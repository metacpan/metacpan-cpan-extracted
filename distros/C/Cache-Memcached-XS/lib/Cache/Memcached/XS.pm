package Cache::Memcached::XS;

use 5.008006;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Cache::Memcached::XS', $VERSION);

use Storable;

# flag definitions
use constant F_STORABLE => 1;
use constant F_COMPRESS => 2;

# size savings required before saving compressed value
use constant COMPRESS_SAVINGS => 0.20; # percent

use vars qw($HAVE_ZLIB);

BEGIN {
    $HAVE_ZLIB = eval "use Compress::Zlib (); 1;";
}

sub new
{
	my $this	=	shift;
	my $class	=	ref($this) || $this;
	my $args	=	shift;
	my $self	=	{};

	bless $self,$class;

	$self->{mc}	=	mc_new();
	if (defined $args->{servers})
	{
		$self->set_servers($args->{servers});
	}
	$self->{$_} = $args->{$_} for (qw(readonly compress_threshold));

	return $self;
}

sub set_servers
{
	my $self	=	shift;
	my $servers	=	shift;

	return if !ref $servers || ref $servers ne "ARRAY";
	for my $server (@$servers)
	{
		if (ref $server)
		{
			mc_server_add4($self->{mc},$server->[0]) for ( 1 .. ($server->[1] || 1));
		}
		else
		{
			mc_server_add4($self->{mc},$server);
		}
	}
}

sub set_compress_threshold
{
	my $self	=	shift;
	my $threshold	=	shift;

	$self->{compress_threshold}	=	$threshold;
}

sub set_readonly
{
	my $self	=	shift;
	my $readonly	=	shift;

	$self->{readonly}	=	$readonly;
}

sub enable_compress
{
	my $self	=	shift;
	my $enable	=	shift;

	$self->{enable_compress}	=	$enable;
}

sub get
{
	my $self	=	shift;
	my $key	=	shift;

	my $ret	=	$self->get_multi($key);

	return $ret->{$key};
}

sub get_multi
{
	my $self	=	shift;

	my $results	=	{};
	my $flags	=	{};
	my $xsresults	=	[ $results, $flags ];
	my $req		=	mc_req_new();
	for my $key (@_)
	{
		my $res	=	mc_req_add($req,$key);
		mc_res_register_callback($req,$res,$xsresults);
	}
	mc_get($self->{mc},$req);
	for my $key (keys %{$results})
	{
		$results->{$key} = Compress::Zlib::memGunzip($results->{$key})
			if $HAVE_ZLIB && $flags->{$key} & F_COMPRESS;
		if ($flags->{$key} & F_STORABLE)
		{
			# wrapped in eval in case a perl 5.6 Storable tries to
			# unthaw data from a perl 5.8 Storable.  (5.6 is stupid
			# and dies if the version number changes at all.  in 5.8
			# they made it only die if it unencounters a new feature)
			eval
			{
				$results->{$key} = Storable::thaw($results->{$key});
			};
			# so if there was a problem, just treat it as a cache miss.
			if ($@)
			{
				delete $results->{$key};
			}
		}
	}
	return $results;
}

sub prepare_value
{
	my $self	=	shift;
	my $value	=	shift;
	my $exp		=	shift;
	my $flags	=	0;

	if (ref $value)
	{
		$value = Storable::nfreeze($value);
		$flags |= F_STORABLE;
	}

	my $len = length($value);

	if ($self->{'compress_threshold'} && $HAVE_ZLIB && $self->{'compress_enable'} &&
		$len >= $self->{'compress_threshold'})
	{
		my $c_value = Compress::Zlib::memGzip($value);
		my $c_len = length($c_value);

		# do we want to keep it?
		if ($c_len < $len*(1 - COMPRESS_SAVINGS))
		{
			$value = $c_value;
			$len = $c_len;
			$flags |= F_COMPRESS;
		}
	}

	$exp = int($exp || 0);

	return ($value,$exp,$flags);
}

sub set
{
	my $self	=	shift;
	my $key		=	shift;
	my $value	=	shift;
	my $exp		=	shift;

	return if $self->{readonly};
	return !mc_set($self->{mc},$key,$self->prepare_value($value,$exp));
}

sub add
{
	my $self	=	shift;
	my $key		=	shift;
	my $value	=	shift;
	my $exp		=	shift;

	return if $self->{readonly};
	return !mc_add($self->{mc},$key,$self->prepare_value($value,$exp));
}

sub replace
{
	my $self	=	shift;
	my $key		=	shift;
	my $value	=	shift;
	my $exp		=	shift;

	return if $self->{readonly};
	return !mc_replace($self->{mc},$key,$self->prepare_value($value,$exp));
}

sub incr
{
	my $self	=	shift;
	my $key		=	shift;
	my $value	=	shift;

	return if $self->{readonly};
	return mc_incr($self->{mc},$key,$value || 1);
}

sub decr
{
	my $self	=	shift;
	my $key		=	shift;
	my $value	=	shift;

	return if $self->{readonly};
	return mc_decr($self->{mc},$key,$value || 1);
}

sub delete
{
	my $self	=	shift;
	my $key		=	shift;
	my $hold	=	shift;

	return if $self->{readonly};
	return mc_delete($self->{mc},$key,$hold || 0);
}

1;
__END__

=head1 NAME

Cache::Memcached::XS - client library for memcached (memory cache daemon) using libmemcache

=head1 SYNOPSIS

  use Cache::Memcached::XS;

  $memd = new Cache::Memcached {
    'servers' => [ "10.0.0.15:11211", "10.0.0.15:11212",
                   "10.0.0.17:11211", [ "10.0.0.17:11211", 3 ] ],
    'compress_threshold' => 10_000,
  };
  $memd->set_servers($array_ref);
  $memd->set_compress_threshold(10_000);
  $memd->enable_compress(0);

  $memd->set("my_key", "Some value");
  $memd->set("object_key", { 'complex' => [ "object", 2, 4 ]});

  $val = $memd->get("my_key");
  $val = $memd->get("object_key");
  if ($val) { print $val->{'complex'}->[2]; }

  $memd->incr("key");
  $memd->decr("key");
  $memd->incr("key", 2);

=head1 DESCRIPTION

This is the Perl API for memcached, a distributed memory cache daemon.
More information is available at:

  http://www.danga.com/memcached/

This version differs from the original Cache::Memcached perl client in
that it uses the libmemcache library and uses quite a lot less CPU.

A few features from the original client are not (yet) supported:

=over 4

=item - no_rehash

=item - debug

=item - stats

=item - disconnect_all

=back

Other than this, it should be pretty much a drop-in replacement for the
original client.


=head1 CONSTRUCTOR

=over 4

=item C<new>

Takes one parameter, a hashref of options.  The most important key is
C<servers>, but that can also be set later with the C<set_servers>
method.  The servers must be an arrayref of hosts, each of which is
either a scalar of the form C<10.0.0.10:11211> or an arrayref of the
former and an integer weight value.  (The default weight if
unspecified is 1.)  It's recommended that weight values be kept as low
as possible, as this module currently emulates weights by having
multiple identical servers.

Use C<compress_threshold> to set a compression threshold, in bytes.
Values larger than this threshold will be compressed by C<set> and
decompressed by C<get>.

Use C<readonly> to disable writes to backend memcached servers.  Only
get and get_multi will work.  This is useful in bizarre debug and
profiling cases only.

=back

=head1 METHODS

=over 4

=item C<set_servers>

Sets the server list this module distributes key gets and sets between.
The format is an arrayref of identical form as described in the C<new>
constructor.

=item C<set_readonly>

Sets the C<readonly> flag.  See C<new> constructor for more information.

=item C<set_compress_threshold>

Sets the compression threshold. See C<new> constructor for more information.

=item C<enable_compress>

Temporarily enable or disable compression.  Has no effect if C<compress_threshold>
isn't set, but has an overriding effect if it is.

=item C<get>

my $val = $memd->get($key);

Retrieves a key from the memcache.  Returns the value (automatically
thawed with Storable, if necessary) or undef.

The $key can optionally be an arrayref, with the first element being the
hash value, if you want to avoid making this module calculate a hash
value.  You may prefer, for example, to keep all of a given user's
objects on the same memcache server, so you could use the user's
unique id as the hash value.

=item C<get_multi>

my $hashref = $memd->get_multi(@keys);

Retrieves multiple keys from the memcache doing just one query.
Returns a hashref of key/value pairs that were available.

This method is recommended over regular 'get' as it lowers the number
of total packets flying around your network, reducing total latency,
since your app doesn't have to wait for each round-trip of 'get'
before sending the next one.

=item C<set>

$memd->set($key, $value[, $exptime]);

Unconditionally sets a key to a given value in the memcache.  Returns true
if it was stored successfully.

The $key can optionally be an arrayref, with the first element being the
hash value, as described above.

The $exptime (expiration time) defaults to "never" if unspecified.  If
you want the key to expire in memcached, pass an integer $exptime.  If
value is less than 60*60*24*30 (30 days), time is assumed to be relative
from the present.  If larger, it's considered an absolute Unix time.

=item C<add>

$memd->add($key, $value[, $exptime]);

Like C<set>, but only stores in memcache if the key doesn't already exist.

=item C<replace>

$memd->replace($key, $value[, $exptime]);

Like C<set>, but only stores in memcache if the key already exists.  The
opposite of C<add>.

=item C<delete>

$memd->delete($key[, $time]);

Deletes a key.  You may optionally provide an integer time value (in seconds) to
tell the memcached server to block new writes to this key for that many seconds.
(Sometimes useful as a hacky means to prevent races.)  Returns true if key
was found and deleted, and false otherwise.

=item C<incr>

$memd->incr($key[, $value]);

Sends a command to the server to atomically increment the value for
$key by $value, or by 1 if $value is undefined.  Returns undef if $key
doesn't exist on server, otherwise it returns the new value after
incrementing.  Value should be zero or greater.  Overflow on server
is not checked.  Be aware of values approaching 2**32.  See decr.

=item C<decr>

$memd->decr($key[, $value]);

Like incr, but decrements.  Unlike incr, underflow is checked and new
values are capped at 0.  If server value is 1, a decrement of 2
returns 0, not -1.

=back

=head1 BUGS

Any in libmemcache plus many others of my own.

=head1 COPYRIGHT

This module is Copyright (c) 2006 Jacques Caron & Oxado SARL
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 FAQ

See the memcached website:
   http://www.danga.com/memcached/

=head1 AUTHORS

Jacques Caron <jc@oxado.com>

Based on previous work by:

Brad Fitzpatrick <brad@danga.com>

Anatoly Vorobey <mellon@pobox.com>

Brad Whitaker <whitaker@danga.com>

Jamie McCarthy <jamie@mccarthy.vg>

=cut
