#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ArrayData::Test::Spec::Basic;

my $ary = ArrayData::Test::Spec::Basic->new;

subtest "elem, reset_iterator" => sub {
    #$ary->reset_iterator;
    is_deeply($ary->elem, 1);
    is_deeply($ary->elem, 2);
    $ary->reset_iterator;
    is_deeply($ary->elem, 1);
    is_deeply($ary->elem, 2);
    is_deeply($ary->elem, undef);
    is_deeply($ary->elem, 4);
    dies_ok { $ary->elem };
};

subtest "get_elem, reset_iterator" => sub {
    $ary->reset_iterator;
    is_deeply($ary->get_elem, 1);
    is_deeply($ary->get_elem, 2);
    $ary->reset_iterator;
    is_deeply($ary->get_elem, 1);
    is_deeply($ary->get_elem, 2);
    is_deeply($ary->get_elem, undef);
    is_deeply($ary->get_elem, 4);
    is_deeply($ary->get_elem, undef);
};

subtest "get_elem_count, get_iterator_index" => sub {
    $ary->reset_iterator;
    is($ary->get_iterator_index, 0);
    is($ary->get_elem_count, 4);
};

subtest get_all_elems => sub {
    is_deeply($ary->get_all_elems, [
        1,
        2,
        undef,
        4,
    ]);
};

subtest each_elem => sub {
    my $row;
    $ary->each_elem(sub { $row //= $_[0] });
    is_deeply($row, 1);
};

done_testing;
