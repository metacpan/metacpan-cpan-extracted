use v5.14;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More 0.96;
use Test::Deep;
use Test::Exception;
use DataLoader::Test qw(await is_promise_ok);

use AnyEvent;

use DataLoader;

subtest 'all' => sub {
    subtest 'resolves all values in order and returns as a list', sub {
        my $promise = DataLoader->all(
            Mojo::Promise->resolve(1),
            Mojo::Promise->resolve(2),
            Mojo::Promise->resolve(3),
        );
        is_promise_ok($promise);

        my @values = await($promise);
        cmp_deeply( \@values, [1,2, 3] );
    };

    subtest 'forwards rejection', sub {
        my $promise = DataLoader->all(
            Mojo::Promise->resolve(1),
            Mojo::Promise->reject("promise_error"),
        );
        is_promise_ok($promise);
        throws_ok { await($promise) } qr/promise_error/;
    };

    subtest 'resolves to an empty list if no promises passed', sub {
        my $promise = DataLoader->all();
        is_promise_ok($promise);

        cmp_deeply( [await($promise)], [] );
    };

    subtest 'throws if multiple values returned in any Promise', sub {
        my $promise = DataLoader->all(Mojo::Promise->resolve(1,2));
        is_promise_ok($promise);

        throws_ok { await($promise) } qr/all: got promise with multiple return values/;
    };
};

done_testing;
