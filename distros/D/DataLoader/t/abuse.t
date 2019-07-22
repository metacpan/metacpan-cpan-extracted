# Test abuse of public API
use v5.14;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More 0.96;
use Test::Deep;
use Test::Exception;
use DataLoader::Test qw(await is_promise_ok id_loader);

use AnyEvent;
use Data::Dump qw(dump);

use DataLoader;

# Show stack trace for timeouts
$Carp::Verbose = 1;

subtest 'loader creation requires a function', sub {
    throws_ok {
        DataLoader->new()
    } qr/batch_load_func must be a function that accepts.*but got: undef/;

    throws_ok {
        DataLoader->new({})
    } qr/batch_load_func must be a function that accepts.*but got: \{\}/;
};

subtest 'load function requires a key', sub {
    my ($loader) = id_loader();

    throws_ok { $loader->load() } qr/load: key is required/;
    throws_ok { $loader->load(undef) } qr/load: key must be defined/;
    throws_ok { $loader->load(1, 2) } qr/load: too many arguments/;

    lives_ok { $loader->load(0) } 'falsy values are fine';
};

subtest 'load_many function requires a list of keys', sub {
    my ($loader) = id_loader();

    # The JS version accepts a single Array argument. We accept a list,
    # so argument checking is simpler here.
    subtest 'Allow an empty list', sub {
        my $promise;
        lives_ok { $promise = $loader->load_many() };
        cmp_deeply( [await($promise)], [] );
    };
};

subtest 'Batch function must return a Promise, not undef', sub {
    my $bad_loader = DataLoader->new(sub { return });
    throws_ok { await($bad_loader->load(1)) }
        qr/DataLoader batch function did not return a Promise/;
};

subtest 'Batch function must return a Promise, not a value', sub {
    # Note: this returns the keys directly, rather than a promise to the keys.
    my $bad_loader = DataLoader->new(sub { return @_ });
    throws_ok { await($bad_loader->load(1)) }
        qr/DataLoader batch function did not return a Promise/;

    # This returns some random object that is not a promise
    my $bad_loader2 = DataLoader->new(sub { return bless {}, 'MyPackage' });
    throws_ok { await($bad_loader2->load(1)) }
        qr/DataLoader batch function did not return a Promise/;
};

subtest 'Batch function must return the correct number of keys', sub {
    my $bad_loader = DataLoader->new(sub { return Mojo::Promise->resolve(1,2) });
    throws_ok { await($bad_loader->load(1)) }
        qr/DataLoader batch function returned the wrong number of keys/;
};

subtest 'Cache key function must be a function', sub {
    throws_ok { DataLoader->new(sub { 1 }, cache_key_func => []) }
        qr/cache_key_func must be a function/;
    throws_ok { DataLoader->new(sub { 1 }, cache_key_func => 'bar') }
        qr/cache_key_func must be a function/;
    # undef is allowed (= default to identity function)
};

subtest 'Cache hashref must be a hashref', sub {
    throws_ok { DataLoader->new(sub { 1 }, cache_hashref => []) }
        qr/cache_hashref must be a HASH ref/;
    throws_ok { DataLoader->new(sub { 1 }, cache_hashref => 'foo') }
        qr/cache_hashref must be a HASH ref/;
    # undef is allowed (= default to local hashref)
};

subtest 'max_batch_size must be valid', sub {
    throws_ok { DataLoader->new(sub { 1 }, max_batch_size => 'foo') }
        qr/max_batch_size must be a positive integer/;
    throws_ok { DataLoader->new(sub { 1 }, max_batch_size => 0) }
        qr/max_batch_size cannot be zero/;
};

subtest 'invalid args in constructor', sub {
    throws_ok { DataLoader->new(sub { 1 }, invalid_test_arg => 1) }
        qr/unknown options? invalid_test_arg/;
};

done_testing;
