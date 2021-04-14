#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ArrayData::Test::Source::LinesDATA;

my $t = ArrayData::Test::Source::LinesDATA->new;

$t->reset_iterator;
is_deeply($t->get_elem, 1);
is_deeply($t->get_elem , 2);
is_deeply($t->get_elem , 3);
is_deeply($t->get_elem , 4);
is_deeply($t->get_elem , 5);
is_deeply($t->get_elem , undef);
dies_ok { $t->elem };

$t->reset_iterator;
is_deeply($t->elem, 1);

done_testing;
