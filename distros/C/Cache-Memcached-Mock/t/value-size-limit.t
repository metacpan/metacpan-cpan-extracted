use Test::More tests => 6;
use Cache::Memcached::Mock;

my $c = Cache::Memcached::Mock->new();

my $some_key = 'some_key';
my $some_value = 'abracadabra';

# Default memcached value is 1Mb
my $very_long_value = ' ' x (1024*1024) . ' ... and then some...';
ok(length($very_long_value) > (1024 * 1024));

is(
    $c->get($some_key) => undef,
    'get() should return an undefined value'
);

ok(
    $c->set($some_key, $some_value),
    'set some value, and check that it works fine'
);
is(
    $c->get($some_key) => $some_value,
    'yes, it works just fine'
);

# Restart from scratch
$c->delete($some_key);

ok(
    ! $c->set($some_key, $very_long_value),
    'set of a value longer than default limit should fail'
);

is(
    $c->get($some_key) => undef,
    q(We shouldn't be able to get the value back, since set failed)
);

