# Test of basic API.
use v5.14;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More 0.96;
use Test::Deep;
use DataLoader::Test qw(await id_loader make_test_loader);

use AnyEvent;
use Data::Dump qw(dump);

use DataLoader;

# Show stack trace for timeouts
$Carp::Verbose = 1;

subtest 'May disable batching', sub {
    my ($loader, $load_calls) = id_loader(batch => 0);

    my @promises = map { $loader->load($_) } (1..3);

    my @values = await(DataLoader->all(@promises));

    cmp_deeply(\@values, [1,2,3]);
    cmp_deeply($load_calls, [[1], [2], [3]] );
};

subtest 'May disable caching', sub {
    my ($loader, $load_calls) = id_loader(cache => 0);
    is( await($loader->load(1)), 1 );
    is( await($loader->load(1)), 1 );
    cmp_deeply( $load_calls, [[1], [1]] );
};

subtest 'May disable caching (advanced)', sub {
    my ($loader, $load_calls) = id_loader(cache => 0);
    my @values = await($loader->load_many('A', 'B'));
    cmp_deeply( \@values, ['A', 'B'] );
    cmp_deeply( $load_calls, [['A', 'B']] );

    @values = await($loader->load_many('A', 'C'));
    cmp_deeply( \@values, ['A', 'C'] );
    cmp_deeply( $load_calls, [['A', 'B'], ['A', 'C']] );

    @values = await($loader->load_many('A', 'B', 'C'));
    cmp_deeply( \@values, ['A', 'B', 'C'] );
    cmp_deeply( $load_calls, [['A', 'B'], ['A', 'C'], ['A', 'B', 'C']] );
};

subtest 'Keys are repeated in batch when cache disabled', sub {
    my ($loader, $load_calls) = id_loader(cache => 0);
    
    my @values = await(Mojo::Promise->all(
        $loader->load('A'),
        $loader->load('C'),
        $loader->load('D'),
        $loader->load_many(qw(C D A A B)),
    ));
    cmp_deeply( \@values, [ ['A'], ['C'], ['D'], [qw(C D A A B)] ] )
        or diag('got: ' . dump(\@values));

    cmp_deeply( $load_calls, [[qw(A C D C D A A B)]] );
};

subtest 'Accepts a custom cache hashref', sub {
    {
        package MyCache;
        require Tie::Hash;
        our @ISA = qw(Tie::StdHash);
    }
    tie my %cache, 'MyCache';
    my ($loader) = id_loader(cache_hashref => \%cache);
    await($loader->load(1));
    cmp_deeply( [sort keys %cache], [1] );
    await($loader->load(2));
    cmp_deeply( [sort keys %cache], [1, 2] );
    $loader->clear_all;
    cmp_deeply( [sort keys %cache], [] );
};

subtest 'Accepts a custom cache_key_func', sub {
    my ($loader, $load_calls) = make_test_loader { lc($_) } (
        cache_key_func => sub { lc }
    );

    subtest 'Loads using cache_key_func', sub {
        is( await($loader->load('A')), 'a' );
        is( await($loader->load('a')), 'a' );
        is( await($loader->load('b')), 'b' );
        is( await($loader->load('B')), 'b' );
        
        cmp_deeply( $load_calls, [['A'], ['b']] );
    };

    subtest 'Clears using cache_key_func', sub {
        $loader->clear('A'); 
        is( await($loader->load('a')), 'a' );
        cmp_deeply( $load_calls, [['A'], ['b'], ['a']] );
    };

    subtest 'Primes using cache_key_func', sub {
        $loader->prime('C', 1);
        is( await($loader->load('c')), 1);
        is( await($loader->load('C')), 1);
        cmp_deeply( $load_calls, [['A'], ['b'], ['a']] );
    };
};

done_testing;
