use strict;
use warnings;
use Test::More;

plan tests => 6;

use Class::Date qw(now gmdate);
ok(1);

my $t = gmdate(315532800); # 00:00:00 1/1/1980

is $t->year, 1980, 'year';

is $t->hour, 0, 'hour';

is $t->mon, 1, 'mon';

cmp_ok now, '>', "1970-1-1";

cmp_ok gmdate("now"), '>', "1970-1-1";
