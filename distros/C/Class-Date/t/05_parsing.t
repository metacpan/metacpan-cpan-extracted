use strict;
use warnings;
use Test::More;

plan tests => 7;

use Class::Date qw(gmdate);

ok(1);

my $t = gmdate("2008-8-3T11:7:10");

is $t->year, 2008, 'year';
is $t->month, 8,   'month';
is $t->day, 3,     'day';
is $t->hour, 11,   'hour';
is $t->min, 7,     'min';
is $t->second, 10, 'second';
