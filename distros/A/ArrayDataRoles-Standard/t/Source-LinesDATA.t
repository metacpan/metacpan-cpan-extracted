#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ArrayData::Test::Source::LinesDATA;

my $t = ArrayData::Test::Source::LinesDATA->new;

$t->reset_iterator;
is_deeply($t->get_next_item, 1);
is_deeply($t->get_next_item , 2);
is_deeply($t->get_next_item , 3);
is_deeply($t->get_next_item , 4);
is_deeply($t->get_next_item , 5);
dies_ok { $t->get_next_item };

$t->reset_iterator;
is_deeply($t->get_next_item, 1);

done_testing;
