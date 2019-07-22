# Test of basic API.
use v5.14;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More 0.96;
use Test::Deep;
use DataLoader::Test qw(await is_promise_ok id_loader);

use AnyEvent;
use Data::Dump qw(dump);

use DataLoader;

# Show stack trace for timeouts
$Carp::Verbose = 1;

subtest 'simple data loader', sub {
    my ($identity_loader) = id_loader();

    my $promise1 = $identity_loader->load(1);
    is_promise_ok($promise1);

    is( await($promise1), 1 );
};

subtest 'supports loading multiple keys in one call', sub {
    my ($identity_loader) = id_loader();

    my $promise_all = $identity_loader->load_many(1, 2);
    is_promise_ok($promise_all);

    cmp_deeply( [await($promise_all)], [1, 2] );

    my $promise_empty = $identity_loader->load_many();
    is_promise_ok($promise_empty);

    cmp_deeply( [await($promise_empty)], [] );
};

subtest 'batches multiple requests', sub {
    my ($identity_loader, $load_calls) = id_loader();

    my $promise1 = $identity_loader->load(1);
    my $promise2 = $identity_loader->load(2);

    my ($value1, $value2) = await(DataLoader->all($promise1, $promise2));
    is( $value1, 1 );
    is( $value2, 2 );

    cmp_deeply( $load_calls, [[1,2]], 'only one request made for both items' )
        or diag("got: " . dump($load_calls));
};

subtest 'batches multiple request with max batch sizes', sub {
    my ($identity_loader, $load_calls) = id_loader(max_batch_size => 2);

    my @vals = await(DataLoader->all(
        map { $identity_loader->load($_) } (1..3)
    ));
    cmp_deeply( \@vals, [1,2,3] );

    cmp_deeply( $load_calls, [ [1,2], [3] ], 'split into two batches' );

    subtest 'only splits batches if needed', sub {
        my ($identity_loader, $load_calls) = id_loader(max_batch_size => 100);

        await(DataLoader->all(
            map { $identity_loader->load($_) } (1..10)
        ));

        cmp_deeply( $load_calls, [ [1..10] ], 'single batch' );
    };
};

subtest 'caches identical requests', sub {
    my ($identity_loader, $load_calls) = id_loader();

    my $promise1a = $identity_loader->load(1);
    my $promise1b = $identity_loader->load(1);

    is( $promise1a, $promise1b, 'two promises are the same object' );

    my ($value1, $value2) = await(DataLoader->all($promise1a, $promise1b));
    is( $value1, 1 );
    is( $value2, 1 );

    cmp_deeply( $load_calls, [ [1] ], 'item only requested once' );
};

subtest 'caches repeated requests', sub {
    my ($identity_loader, $load_calls) = id_loader();

    my ($a, $b) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('B'),
    ));
    is( $a, 'A' );
    is( $b, 'B' );

    cmp_deeply( $load_calls, [ ['A', 'B'] ] );

    my ($a2, $c) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('C'),
    ));
    is( $a2, 'A' );
    is( $c, 'C' );

    cmp_deeply( $load_calls, [ ['A', 'B'], ['C'] ], 'no repeated A call' );

    my ($a3, $b2, $c2) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('B'),
        $identity_loader->load('C'),
    ));
    is( $a3, 'A' );
    is( $b2, 'B' );
    is( $c2, 'C' );

    cmp_deeply( $load_calls, [ ['A', 'B'], ['C'] ], 'no additional calls' );
};

subtest 'clears single value in loader', sub {
    my ($identity_loader, $load_calls) = id_loader();

    my ($a, $b) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('B'),
    ));
    is( $a, 'A' );
    is( $b, 'B' );

    cmp_deeply( $load_calls, [ ['A', 'B'] ] );

    $identity_loader->clear('A');

    my ($a2, $b2) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('B'),
    ));
    is( $a2, 'A' );
    is( $b2, 'B' );

    cmp_deeply( $load_calls, [ ['A', 'B'], ['A'] ], 'A requested anew' );
};

subtest 'clears all values in loader', sub {
    my ($identity_loader, $load_calls) = id_loader();

    my ($a, $b) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('B'),
    ));
    is( $a, 'A' );
    is( $b, 'B' );

    cmp_deeply( $load_calls, [ ['A', 'B'] ] );

    $identity_loader->clear_all;

    my ($a2, $b2) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('B'),
    ));
    is( $a2, 'A' );
    is( $b2, 'B' );

    cmp_deeply( $load_calls, [ ['A', 'B'], ['A', 'B'] ] );
};

subtest 'allows priming the cache', sub {
    my ($identity_loader, $load_calls) = id_loader();

    $identity_loader->prime('A', 'A*');

    my ($a, $b) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('B'),
    ));
    is( $a, 'A*' );
    is( $b, 'B' );

    cmp_deeply( $load_calls, [ ['B'] ] );
};

subtest 'does not prime keys that already exist', sub {
    my ($identity_loader, $load_calls) = id_loader();

    $identity_loader->prime('A', 'X');

    my ($a, $b) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('B'),
    ));
    is( $a, 'X' );
    is( $b, 'B' );

    $identity_loader->prime('A', 'Y');
    $identity_loader->prime('B', 'Y');

    my ($a2, $b2) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('B'),
    ));
    is( $a, 'X' );
    is( $b, 'B' );

    cmp_deeply( $load_calls, [ ['B'] ] );
};

subtest 'allows forcefully priming the cache', sub {
    my ($identity_loader, $load_calls) = id_loader();

    $identity_loader->prime('A', 'X');

    my ($a, $b) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('B'),
    ));
    is( $a, 'X' );
    is( $b, 'B' );

    $identity_loader->clear('A')->prime('A', 'Y');
    $identity_loader->clear('B')->prime('B', 'Y');

    my ($a2, $b2) = await(DataLoader->all(
        $identity_loader->load('A'),
        $identity_loader->load('B'),
    ));
    is( $a2, 'Y' );
    is( $b2, 'Y' );

    cmp_deeply( $load_calls, [ ['B'] ] );
};

subtest 'accepts objects as keys', sub {
    my ($loader, $calls) = id_loader();
    my $keyA = {};
    my $keyB = {};

    subtest 'Fetches as expected', sub {
        my ($valueA, $valueB) = await(DataLoader->all(
            $loader->load($keyA),
            $loader->load($keyB),
        ));

        is( $valueA, $keyA );
        is( $valueB, $keyB );

        is( @$calls, 1 );
        is( @{$calls->[0]}, 2 );
        is( $calls->[0][0], $keyA );
        is( $calls->[0][1], $keyB );
    };

    subtest 'Caching', sub {
        $loader->clear($keyA);
        my ($valueA, $valueB) = await(DataLoader->all(
            $loader->load($keyA),
            $loader->load($keyB),
        ));
        is( $valueA, $keyA );
        is( $valueB, $keyB );

        is( @$calls, 2 );
        is( @{$calls->[1]}, 1 );
        is( $calls->[1][0], $keyA, 'keyA refetched' );
    };
};

subtest 'accepted blessed objects', sub {
    my ($loader, $calls) = id_loader();
    my $obj = bless [], 'MyPackage';
    my $obj2 = bless [], 'MyPackage';
    is( await($loader->load($obj)), $obj );
    is( await($loader->load($obj)), $obj, 'cached' );
    $loader->clear($obj);
    is( await($loader->load($obj)), $obj, 'cleared' );
    $loader->clear($obj);
    $loader->prime($obj, $obj2);
    is( await($loader->load($obj)), $obj2, 'primed' );

    cmp_deeply( $calls, [
        [$obj],  # first load call
                 # second load call (cached)
        [$obj],  # third load call (after clearing cache)
                 # fourth load call (primed)
    ] );
};

done_testing;
