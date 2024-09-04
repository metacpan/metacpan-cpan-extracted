package Arcus::Client;

use strict;
use warnings;
use Storable;
use POSIX::AtFork;
use Digest::SHA qw/sha1_hex/;
use parent 'Arcus::Base';

our $VERSION = '0.5.0';
our $HAVE_ZLIB;

BEGIN {
  $HAVE_ZLIB = eval "use Compress::Zlib (); 1;";
}

use constant F_STORABLE => 1;
use constant F_COMPRESS => 2;

my %arcus_info;

our $SANITIZE = \&_sanitize_method;
{
  use bytes;
  my %escapes = map { chr($_) => sprintf('%%%02X', $_) } (0x00..0x20, 0x7f..0xff);
  sub _sanitize_method {
    my $key = shift;
    return undef unless defined($key);
    $key =~ s/([\x00-\x20\x7f-\xff])/$escapes{$1}/ge;
    if (length($key) > 200) {
      $key = sha1_hex($key);
    }
    return $key;
  }
}

my $ENCODE = sub {
  my ($conf, $value, $flags) = @_;
  # serialization
  if (ref $value) {
    $value = eval { $conf->{serialize_methods}->[0]->($value) };
    if ($@) {
      warn "failed to serialize.";
    } else {
      $flags |= F_STORABLE;
    }
  }
  # compression
  if (defined($value) and
      defined($conf->{compress_methods}) and
      $conf->{compress_threshold} > 0 and
      $conf->{compress_threshold} <= length($value)) {
    my $c_val = eval { $conf->{compress_methods}->[0]->($value) };
    if ($@) {
      warn "failed to compress.";
    } elsif (length($c_val) < length($value) * $conf->{compress_ratio}) {
      $value = $c_val;
      $flags |= F_COMPRESS;
    }
  }
  return ($value, $flags);
};

my $DECODE = sub {
  my ($conf, $value, $flags) = @_;
  if (defined($flags)) {
    if (defined($value) && ($flags & F_COMPRESS)) {
      $value = eval { $conf->{compress_methods}->[1]->($value) };
      warn "failed to decompress." if ($@);
    }
    if (defined($value) && ($flags & F_STORABLE)) {
      $value = eval { $conf->{serialize_methods}->[1]->($value) };
      warn "failed to deserialize." if ($@);
    }
  }
  return ($value);
};

sub new {
  my ($class, $args) = @_;
  $args->{connect_timeout} //= 1.0; # second
  $args->{io_timeout}      //= 0.8; # second
  $args->{max_thread} //= 64;
  $args->{nowait} = 0; # TODO: Fix a C Client's noreply flags (issue: #3)
  $args->{hash_namespace} = 1;
  $args->{namespace} //= "";
  $args->{serialize_methods} //= [ \&Storable::nfreeze, \&Storable::thaw ];
  $args->{compress_threshold} //= -1;
  $args->{compress_ratio} //= 0.8;
  $args->{compress_methods} //= [ \&Compress::Zlib::memGzip,
                                  \&Compress::Zlib::memGunzip ] if $HAVE_ZLIB;
  my $arcus = $class->SUPER::new($args);
  bless($arcus, $class);
  $arcus_info{$$arcus} = $args;
  POSIX::AtFork->add_to_child(sub {
    $arcus->connect_proxy();
  });
  return $arcus;
}

sub DESTROY {
  my $arcus = shift;
  $arcus->SUPER::DESTROY;
  if ($arcus_info{$$arcus}) {
    delete $arcus_info{$$arcus};
  }
}

sub CLONE {
  my $class = shift;
  foreach my $arcus (keys %arcus_info) {
    $class->SUPER::new($arcus);
  }
}

for my $method ( qw/set add replace/ ) {
  no strict 'refs';
  my $super = 'SUPER::'.$method;
  *{$method} = sub {
    my ($arcus, $key, $value, $exptime) = @_;
    my ($conf, $flags) = ($arcus_info{$$arcus}, 0);
    return undef unless $conf;
    $key = $SANITIZE->($key);
    ($value, $flags) = $ENCODE->($conf, $value, $flags);
    return $arcus->$super($key, $value, $exptime, $flags);
  };
}

sub cas {
  my ($arcus, $key, $cas, $value, $exptime) = @_;
  my ($conf, $flags) = ($arcus_info{$$arcus}, 0);
  return undef unless $conf;
  $key = $SANITIZE->($key);
  ($value, $flags) = $ENCODE->($conf, $value, $flags);
  return $arcus->SUPER::cas($key, $cas, $value, $exptime, $flags);
}

sub cas_multi {
  my ($arcus, @kvs) = @_;
  my $ctx = wantarray;
  my $conf = $arcus_info{$$arcus};
  return undef unless $conf;
  my (@skvs, @ref);
  foreach my $elem (@kvs) {
    my ($key, $cas, $value) = @{$elem}[0, 1, 2];
    my $flags = 0;
    my $exptime = $elem->[3] ? $elem->[3] : 0;
    $key = $SANITIZE->($key);
    ($value, $flags) = $ENCODE->($conf, $value, $flags);
    push(@skvs, [$key, $cas, $value, $exptime, $flags]);
  }
  @ref = $arcus->SUPER::cas_multi(@skvs);
  return unless defined($ctx);
  return @ref if $ctx;
  my %href;
  foreach my $index (0..$#kvs) {
    $href{$kvs[$index]->[0]} = $ref[$index] if defined($ref[$index]);
  }
  return \%href;
}

for my $method ( qw/set_multi add_multi replace_multi/ ) {
  no strict 'refs';
  my $super = 'SUPER::'.$method;
  *{$method} = sub {
    my ($arcus, @kvs) = @_;
    my $ctx = wantarray;
    my $conf = $arcus_info{$$arcus};
    return undef unless $conf;
    my (@skvs, @ref);
    foreach my $elem (@kvs) {
      my ($key, $value) = @{$elem}[0, 1];
      my $flags = 0;
      my $exptime = $elem->[2] ? $elem->[2] : 0;
      $key = $SANITIZE->($key);
      ($value, $flags) = $ENCODE->($conf, $value, $flags);
      push(@skvs, [$key, $value, $exptime, $flags]);
    }
    @ref = $arcus->$super(@skvs);
    return unless defined($ctx);
    return @ref if $ctx;
    my %href;
    foreach my $index (0..$#kvs) {
      $href{$kvs[$index]->[0]} = $ref[$index] if defined($ref[$index]);
    }
    return \%href;
  }
}

for my $method ( qw/append prepend/ ) {
  no strict 'refs';
  my $super = 'SUPER::'.$method;
  *{$method} = sub {
    my ($arcus, $key, $value) = @_;
    my $conf = $arcus_info{$$arcus};
    return undef unless $conf;
    $key = $SANITIZE->($key);
    return $arcus->$super($key, $value);
  };
}

for my $method ( qw/append_multi prepend_multi/ ) {
  no strict 'refs';
  my $super = 'SUPER::'.$method;
  *{$method} = sub {
    my ($arcus, @kvs) = @_;
    my $ctx = wantarray;
    my $conf = $arcus_info{$$arcus};
    return undef unless $conf;
    my (@skvs, @ref);
    foreach my $elem (@kvs) {
      my ($key, $value) = @{$elem}[0, 1];
      my $flags = 0;
      my $exptime = $elem->[2] ? $elem->[2] : 0;
      $key = $SANITIZE->($key);
      push(@skvs, [$key, $value, $exptime, $flags]);
    }
    @ref = $arcus->$super(@skvs);
    return unless defined($ctx);
    return @ref if $ctx;
    my %href;
    foreach my $index (0..$#kvs) {
      $href{$kvs[$index]->[0]} = $ref[$index] if defined($ref[$index]);
    }
    return \%href;
  }
}

for my $method ( qw/incr decr/ ) {
  no strict 'refs';
  my $super = 'SUPER::'.$method;
  *{$method} = sub {
    my ($arcus, $key, $offset) = @_;
    my $conf = $arcus_info{$$arcus};
    return undef unless $conf;
    $key = $SANITIZE->($key);
    return $arcus->$super($key, $offset);
  };
}

#for my $method ( qw/incr_multi decr_multi/ ) {
#  no strict 'refs';
#  my $super = substr('SUPER::'.$method, 0, -6);
#  *{$method} = sub {
#    my ($arcus, @arr) = @_;
#    my $ctx = wantarray;
#    my (@ref, @keys);
#    my $conf = $arcus_info{$$arcus};
#    return undef unless $conf;
#    foreach my $elem (@arr) {
#      my ($key, $offset);
#      if (ref $elem) {
#        ($key, $offset) = @{$elem}[0, 1];
#      }
#      else {
#        $key = $elem;
#      }
#      $key = $SANITIZE->($key);
#      push(@ref, $arcus->$super($key, $offset));
#      push(@keys, $key);
#    }
#    return unless defined($ctx);
#    return @ref if $ctx;
#    my %href = map { $keys[$_] => $ref[$_] } 0..$#arr;
#    return \%href;
#  }
#}

sub get {
  my ($arcus, $key) = @_;
  my $conf = $arcus_info{$$arcus};
  return undef unless $conf and defined($key);
  $key = $SANITIZE->($key);
  my ($value, $flags) = $arcus->SUPER::get($key);
  return undef unless defined($value) and defined($flags);
  ($value) = $DECODE->($conf, $value, $flags);
  return $value;
}

sub get_multi {
  my ($arcus, @keys) = @_;
  my $conf = $arcus_info{$$arcus};
  return undef unless $conf;
  my @skeys;
  my %kmap;
  for my $key (@keys) {
    my $skey = $SANITIZE->($key) if defined($key);
    next unless defined($skey);

    push(@skeys, $skey);
    $kmap{$skey} = $key;
  }
  my $result = $arcus->SUPER::get_multi(@skeys);
  my %href;
  while (my ($key, $arr) = each %{$result}) {
    my ($value, $flags) = @{$arr}[0, 1];
    ($value) = $DECODE->($conf, $value, $flags);
    $href{$kmap{$key}} = $value if defined($value);
  }
  return \%href;
}

sub gets {
  my ($arcus, $key) = @_;
  my $conf = $arcus_info{$$arcus};
  return undef unless $conf and defined($key);
  $key = $SANITIZE->($key);
  my ($cas, $value, $flags) = $arcus->SUPER::gets($key);
  return undef unless defined($cas) and defined($value) and defined($flags);
  ($value) = $DECODE->($conf, $value, $flags);
  return [$cas, $value];
}

sub gets_multi {
  my ($arcus, @keys) = @_;
  my $conf = $arcus_info{$$arcus};
  return undef unless $conf;
  my @skeys;
  my %kmap;
  for my $key (@keys) {
    my $skey = $SANITIZE->($key) if defined($key);
    next unless defined($skey);

    push(@skeys, $skey);
    $kmap{$skey} = $key;
  }
  my $result = $arcus->SUPER::gets_multi(@skeys);
  my %href;
  while (my ($key, $arr) = each %{$result}) {
    my ($cas, $value, $flags) = @{$arr}[0, 1, 2];
    ($value) = $DECODE->($conf, $value, $flags);
    $href{$kmap{$key}} = [$cas, $value] if defined($cas) and defined($value);
  }
  return \%href;
}

sub get_or_set {
  my($arcus, $key, $callback, $expire) = @_;
  my $value = $arcus->get($key);
  unless (defined($value)) {
    my $ret_expire;
    ($value, $ret_expire) = $callback->();
    $arcus->set($key, $value, $expire || $ret_expire);
  }
  return $value;
}

sub delete {
  my ($arcus, $key) = @_;
  my $conf = $arcus_info{$$arcus};
  return undef unless $conf;
  $key = $SANITIZE->($key);
  return $arcus->SUPER::delete($key);
}

#sub delete_multi {
#  my ($arcus, @keys) = @_;
#  my $ctx = wantarray;
#  my @ref;
#  my $conf = $arcus_info{$$arcus};
#  return undef unless $conf;
#  foreach my $key (@keys) {
#    $key = $SANITIZE->($key);
#    push(@ref, $arcus->SUPER::delete($key));
#  }
#  return unless defined($ctx);
#  return @ref if $ctx;
#  my %href = map { $keys[$_] => $ref[$_] } 0..$#keys;
#  return \%href;
#}

# This is necessary to use plack framework
sub remove {
  my ($self, $key, $exptime) = @_;
  return $self->delete($key, $exptime);
}

1;
__END__

=head1 NAME

Arcus::Client - Perl client for arcus cache cluster

=head1 SYNOPSIS

  use Arcus::Client;

  my $cache = Arcus::Client->new({
    zk_address => [ "localhost:2181", "localhost:2182", "localhost:2183" ],
    service_code => "test",
    namespace => "my:",
    connect_timeout => 1.5,
    io_timeout => 0.7,
    compress_threshold => 100_000,
    compress_ratio => 0.9,
    compress_methods => [ \&IO::Compress::Gzip::gzip,
                          \&IO::Uncompress::Gunzip::gunzip ],
    serialize_methods => [ \&Storable::freeze, \&Storable::thaw ],
  });

  # Get server versions
  my $versions = $cache->server_versions;
  while (my ($server, $version) = each %$versions) {
    #...
  }

  # Store scalar values
  $cache->add("sadd1", "v1");
  $cache->add_multi(["saddr2", "v2"], ["sadd3", "v3", 100]);

  $cache->set("sset1", "v1");
  $cache->set_multi(["sset2", "v2"], ["sset3", "v3", 10]);

  $cache->replace("sset1", 10);
  $cache->replace_multi(["sset2", "r2"],["sset3", "r3"]);

  # Store arbitrary Perl data structures
  $cache->set("hset1", {a => 1, b => 2});
  $cache->set_multi(["hset2", {c => 3}], ["lset1", [0, 1, 2]]);

  # Append/Prepend to values
  $cache->prepend("sadd1", "pre1");
  $cache->prepend_multi(["sadd2", "pre2"], ["sadd3", "pre3"]);
  $cache->append("sadd1", "app");
  $cache->append_multi(["sadd2", "app2"], ["sadd3", "app3"]);

  # Do arithmetic
  $cache->incr("sset1", 10);
  $cache->decr("sset1", 13);

  # Retrieve values
  print "OK\n" if $cache->get("sset1") == 7;
  my $href = $cache->get_multi("hset1", "sset3");

  if ($href->{hset1}->{a} == 1 &&
      $href->{hset1}->{b} == 2 &&
      $href->{sset3} eq "r3") {
    print "OK\n";
  }

  # Delete data
  $cache->delete("sset1");

=head1 DESCRIPTION

B<Arcus::Client> is the Perl API for Arcus cache cluster.
This uses B<Arcus Zookeeper C Client> and B<Arcus C Client>
to support cross-shard operations on the elastic Arcus clusters.

Also, it supports most of the methods provided by L<Cache::Memcached::Fast::Safe>,
but I<incr_multi>, I<decr_multi>, and I<delete_multi> are not yet supported.

=head1 CONSTRUCTOR

=over

=item C<new>

  my $cache = Arucs::client->new($params);

Create a new client object. I<$params> is a hash reference containing the
settings for client. The following keys are recognized in I<$params>:

=over

=item I<zk_address>

  zk_address => [ "localhost:2181", "localhost:2182", "localhost:2183" ],
  (Essential)

I<zk_address> consists of zookeeper ensemble addresses to retrieve
cache server information. It is an array reference where each
element is a scalar type.

=item I<service_code>

  service_code => "test"
  (Essential)

I<service_code> is a scalar value being used to retrieve cache server information
for a specific service from the Zookeeper ensemble.

=item I<namespace>

  namespace => "my:"
  (default: '')

I<namespace> is a prefix that is prepended to all key names sent to the
server. It is a scalar type.

By using distinct namespaces, clients can prevent conflicts with one another.

I<hash_namespace> must always be set to I<true>, and the I<namespace> is hashed with
the key to specify the destination server.

=item I<connect_timeout>

  connect_timeout => 1.5
  (default: 1.0 seconds)

I<connect_timeout> represents the number of seconds to wait for the connection
to be established. It is a scalar type with a positive rational number.

=item I<io_timeout>

  io_timeout => 0.7
  (default: 0.8 seconds)

I<io_timeout> represents the number of seconds to wait before abandoning
communication with the servers. It is a scalar type with a positive rational number.

=item I<compress_threshold>

  compress_threshold => 100_000
  (default: -1)

I<compress_threshold> specifies the size threshold in bytes:
data that is equal to or larger than this value should be compressed.
See L</compress_ratio> and L</compress_methods> below.

It is a scalar type with an integer value. If the value is negative,
compression is disabled.

=item I<compress_ratio>

  compress_ratio => 0.9
  (default: 0.8)

When compression is enabled by L</compress_threshold>, the compressed size
should be less than or equal to S<(original-size * I<compress_ratio>)>.
Otherwise, the data will be stored in its uncompressed form.

It is a scalar type with a fraction between 0 and 1.

=item I<compress_methods>

  compress_methods => [ \&IO::Compress::Gzip::gzip,
                        \&IO::Uncompress::Gunzip::gunzip ]
  (default: [ \&Compress::Zlib::memGzip, \&Compress::Zlib::memGunzip ]
   when Compress::Zlib is available)

I<compress_methods> is an array reference containing two code references:
one for compression and one for decompression routines.

The compression routine is invoked when the size of the I<$value>
passed to the L</set> method is equal to or exceeds L</compress_threshold>
(see also L</compress_ratio>).  The fact that compression has been applied
is stored with the data, and the decompression routine is used
when retrieving data with the L</get> method.  The interfaces for these
routines should be compatible with those in the B<IO::Compress> family.

=item I<serialize_methods>

  serialize_methods => [ \&Storable::freeze, \&Storable::thaw ],
  (default: [ \&Storable::nfreeze, \&Storable::thaw ])

I<serialize_methods> is an array reference containing two code references:
one for a serialization routine and one for a deserialization routine.

The serialization routine is invoked when the I<$value> passed
to the L</set> method is a reference.  This routine stores the fact
that serialization has occurred along with the data,
and the deserialization routine is used when retrieving data
with the L</get> method. The interfaces for these routines should
be similar to those in L<Storable::nfreeze|Storable/nfreeze> and
L<Storable::thaw|Storable/thaw>.

=back

=back

=head1 METHODS

=over

=item C<set>

  $cache->set($key, $value);
  $cache->set($key, $value, $expiration_time);

Store a value under the given key on the server.
Both I<$key> and I<$value> are required. I<$key> shoud be a scalar.
I<$value> should be defined and may be of any Perl data type.
If I<$value> is a reference, it will be automatically serialized
using the routine defined in L</serialize_methods>.

I<$expiration_time> is optional. It is a scalar type with a positive
integer representing the number of seconds after which the value will
expire and be removed from the server.
If not provided, the default I<$expiration_time> is 0. In this case,
the key will not expire but may be evicted according to the server's memory policy.

I<Return:>

=over

I<true(1)> : a successful server reply

I<false(0)> : an unsuccessful server reply

I<undef> : case of some error

=back

=item C<set_multi>

  $cache->set_multi(
      [$key, $value],
      [$key, $value, $expiration_time],
      ...
  );

Similar to L</set>, but applies to multiple keys at once.
It takes a list of array references, each containing
I<$key>, I<$value>, and optional I<$expiration_time>

Note that multi-key operations do not support an all-or-nothing approach;
some operations may succeed while others may fail.

I<Return:>

=over

I<@list> : In list context, returns a list of results
where each I<$list[$index]> corresponds to the result for
the argument at position I<$index>.

I<$href> : In scalar context, returns a hash reference
where I<$href-E<gt>{$key}> contains the result for that key.

=back

=item C<cas>

  $cache->cas($key, $cas, $value);
  $cache->cas($key, $cas, $value, $expiration_time);

Store a value under the given key, but only if CAS(I<Consistent Access Storage>)
value associated with this key matches the provided I<$cas>.
The I<$cas> is an opaque object returned by L</gets>, L</gets_multi>.

For details on the I<$key>, I<$value>, and I<$expiration_time> parameters,
refer to L</set>.

I<Return:>

=over

I<true(1)> : a successful server reply

I<false(0)> : an unsuccessful server reply

I<undef> : case of some error

=back

=item C<cas_multi>

  $cache->cas_multi(
      [$key, $cas, $value],
      [$key, $cas, $value, $expiration_time],
      ...
  );

Similar to L</cas>, but applies to multiple keys at once.
It takes a list of array references, each containing
I<$key>, I<$cas>, I<$value> and optional I<$expiration_time>

Note that multi-key operations do not support an all-or-nothing approach;
some operations may succeed while others may fail.

I<Return:>

=over

I<@list> : In list context, returns a list of results
where each I<$list[$index]> corresponds to the result of
the argument at position I<$index>.

I<$href> : In scalar context, returns a hash reference
where I<$href-E<gt>{$key}> contains the result for that key.

=back

=item C<add>

  $cache->add($key, $value);
  $cache->add($key, $value, $expiration_time);

Store a value under the given key, but only if the key B<doesn't> already
exist on the server.

For details on the I<$key>, I<$value>, and I<$expiration_time> parameters,
refer to L</set>.

I<Return:>

=over

I<true(1)> : a successful server reply

I<false(0)> : an unsuccessful server reply

I<undef> : case of some error

=back

=item C<add_multi>

  $cache->add_multi(
    [$key, $value],
    [$key, $value, $expiration_time],
    ...
  );

Like L</add>, but applies to multiple keys at once.
It takes a list of array references, each containing
I<$key>, I<$value> and optional I<$expiration_time>

Note that multi-key operations do not support an all-or-nothing approach;
some operations may succeed while others may fail.

I<Return:>

=over

I<@list> : In list context, returns a list of results
where each I<$list[$index]> corresponds to the result of
the argument at position I<$index>.

I<$href> : In scalar context, returns a hash reference
where I<$href-E<gt>{$key}> contains the result for that key.

=back

=item C<replace>

  $cache->replace($key, $value);
  $cache->replace($key, $value, $expiration_time);

Store a value under the given key, but only if the key B<does> already
exist on the server.

For details on the I<$key>, I<$value>, and I<$expiration_time> parameters,
refer to L</set>.

I<Return:>

=over

I<true(1)> : a successful server reply

I<false(0)> : an unsuccessful server reply

I<undef> : case of some error

=back

=item C<replace_multi>

  $cache->replace_multi(
    [$key, $value],
    [$key, $value, $expiration_time],
    ...
  );

Like L</replace>, but applies to multiple keys at once.
It takes a list of array references, each containing
I<$key>, I<$value> and optional I<$expiration_time>

Note that multi-key operations do not support an all-or-nothing approach;
some operations may succeed while others may fail.

I<Return:>

=over

I<@list> : In list context, returns a list of results
where each I<$list[$index]> corresponds to the result of
the argument at position I<$index>.

I<$href> : In scalar context, returns a hash reference
where I<$href-E<gt>{$key}> contains the result for that key.

=back

=item C<append>

  $cache->append($key, $value);

B<Append> the I<$value> to the existing value on the server under the
given I<$key>.

Both I<$key> and I<$value> are required and should be scalars.

I<Return:>

=over

I<true(1)> : a successful server reply

I<false(0)> : an unsuccessful server reply

I<undef> : case of some error

=back

=item C<append_multi>

  $cache->append_multi(
      [$key, $value],
      ...
  );

Like L</append>, but applies to multiple keys at once.
It takes a list of array references, each containing
I<$key>, I<$value> and optional I<$expiration_time>

Note that multi-key operations do not support an all-or-nothing approach;
some operations may succeed while others may fail.

I<Return:>

=over

I<@list> : In list context, returns a list of results
where each I<$list[$index]> corresponds to the result of
the argument at position I<$index>.

I<$scalar> : In scalar context, returns a hash reference
where I<$href-E<gt>{$key}> contains the result for that key.

=back

=item C<prepend>

  $cache->prepend($key, $value);

B<Prepend> the I<$value> to the existing value on the server under the
given I<$key>.

Both I<$key> and I<$value> are required and should be scalars.

I<Return:>

=over

I<true(1)> : a successful server reply

I<false(0)> : an unsuccessful server reply

I<undef> : case of some error

=back

=item C<prepend_multi>

  $cache->prepend_multi(
      [$key, $value],
      ...
  );

Like L</prepend>, but applies to multiple keys at once.
It takes a list of array references, each containing
I<$key>, I<$value> and optional I<$expiration_time>

Note that multi-key operations do not support an all-or-nothing approach;
some operations may succeed while others may fail.

I<Return:>

=over

I<@list> : In list context, returns a list of results
where each I<$list[$index]> corresponds to the result of
the argument at position I<$index>.

I<$scalar> : In scalar context, returns a hash reference
where I<$href-E<gt>{$key}> contains the result for that key.

=back

=item C<get>

  $cache->get($key);

Retrieve a value associated with the I<$key>.
I<$key> should be a scalar.

I<Return:>

=over

I<value> : associated with the I<$key>

I<undef> : unsuccessful or case of some error

=back

=item C<get_multi>

  $cache->get_multi(@keys);

Retrieve multipe values associated with I<@keys>.
I<@keys> should be an array of scalars.

I<Return:>

=over

I<$href> I<$href-E<gt>{$key}> holds corresponding value

=back

=item C<gets>

  $cache->gets($key);

Retrieve a value and its CAS associated with the I<$key>.
I<$key> should be a scalar.

I<Return:>

=over

I<[$cas, $value]> : associated with the I<$key>

I<undef> : unsuccessful or case of some error

=back

=item C<gets_multi>

  $cache->get_multi(@keys);

Retrieve multipe values and their CAS associated with I<@keys>.
I<@keys> should be an array of scalars.

I<Return:>

=over

I<$href> : I<$href-E<gt>{$key}> holds corresponding I<[$cas, $value]>

=back

=item C<incr>

  $cache->incr($key);
  $cache->incr($key, $increment);

Increment the value associated with the I<$key>.
An optional I<$increment> should be positive integer;
if not provided, the default I<$increment> is 1.

Note that the server does not perform an overflow check.

I<Return:>

=over

I<$new_value> : new value resulting from a successful operation

I<false(0)> : an unsuccessful server reply

I<undef> : case of some error

=back

=item C<decr>

  $cache->decr($key);
  $cache->decr($key, $decrement);

Decrement the value associated with the I<$key>.
An optional I<$decrement> should be positive integer;
if not provided, the default I<$decrement> is 1.

Note that the server does check for underflow;
attempting to decrement the value below zero will set it to zero.
Similar to L<DBI|DBI>, zero is returned as I<"0E0">,
and evaluates to true in a boolean context.

I<Return:>

=over

I<$new_value> : new value resulting from a successful operation

I<false(0)> : an unsuccessful server reply

I<undef> : case of some error

=back

=item C<delete>

  $cache->delete($key);

Delete I<$key> and its associated value from the server.

I<Return:>

=over

I<true(1)> : a successful server reply

I<false(0)> : an unsuccessful server reply

I<undef> : case of some error

=back

=item C<remove> (B<deprecated>)

Another name for the L</delete>,
for compatibility with B<Cache::Memcached::Fast>.

=item C<get_or_set>

Retrieve the cached value for I<$key>.
If the value cannot be retrieved for the cache,
execute I<$callback> and cache the result for I<$expires> seconds.

=back

=head1 AUTHOR

JaM2in, E<lt>koo05131@jam2in.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by JaM2in

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
