#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ArrayData::Test::Spec::Basic;

my $ary = ArrayData::Test::Spec::Basic->new;

subtest "has_next_item, get_next_item, reset_iterator" => sub {
    #$ary->reset_iterator;
    ok($ary->has_next_item);
    is_deeply($ary->get_next_item, 1);
    is_deeply($ary->get_next_item, 2);
    $ary->reset_iterator;
    is_deeply($ary->get_next_item, 1);
    is_deeply($ary->get_next_item, 2);
    is_deeply($ary->get_next_item, undef);
    is_deeply($ary->get_next_item, 4);
    ok(!$ary->has_next_item);
    dies_ok { $ary->get_next_item };
};

subtest "get_item_count, get_iterator_pos" => sub {
    $ary->reset_iterator;
    is($ary->get_iterator_pos, 0);
    is($ary->get_item_count, 4);
};

subtest get_all_items => sub {
    is_deeply([$ary->get_all_items], [
        1,
        2,
        undef,
        4,
    ]);
};

subtest each_item => sub {
    my $row;
    $ary->each_item(sub { $row //= $_[0] });
    is_deeply($row, 1);
};

subtest "get_item_at_pos, has_item_at_pos" => sub {
    is_deeply($ary->get_item_at_pos(0), 1);
    ok($ary->has_item_at_pos(0));

    dies_ok { $ary->get_item_at_pos(4) };
    ok(!$ary->has_item_at_pos(4));
};

done_testing;
