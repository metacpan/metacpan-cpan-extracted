use strict;
use warnings;
use Test::More;

BEGIN
{
    if (! $ENV{DATA_THROTTLER_MEMCACHED_DATA}) {
        plan( skip_all => "Specify your memcached host in DATA_THROTTLER_MEMCACHED_DATA to enable this test (e.g. env DATA_THROTTLER_MEMCACHED_DATA=127.0.0.1:11211)" );
    } else {
        plan( tests => 9 );
        use_ok("Data::Throttler::Memcached");
    }
}

my $throttler = Data::Throttler::Memcached->new(
    max_items => 2,
    interval  => 60,
    cache     => {
        data => $ENV{DATA_THROTTLER_MEMCACHED_DATA}
    }
);

is($throttler->try_push(), 1, "1st item");
is($throttler->try_push(), 1, "2nd item");
is($throttler->try_push(), 0, "3nd item");

is($throttler->try_push(key => "foobar"), 1, "1st item (key)");
is($throttler->try_push(key => "foobar"), 1, "2nd item (key)");
is($throttler->try_push(key => "foobar"), 0, "3nd item (key)");

$throttler = Data::Throttler::Memcached->new(
    max_items => 2,
    interval  => 2,
    cache     => {
        data => $ENV{DATA_THROTTLER_MEMCACHED_DATA}
    }
);

$throttler->try_push() for (1..3);
is($throttler->try_push(), 0, "rejected before sleep");
sleep(2);
is($throttler->try_push(), 1, "1st item after sleep");