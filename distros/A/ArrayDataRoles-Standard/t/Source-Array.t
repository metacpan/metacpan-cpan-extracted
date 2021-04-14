#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ArrayData::Test::Source::Array;

my $t = ArrayData::Test::Source::Array->new(array=>[1,2,3]);

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
