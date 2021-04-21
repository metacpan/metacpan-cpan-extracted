#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ArrayData::Test::Source::Iterator;

my $t = ArrayData::Test::Source::Iterator->new(num_elems=>3);

$t->reset_iterator;
is_deeply($t->get_next_item, 1);
is_deeply($t->get_next_item, 2);
is_deeply($t->get_next_item, 3);
dies_ok { $t->get_next_item };
$t->reset_iterator;
is_deeply($t->get_next_item , 1);
is($t->get_item_count, 3);

done_testing;
