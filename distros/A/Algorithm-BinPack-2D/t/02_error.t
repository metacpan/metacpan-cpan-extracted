# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Algorithm::BinPack::2D;

subtest 'Add a too big item' => sub {
    my $packer = Algorithm::BinPack::2D->new(
        binwidth  => 500,
        binheight => 400,
    );

    $packer->add_item(label => 'one',   width => 300, height => 100);
    $packer->add_item(label => 'two',   width => 200, height => 100);
    $packer->add_item(label => 'three', width => 100, height => 200);
    $packer->add_item(label => 'as is', width => 500, height => 400);
    dies_ok {
        $packer->add_item(label => 'too big', width => 501, height => 401);
    }
    'A too big item not to be added';
    lives_ok {
        $packer->add_item(label => 'four', width => 100, height => 200);
    }
    'After inserting a too big item';
    dies_ok {
        $packer->add_item(
            label  => 'minus width and height', width => -1,
            height => -1
        );
    }
    'An item with minus width and height';
    dies_ok {
        $packer->add_item(width => 1, height => 1);
    }
    'An item without label';
    dies_ok {
        $packer->add_item(label => 'height only', height => 1);
    }
    'An item without width';
    dies_ok {
        $packer->add_item(label => 'width only', width => 1);
    }
    'An item without height';
};

done_testing;
