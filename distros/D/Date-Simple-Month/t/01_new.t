use strict;
use Test::More 'no_plan';

use Date::Simple::Month;
use Date::Simple;

my ($mday,$mon,$year) = (localtime(time))[3..5];
$mon++;
$year+=1900;

my $m = Date::Simple::Month->new();
isa_ok $m, 'Date::Simple::Month', 'isa Date::Simple::Month';
is $m->year , $year, 'current year';
is $m->month , $mon, 'current month';

$m = Date::Simple::Month->new(Date::Simple->new);
isa_ok $m, 'Date::Simple::Month', 'isa Date::Simple::Month';
is $m->year , $year, 'current year';
is $m->month , $mon, 'current month';

$m = Date::Simple::Month->new(7);
isa_ok $m, 'Date::Simple::Month', 'isa Date::Simple::Month';
is $m->year , $year, 'current year';
is $m->month , 7, 'month is July';

$m = Date::Simple::Month->new(1978, 7);
isa_ok $m, 'Date::Simple::Month', 'isa Date::Simple::Month';
is $m->year , 1978, 'year is 1978';
is $m->month , 7, 'month is July';


