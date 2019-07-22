use v5.14;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More 0.96;
use Test::Deep;
use DataLoader::Test qw(await make_test_loader id_loader);

use Mojo::Promise;

subtest 'await' => sub {
    my $promise = Mojo::Promise->resolve(1);
    is( await($promise), 1 );

    my $list_promise = Mojo::Promise->resolve(1,2);
    cmp_deeply( [await($list_promise)], [1,2] );
};

subtest 'make_test_loader' => sub {
    my ($loader, $calls) = make_test_loader { $_ * 2 } cache => 0;
    isa_ok($loader, 'DataLoader');

    is( await($loader->load(1)), 2 );
    is( await($loader->load(2)), 4 );
    is( await($loader->load(2)), 4 );
    cmp_deeply( $calls, [[1], [2], [2]], 'caching disabled' );
};

subtest 'id_loader' => sub {
    my ($loader, $calls) = id_loader();
    isa_ok($loader, 'DataLoader');
    is( await($loader->load("foo")), "foo" );
    cmp_deeply( $calls, [["foo"]] );
    is( await($loader->load("bar")), "bar" );
    cmp_deeply( $calls, [["foo"], ["bar"]] );

    my ($loader2, $calls2) = id_loader(cache => 0);
    is( await($loader2->load(1)), 1 );
    is( await($loader2->load(1)), 1 );
    cmp_deeply( $calls2, [[1], [1]], 'caching disabled' );
};

done_testing;
