#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ArrayData::Test::Spec::Seekable;

my $ary = ArrayData::Test::Spec::Seekable->new;

subtest set_iterator_index => sub {
    $ary->set_iterator_index(1);
    is_deeply($ary->get_elem, 2);
    $ary->set_iterator_index(-4);
    is_deeply($ary->get_elem, 1);
    is_deeply($ary->get_elem, 2);

    dies_ok { $ary->set_iterator_index(4) };
    dies_ok { $ary->set_iterator_index(-5) };
    lives_ok { $ary->set_iterator_index(-4) };
};

done_testing;
