package Cache::RedisDB;

use 5.010;
use strict;
use warnings;
use Carp;
use RedisDB 2.14;
use Sereal qw(looks_like_sereal);

=head1 NAME

Cache::RedisDB - RedisDB based cache system

=head1 DESCRIPTION

This is just a wrapper around RedisDB to have a single Redis object and connection per process. By default uses server redis://127.0.0.1, but it may be overwritten by REDIS_CACHE_SERVER environment variable. It transparently handles forks.

=head1 COMPATIBILITY AND REQUIREMENTS

Redis 2.6.12 and higher strongly recommended.  Required if you want to use
extended options in ->set().

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

    use Cache::RedisDB;
    Cache::RedisDB->set("namespace", "key", "value");
    Cache::RedisDB->get("namespace", "key");

=head1 METHODS

=head2 redis_uri

Returns a C<< redis:// >> redis URI which will be used for the initial Redis connection.

This will default to localhost on the standard port, and can be overridden with the
C<REDIS_CACHE_SERVER> environment variable.

=cut

sub redis_uri {

    my $redis_uri = $ENV{REDIS_CACHE_SERVER} // 'redis://127.0.0.1';

    # Probably a legacy TCP host:port
    $redis_uri = 'redis://' . $redis_uri if ($redis_uri =~ m#^[^/]+:[0-9]{1,5}$#);

    return $redis_uri;
}

=head2 redis_connection

Creates new connection to a Redis server and returns the corresponding L<RedisDB> object.

=cut

sub redis_connection {
    return RedisDB->new(
        url                => redis_uri(),
        reconnect_attempts => 3,
        on_connect_error   => sub {
            confess "Cannot connect: " . redis_uri();
        });
}

=head2 redis

Returns a singleton L<RedisDB> instance.

=cut

sub redis {
    state $redis;
    $redis //= redis_connection();
    return $redis;
}

=head2 get

Takes a C<$namespace> and C<$key> parameter, and returns the scalar value
corresponding to that cache entry.

This will automatically deserialise data stored with L<Sereal>. If no data
is found, this will return C<undef>.

=cut

sub get {
    my ($self, $namespace, $key) = @_;
    my $res = redis()->get(_cache_key($namespace, $key));
    if (looks_like_sereal($res)) {
        state $decoder = Sereal::Decoder->new();
        $res = $decoder->decode($res);
    }
    return $res;
}

=head2 mget

Retrieve values for multiple keys in a single call.

Similar to L</get>, this takes a C<$namespace> as the first parameter,
but it also accepts a list of C<@keys> to look up.

Returns an arrayref in the same order as the original keys. For any
key that had no value, the resulting arrayref will contain C<undef>.

=cut

sub mget {
    my ($self, $namespace, @keys) = @_;
    my $res = Cache::RedisDB::redis()->mget(map { Cache::RedisDB::_cache_key($namespace, $_) } @keys);
    state $decoder = Sereal::Decoder->new();
    return [map { ($_ && looks_like_sereal($_)) ? $decoder->decode($_) : $_ } @$res];
}

=head2 set

Creates or updates a Redis key under C<$namespace>, C<$key> using the scalar C<$value>.
Also takes an optional C<$exptime> as expiration time in seconds.

 $redis->set($namespace, $key, $value);
 $redis->set($namespace, $key, $value, $expiry_time);

Can also be provided a callback which will be executed once the command completes.

=cut

sub set {
    my ($self, $namespace, $key, $value, $exptime, $callback) = @_;
    if (not defined $value or ref $value or Encode::is_utf8($value)) {
        state $encoder = Sereal::Encoder->new({
            freeze_callbacks => 1,
        });
        $value = $encoder->encode($value);
    }
    my $cache_key = _cache_key($namespace, $key);
    if (defined $exptime) {
        $exptime = int(1000 * $exptime);
        # PX milliseconds -- Set the specified expire time, in milliseconds
        return redis()->set($cache_key, $value, "PX", $exptime, $callback // ());
    } else {
        return redis()->set($cache_key, $value, $callback // ());
    }
}

=head2 set_nw($namespace, $key, $value[, $exptime])

Same as I<set> but do not wait confirmation from server. If the server returns
an error, it will be ignored.

=cut

sub set_nw {
    my ($self, $namespace, $key, $value, $exptime) = @_;
    return $self->set($namespace, $key, $value, $exptime, RedisDB::IGNORE_REPLY);
}

=head2 del($namespace, $key1[, $key2, ...])

Delete given keys and associated values from the cache. I<$namespace> is common for all keys.
Returns number of deleted keys.

=cut

sub del {
    my ($self, $namespace, @keys) = @_;
    return redis->del(map { _cache_key($namespace, $_) } @keys);
}

=head2 keys($namespace)

Return an arrayref of all known keys in the provided C<$namespace>.

=cut

sub keys : method {    ## no critic (ProhibitBuiltinHomonyms)
    my ($self, $namespace) = @_;
    my $prefix = _cache_key($namespace, undef);
    my $pl     = length($prefix);
    return [map { substr($_, $pl) } @{redis()->keys($prefix . '*')}];
}

=head2 ttl($namespace, $key)

Return the Time To Live (in seconds) of a key in the provided I<$namespace>.

=cut

sub ttl {
    my ($self, $namespace, $key) = @_;

    my $ms = redis()->pttl(_cache_key($namespace, $key));
    # We pessimistically round to the start of the second where it
    # will disappear.  While slightly wrong, it is likely less confusing.
    # Nonexistent (or already expired) keys should return 0;
    return ($ms <= 0) ? 0 : int($ms / 1000);
}

sub _cache_key {
    my ($namespace, $key) = @_;
    $namespace //= '';
    $key       //= '';

    return $namespace . '::' . $key;
}

=head3 flushall

Delete all keys and associated values from the cache.

=cut

sub flushall {
    return redis()->flushall();
}

=head1 AUTHOR

binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cache-redisdb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cache-RedisDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cache::RedisDB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cache-RedisDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cache-RedisDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cache-RedisDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Cache-RedisDB/>

=back

=cut

1;    # End of Cache::RedisDB
