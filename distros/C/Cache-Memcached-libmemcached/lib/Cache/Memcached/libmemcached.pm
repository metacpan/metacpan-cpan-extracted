package Cache::Memcached::libmemcached;

require bytes;
use strict;
use warnings;

use Memcached::libmemcached 1.001701, qw(
    MEMCACHED_CALLBACK_PREFIX_KEY
    MEMCACHED_PREFIX_KEY_MAX_SIZE
);
use base qw(Memcached::libmemcached);

use Carp qw(croak carp);
use Scalar::Util qw(weaken);
use Storable ();

our $VERSION = '0.04001';

use constant HAVE_ZLIB    => eval { require Compress::Zlib } && !$@;
use constant F_STORABLE   => 1;
use constant F_COMPRESS   => 2;
use constant OPTIMIZE     => $ENV{PERL_LIBMEMCACHED_OPTIMIZE} ? 1 : 0;

my %behavior;

BEGIN
{
    # Make sure to load bytes.pm if HAVE_ZLIB is enabled
    if (HAVE_ZLIB) {
        require bytes;
    }

    # accessors
    foreach my $field (qw(compress_enable compress_threshold compress_savings)) {
        eval sprintf(<<"        EOSUB", $field, $field, $field, $field);
            sub set_%s { \$_[0]->{%s} = \$_[1] }
            sub get_%s { \$_[0]->{%s} }
        EOSUB
        die if $@;
    }
    # for Cache::Memcached compatibility
    sub enable_compress { shift->set_compress_enable(@_) }

    # XXX this should be done via subclasses
    if (OPTIMIZE) {
        # If the optimize flag is enabled, we do not support master key
        # generation, cause we really care about the speed.
        foreach my $method (qw(get set add replace prepend append cas delete)) {
            eval <<"            EOSUB";
                sub $method {
                    shift->SUPER::memcached_${method}(\@_)
                }
            EOSUB
            die if $@;
        }
    } else {
        # Regular case.
        # Mental note. We only do this cause while we're faster than
        # Cache::Memcached::Fast, *even* when the above optimization isn't
        # toggled.
        foreach my $method (qw(get set add replace prepend append cas delete)) {
            eval <<"            EOSUB";
                sub $method { 
                    my \$self = shift;
                    my \$key  = shift;
                    return \$self->SUPER::memcached_${method}(\$key, \@_)
                        unless ref \$key;
                    (my \$master_key, \$key) = @\$key;
                    if (\$master_key) {
                        \$self->SUPER::memcached_${method}_by_key(\$master_key, \$key, \@_);
                    } else {
                        \$self->SUPER::memcached_${method}(\$key, \@_);
                    }
                }
            EOSUB
            die if $@;
        }
    }

    # Create get_*/is_*/set_* methods for some libmemcached behaviors.
    # We only do this for some because there are many and it's easy for
    # the user to use memcached_behavior_set() etc directly.
    #
    %behavior = (
        # non-boolean behaviors that are renamed (to be more descriptive)
        distribution_method => [ 0, 'distribution' ],
        hashing_algorithm   => [ 0, 'hash' ],
        # boolean behaviors that are not renamed:
        no_block        => [ 1 ],
        binary_protocol => [ 1 ],
    );

    while ( my ($method, $field_info) = each %behavior ) {
        my $is_bool = $field_info->[0];
        my $field   = $field_info->[1] || $method;

        my $behavior = "Memcached::libmemcached::MEMCACHED_BEHAVIOR_\U$field";
        warn "$behavior doesn't exist\n" # sanity check
            unless do { no strict 'refs'; defined &$behavior };

        my ($set, $get) = ("set_$method", "get_$method");
        $get = "is_$method" if $is_bool;
        my $code = "sub $set { \$_[0]->memcached_behavior_set($behavior(), \$_[1]) }\n"
                 . "sub $get { \$_[0]->memcached_behavior_get($behavior()) }";
        eval $code;
        die "$@ while executing $code" if $@;
    }

}

sub import
{
    my $class = shift;
    Memcached::libmemcached->export_to_level(1, undef, @_) ;
}

sub new
{
    my $class = shift;
    my %args  = %{ shift || {} };

    my $self = $class->SUPER::new();

    $self->trace_level(delete $args{debug}) if exists $args{debug};

    $self->namespace(delete $args{namespace})
        if exists $args{namespace};

    $self->{compress_threshold} = delete $args{compress_threshold};
    # Add support for Cache::Memcache::Fast's compress_ratio
    $self->{compress_savingsS}  = delete $args{compress_savings} || 0.20;
    $self->{compress_enable}    =
        exists $args{compress_enable} ? delete $args{compress_enable} : 1;

    # servers 
    $args{servers} || croak "No servers specified";
    $self->set_servers(delete $args{servers});

    # old-style behavior options (see behavior_ block below)
    foreach my $option (qw(no_block hashing_algorithm distribution_method binary_protocol)) {
        my $behavior = $behavior{$option}->[1] || $option;
        $args{"behavior_$behavior"} = delete $args{$option} if exists $args{$option};
    }

    # allow any libmemcached behavior to be set via args to new()
    for my $name (grep { /^behavior_/ } keys %args) {
        my $value = delete $args{$name};
        my $behavior = "Memcached::libmemcached::MEMCACHED_\U$name";
        no strict 'refs';
        if (not defined &$behavior) {
            carp "$name ($behavior) isn't available"; # sanity check
            next;
        }
        $self->memcached_behavior_set(&$behavior(), $value);
    }

    delete $args{readonly};
    delete $args{no_rehash};

    carp "Unrecognised options: @{[ sort keys %args ]}"
        if %args;

    # Set compression/serialization callbacks
    $self->set_callback_coderefs(
        # Closures so we have reference to $self
        $self->_mk_callbacks()
    );

    # behavior options
    foreach my $option (qw(no_block hashing_algorithm distribution_method binary_protocol)) {
        my $method = "set_$option";
        $self->$method( $args{$option} ) if exists $args{$option};
    }

    return $self;
}

sub namespace {
    my $self = shift;

    my $old_namespace = $self->memcached_callback_get(MEMCACHED_CALLBACK_PREFIX_KEY);
    if (@_) {
        my $namespace = shift;
        $self->memcached_callback_set(MEMCACHED_CALLBACK_PREFIX_KEY, $namespace)
            or carp $self->errstr;
    }

    return $old_namespace;
}

sub set_servers
{
    my $self = shift;
    my $servers = shift || [];

    # $self->{servers} = []; # for compatibility with Cache::Memcached

    # XXX should delete any existing servers from libmemcached
    foreach my $server (@$servers) {
        $self->server_add($server);
    }
}

sub server_add
{
    my $self = shift;
    my $server = shift
        or Carp::confess("server not specified");

    my $weight = 0;
    if (ref $server eq 'ARRAY') {
        my @ary = @$server;
        $server = shift @ary;
        $weight = shift @ary || 0 if @ary;
    }
    elsif (ref $server eq 'HASH') { # Cache::Memcached::Fast
        my $h = $server;
        $server = $h->{address};
        $weight = $h->{weight} if exists $h->{weight};
        # noreply is not supported
    }

    if ($server =~ /^([^:]+):([^:]+)$/) {
        my ($hostname, $port) = ($1, $2);
        $self->memcached_server_add_with_weight($hostname, $port, $weight);
    } else {
        $self->memcached_server_add_unix_socket_with_weight( $server, $weight );
    }

    # for compatibility with Cache::Memcached
    # push @{$self->{servers}}, $server;
}


sub _mk_callbacks
{
    my $self = shift;

    weaken($self);
    my $inflate = sub {
        my ($key, $flags) = @_;
        if ($flags & F_COMPRESS) {
            if (! HAVE_ZLIB) {
                croak("Data for $key is compressed, but we have no Compress::Zlib");
            }
            $_ = Compress::Zlib::memGunzip($_);
        }

        if ($flags & F_STORABLE) {
            $_ = Storable::thaw($_);
        }
        return ();
    };

    my $deflate = sub {
        # Check if we have a complex structure
        if (ref $_) {
            $_ = Storable::nfreeze($_);
            $_[1] |= F_STORABLE;
        }

        # Check if we need compression
        if (HAVE_ZLIB && $self->{compress_enable} && $self->{compress_threshold}) {
            # Find the byte length
            my $length = bytes::length($_);
            if ($length > $self->{compress_threshold}) {
                my $tmp = Compress::Zlib::memGzip($_);
                if (bytes::length($tmp) / $length < 1 - $self->{compress_savingsS}) {
                    $_ = $tmp;
                    $_[1] |= F_COMPRESS;
                }
            }
        }
        return ();
    };
    return ($deflate, $inflate);
}

sub incr
{
    my $self = shift;
    my $key  = shift;
    my $offset = shift || 1;
    my $val = 0;
    $self->memcached_increment($key, $offset, $val) || return undef;
    return $val;
}

sub decr
{
    my $self = shift;
    my $key  = shift;
    my $offset = shift || 1;
    my $val = 0;
    $self->memcached_decrement($key, $offset, $val) || return undef;
    return $val;
}


sub flush_all
{
    $_[0]->memcached_flush(0);
}

*remove = \&delete;

sub disconnect_all {
    $_[0]->memcached_quit();
}


sub server_versions {
    my $self = shift;
    my %versions;
    # XXX not optimal, libmemcached knows these values without having to send a stats request
    $self->walk_stats('', sub {
        my ($key, $value, $hostport) = @_;
        $versions{$hostport} = $value if $key eq 'version';
        return;
    });
    return \%versions;
}


sub stats
{
    my $self = shift;
    my ($stats_args) = @_;

    # http://github.com/memcached/memcached/blob/master/doc/protocol.txt
    $stats_args = [ $stats_args ]
        if $stats_args and not ref $stats_args;
    $stats_args ||= [ '' ];

    # stats keys that aren't matched by the prefix and suffix regexes below
    # but which we want to accumulate in totals
    my %total_misc_keys = map { ($_ => 1) } qw(
        bytes evictions
        connection_structures curr_connections total_connections
    ); 

    my %h;
    for my $type (@$stats_args) {

        my $code = sub {
            my ($key, $value, $hostport) = @_;

            # XXX - This is hardcoded in the callback cause r139 in perl-memcached
            # removed the magic of "misc"
            $type ||= 'misc';
            $h{hosts}{$hostport}{$type}{$key} = $value;
            #warn "$_ ($key, $value, $hostport, $type)\n";

            # accumulate overall totals for some items
            if ($type eq 'misc') {
                if ($total_misc_keys{$key}
                or $key =~ /^(?:cmd|bytes)_/ # prefixes
                or $key =~ /_(?:hits|misses|errors|yields|badval|items|read|written)$/ # suffixes
                ) {
                    $h{total}{$key} += $value;
                }
            }
            elsif ($type eq 'malloc' or $type eq 'sizes') {
                $h{total}{"${type}_$key"} += $value;
            }
            return;
        };

        $self->walk_stats($type, $code);
    }

    return \%h;
}

# for compatability with Cache::Memcached and Cache::Memcached::Managed 0.20:
# https://rt.cpan.org/Ticket/Display.html?id=62512
# sub sock_to_host { undef }
# sub get_sock { undef }
# sub forget_dead_hosts { undef }

1;

__END__

=head1 NAME

Cache::Memcached::libmemcached - Cache interface to Memcached::libmemcached

=head1 SYNOPSIS

  use Cache::Memcached::libmemcached;

  my $memd = Cache::Memcached::libmemcached->new({
      servers => [
            "10.0.0.15:11211",
            [ "10.0.0.15:11212", 2 ], # weight
            "/var/sock/memcached"
      ],
      compress_threshold => 10_000,
      # ... many more options supported
  });

  $memd->set("my_key", "Some value");
  $memd->set("object_key", { 'complex' => [ "object", 2, 4 ]});

  $val = $memd->get("my_key");
  $val = $memd->get("object_key");
  print $val->{complex}->[2] if $val;

  $memd->incr("key");
  $memd->decr("key");
  $memd->incr("key", 2);

  $memd->delete("key");
  $memd->remove("key"); # Alias to delete

  my $hashref = $memd->get_multi(@keys);

  # Import Memcached::libmemcached constants - explicitly by name or by tags
  # see Memcached::libmemcached::constants for a list
  use Cache::Memcached::libmemcached qw(MEMCACHED_DISTRIBUTION_CONSISTENT);
  use Cache::Memcached::libmemcached qw(
      :defines
      :memcached_allocated
      :memcached_behavior
      :memcached_callback
      :memcached_connection
      :memcached_hash
      :memcached_return
      :memcached_server_distribution
  );

  my $memd = Cache::Memcached::libmemcached->new({
      distribution_method => MEMCACHED_DISTRIBUTION_CONSISTENT,
      hashing_algorithm   => MEMCACHED_HASH_FNV1A_32,
      behavior_... => ...,
      ...
  });

=head1 DESCRIPTION

This is the Cache::Memcached compatible interface to libmemcached,
a C library to interface with memcached.

Cache::Memcached::libmemcached is built on top of Memcached::libmemcached.
While Memcached::libmemcached aims to port libmemcached API to perl, 
Cache::Memcached::libmemcached attempts to be API compatible with
Cache::Memcached, so it can be used as a drop-in replacement.

Cache::Memcached::libmemcached I<inherits> from Memcached::libmemcached.
While you are free to use the Memcached::libmemcached specific methods directly
on the object, doing so will mean that your code is no longer compatible with
the original Cache::Memcached API therefore losing some of the portability in
case you want to replace it with some other package.

=head1 Cache::Memcached COMPATIBLE METHODS

Except for the minor incompatiblities, below methods are compatible with
Cache::Memcached.

=head2 new

Takes one parameter, a hashref of options.

=head3 Cache::Memcached options:

=head3 servers

The value is passed to the L</set_servers> method.

=head3 compress_threshold

Set a compression threshold, in bytes. Values larger than this threshold will
be compressed by set and decompressed by get.

=head3 namespace

The value is passed to the L</namespace> method.

=head3 debug

Sets the C<trace_level> for the Memcached::libmemcached object.

=head3 readonly, no_rehash

These Cache::Memcached options are not supported.

=head3 Options specific to Cache::Memcached::libmemcached:

=head3 compress_savings

=head3 behavior_*

Any of the I<many> behaviors documented in
L<Memcached::libmemcached::memcached_behavior> can be specified by using
argument key names that start with C<behavior_>. For example:

    behavior_ketama_weighted => 1,
    behavior_noreply => 1,
    behavior_number_of_replicas => 2,
    behavior_server_failure_limit => 3,
    behavior_auto_eject_hosts => 1,

=head3 no_block

=head3 hashing_algorithm

=head3 distribution_method

=head3 binary_protocol

These are equivalent to the same options prefixed with C<behavior_>.

=head2 set_servers

  $memd->set_servers( [ 'serv1:port1', 'serv2:port2', ... ]);

Calls L</server_add> for each element of the supplied arrayref.
See L</server_add> for details of valid values, including how to specify weights.

=head2 namespace

  $memd->namespace;
  $memd->namespace($string);

Without the argument return the current namespace prefix.  With the
argument set the namespace prefix to I<$string>, and return the old prefix.

The effect is to pefix all keys with the provided namespace value. That is, if
you set namespace to "app1:" and later do a set of "foo" to "bar", memcached is
actually seeing you set "app1:foo" to "bar".

The namespace string must be less than 128 bytes (MEMCACHED_PREFIX_KEY_MAX_SIZE).

=head2 get

  my $val = $memd->get($key);

Retrieves a key from the memcached. Returns the value (automatically thawed
with Storable, if necessary) or undef.

Currently the arrayref form of $key is NOT supported. Perhaps in the future.

=head2 get_multi

  my $hashref = $memd->get_multi(@keys);

Retrieves multiple keys from the memcache doing just one query.
Returns a hashref of key/value pairs that were available.

=head2 set

  $memd->set($key, $value[, $expires]);

Unconditionally sets a key to a given value in the memcache. Returns true if 
it was stored successfully.

Currently the arrayref form of $key is NOT supported. Perhaps in the future.

=head2 add

  $memd->add($key, $value[, $expires]);

Like set(), but only stores in memcache if they key doesn't already exist.

=head2 replace

  $memd->replace($key, $value[, $expires]);

Like set(), but only stores in memcache if they key already exist.

=head2 append

  $memd->append($key, $value);

Appends $value to whatever value associated with $key. Only available for
memcached > 1.2.4

=head2 prepend

  $memd->prepend($key, $value);

Prepends $value to whatever value associated with $key. Only available for
memcached > 1.2.4

=head2 incr

=head2 decr

  my $newval = $memd->incr($key);
  my $newval = $memd->decr($key);

  my $newval = $memd->incr($key, $offset);
  my $newval = $memd->decr($key, $offset);

Atomically increments or decrements the specified the integer value specified 
by $key. Returns undef if the key doesn't exist on the server.

=head2 delete

=head2 remove

  $memd->delete($key);
  $memd->delete($key, $time);

Deletes a key.

If $time is non-zero then the item is marked for later expiration. Expiration
works by placing the item into a delete queue, which means that it won't
possible to retrieve it by the "get" command, but "add" and "replace" command
with this key will also fail (the "set" command will succeed, however). After
the time passes, the item is finally deleted from server memory.

=head2 flush_all

  $memd->fush_all;

Runs the memcached "flush_all" command on all configured hosts, emptying all 
their caches. 

=head2 set_compress_threshold

  $memd->set_compress_threshold($threshold);

Set the compress threshold.

=head2 enable_compress

  $memd->enable_compress($bool);

This is actually an alias to set_compress_enable(). The original version
from Cache::Memcached is, despite its naming, a setter as well.

=head2 stats

  my $h = $memd->stats();
  my $h = $memd->stats($keys);

Returns a hashref of statistical data regarding the memcache server(s), the
$memd object, or both. $keys can be an arrayref of keys wanted, a single key
wanted, or absent (in which case the default value is C<[ '' ]>). For each
key the C<stats> command is run on each server.

For example C<<$memd->stats([ '', 'sizes' ])>> would return a structure like
this:

    {
        hosts => {
            'N.N.N.N:P' => {
                misc => {
                    ...
                },
                sizes => {
                    ...
                },
            },
            ...,
        },
        totals => {
            ...
        }
    }

The general stats (where the key is "") are returned with a key of C<misc>.
The C<totals> element contains the aggregate totals for all hosts of some of
the statistics.

=head2 disconnect_all

Disconnects from servers

=head2 cas

  $memd->cas($key, $cas, $value[, $exptime]);

Overwrites data in the server as long as the "cas" value is still the same in
the server.

You can get the cas value of a result by calling memcached_result_cas() on a
memcached_result_st(3) structure.

Support for "cas" is disabled by default as there is a slight performance
penalty. To enable it use the C<support_cas> option to L</new>.


=head1 Cache::Memcached::Fast COMPATIBLE METHODS

=head2 server_versions

    $href = $memd->server_versions;

Returns a reference to hash, where $href->{$server} holds corresponding server
version string, e.g. "1.4.4". $server is either host:port or /path/to/unix.sock.

=head1 Cache::Memcached::libmemcached SPECIFIC METHODS

These methods are libmemcached-specific.

=head2 server_add

    $self->server_add( $server_host_port );   # 10.10.10.10:11211
    $self->server_add( $server_socket_path ); # /path/to/socket
    $self->server_add( [ $server, $weight ] );
    $self->server_add( { address => $server, weight => $weight } );

Adds a memcached server address with an optional weight (default 0).

=head1 UTILITY METHODS

WARNING: Please do not consider the existance for these methods to be final.
They may be renamed or may entirely disappear from future releases.

=head2 get_compress_threshold

Return the current value of compress_threshold

=head2 set_compress_enable

Set the value of compress_enable

=head2 get_compress_enable

Return the current value of compress_enable

=head2 set_compress_savings

Set the value of compress_savings

=head2 get_compress_savings

Return the current value of compress_savings

=head1 BEHAVIOR CUSTOMIZATION

Memcached::libmemcached supports I<many> 'behaviors' that can be used to
configure the behavior of the library and its interaction with the servers.

Certain libmemcached behaviors can be configured with the following methods.

(NOTE: This API is not fixed yet)

=head2 set_no_block

  $memd->set_no_block( 1 );

Set to use blocking/non-blocking I/O. When this is in effect, get() becomes
flaky, so don't attempt to call it. This has the most effect for set()
operations, because libmemcached stops waiting for server response after
writing to the socket (set() will also always return success).

Please consult the man page for C<memcached_behavior_set()> for details 
before setting.

=head2 is_no_block

Get the current value of no_block behavior.

=head2 set_distribution_method

  $memd->set_distribution_method( MEMCACHED_DISTRIBUTION_CONSISTENT );

Set the distribution behavior.

=head2 get_distribution_method

Get the distribution behavior.

=head2 set_hashing_algorithm

  $memd->set_hashing_algorithm( MEMCACHED_HASH_KETAMA );

Set the hashing algorithm used.

=head2 get_hashing_algorithm

Get the hashing algorithm used.

=head2 set_binary_protocol

=head2 is_binary_protocol

  $memd->set_binary_protocol( 1 );
  $binary = $memd->is_binary_protocol();

Use C<set_binary_protocol> to enable/disable binary protocol.
Use C<is_binary_protocol> to determine the current setting.

=head1 OPTIMIZE FLAG

If you are 100% sure that you won't be using the master key support (where 
you provide an arrayref as the key) you can get about 4~5% performance boost
by setting the environment variable named PERL_LIBMEMCACHED_OPTIMIZE to a true
value I<before> loading the module.

This is an EXPERIMENTAL optimization and will possibly be replaced by
implementing the methods in C in Memcached::libmemcached.

=head1 VARIOUS MEMCACHED MODULES

Below are the various memcached modules available on CPAN. 

Please check tool/benchmark.pl for a live comparison of these modules.
(except for Cache::Memcached::XS, which I wasn't able to compile under my
main dev environment)

=head2 Cache::Memcached

This is the "original" module. It's mostly written in Perl, is slow, and lacks
significant features like support for the binary protocol.

=head2 Cache::Memcached::libmemcached

Cache::Memcached::libmemcached, this module,
is a perl binding for libmemcached (http://tangent.org/552/libmemcached.html).
Not to be confused with libmemcache (see below).

=head2 Cache::Memcached::Fast

Cache::Memcached::Fast is a memcached client written in XS from scratch.
As of this writing benchmarks shows that Cache::Memcached::Fast is faster on 
get_multi(), and Cache::Memcached::libmemcached is faster on regular get()/set().
Cache::Memcached::Fast doesn't support the binary protocol.

=head2 Memcached::libmemcached

Memcached::libmemcached is a thin binding to the libmemcached C library
and provides access to most of the libmemcached API.

If you don't care about a drop-in replacement for Cache::Memcached, and want to
benefit from the feature-rich efficient API that libmemcached offers, this is
the way to go.

Since the Memcached::libmemcached module is also the parent class of this module
you can call Memcached::libmemcached methods directly.

=head2 Cache::Memcached::XS

Cache::Memcached::XS is a binding for libmemcache (http://people.freebsd.org/~seanc/libmemcache/).
The main memcached site at http://danga.com/memcached/apis.bml seems to 
indicate that the underlying libmemcache is no longer in active development.
The module hasn't been updated since 2006.

=head1 TODO

Check and improve compatibility with Cache::Memcached::Fast.

Add forget_dead_hosts() for greater Cache::Memcached compatibility?

Treat PERL_LIBMEMCACHED_OPTIMIZE as the default and add a subclass that
handles the arrayref master key concept. Then
the custom methods (get set add replace prepend append cas
delete) can then all be removed and the libmemcached ones used directly.
Alternatively, add master key via array ref support to the methods in
::libmemcached. Either way the effect on performance should be significant.

Redo tools/benchmarks.pl performance tests (ensuring that methods are not called in
void context unless it's appropriate).

Try using Cache::Memcached::Fast's test suite to test this module.
Via private lib/Cache/Memcached/libmemcachedAsFast.pm wrapper.

Implement automatic no-reply on calls in void context (like Cache::Memcached::Fast).
That should yield a signigicant performance boost.

=head1 AUTHOR

Copyright (c) 2008 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

With contributions by Tim Bunce.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
