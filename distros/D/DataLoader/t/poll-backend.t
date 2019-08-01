# Test of basic API.
use v5.14;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More 0.96;
use Test::Deep;

BEGIN {
    $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use DataLoader::Test qw(is_promise_ok id_loader);
use DataLoader;

subtest 'works with Poll backend and next_tick (non-EV)', sub {
    my ($identity_loader) = id_loader();

    my $promise1 = $identity_loader->load(1);
    is_promise_ok($promise1);

    # Have to manually await, as AnyEvent won't work
    my $value;
    $promise1->then(sub { $value = $_[0] });
    $promise1->wait;

    is( $value, 1 );
};

done_testing;
