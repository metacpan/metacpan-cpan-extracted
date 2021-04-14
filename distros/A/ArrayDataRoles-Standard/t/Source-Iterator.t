#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ArrayData::Test::Source::Iterator;

my $t = ArrayData::Test::Source::Iterator->new(num_elems=>3);

$t->reset_iterator;
is_deeply($t->get_elem, 1);
is_deeply($t->get_elem, 2);
is_deeply($t->get_elem, 3);
is_deeply($t->get_elem, undef);
dies_ok { $t->elem };
$t->reset_iterator;
is_deeply($t->elem , 1);
is($t->get_elem_count, 3);

done_testing;
