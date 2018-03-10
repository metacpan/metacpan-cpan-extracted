#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Business::Inventory::Valuation;

subtest "sanity" => sub {
    dies_ok { Business::Inventory::Valuation->new() };
    dies_ok { Business::Inventory::Valuation->new(method => "foo") };

    my $biv = Business::Inventory::Valuation->new(method => "LIFO");
    dies_ok { $biv->buy(-1, 100) };

    $biv->buy(10, 100);

    dies_ok { $biv->sell(-1, 100) };
};

subtest "method=LIFO" => sub {
    my $biv = Business::Inventory::Valuation->new(method => 'LIFO');

    is_deeply([$biv->inventory], []);
    is_deeply([$biv->summary], [0, undef]);

    # buy: 100 units @1500
    $biv->buy (100, 1500);
    is_deeply([$biv->inventory], [[100, 1500]]);
    is_deeply([$biv->summary], [100, 1500]);

    # buy more: 150 units @1600
    $biv->buy (150, 1600);
    is_deeply([$biv->inventory], [[100, 1500], [150, 1600]]);
    is_deeply([$biv->summary], [250, 1560]);

    # sell: 50 units @1700
    $biv->sell( 50, 1700);
    is_deeply([$biv->inventory], [[100, 1500], [100, 1600]]);
    is_deeply([$biv->summary], [200, 1550]);

    # buy: 200 units @1500
    $biv->buy(200, 1500);
    is_deeply([$biv->inventory], [[100, 1500], [100, 1600], [200, 1500]]);
    is_deeply([$biv->summary], [400, 1525]);

    # sell: 350 units @1800
    $biv->sell(350, 1800);
    is_deeply([$biv->inventory], [[50, 1500]]);
    is_deeply([$biv->summary], [50, 1500]);

    # sell: 60 units @1700
    dies_ok { $biv->sell(60, 1800) };
};

subtest "method=FIFO" => sub {
    my $biv = Business::Inventory::Valuation->new(method => 'FIFO');

    is_deeply([$biv->inventory], []);
    is_deeply([$biv->summary], [0, undef]);

    # buy: 100 units @1500
    $biv->buy (100, 1500);
    is_deeply([$biv->inventory], [[100, 1500]]);
    is_deeply([$biv->summary], [100, 1500]);

    # buy more: 150 units @1600
    $biv->buy (150, 1600);
    is_deeply([$biv->inventory], [[100, 1500], [150, 1600]]);
    is_deeply([$biv->summary], [250, 1560]);

    # sell: 50 units @1700
    $biv->sell( 50, 1700);
    is_deeply([$biv->inventory], [[50, 1500], [150, 1600]]);
    is_deeply([$biv->summary], [200, 1575]);

    # buy: 200 units @1500
    $biv->buy(200, 1800);
    is_deeply([$biv->inventory], [[50, 1500], [150, 1600], [200, 1800]]);
    is_deeply([$biv->summary], [400, 1687.5]);

    # sell: 350 units @1800
    $biv->sell(350, 1900);
    is_deeply([$biv->inventory], [[50, 1800]]);
    is_deeply([$biv->summary], [50, 1800]);

    # sell: 60 units @1700
    dies_ok { $biv->sell(60, 1800) };
};

DONE_TESTING:
done_testing;
