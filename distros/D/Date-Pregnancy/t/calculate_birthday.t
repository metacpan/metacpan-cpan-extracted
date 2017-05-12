# $Id$

use strict;
use Test::More tests => 17;
use DateTime;

#test 1
use_ok( "Date::Pregnancy", qw(calculate_birthday));

my $dt = DateTime->new(
	year  => 2004,
	month => 3,
	day   => 19,
);

my $birthday;

#test 2
ok($birthday = calculate_birthday(
	first_day_of_last_period => $dt,
));

#test 3
isa_ok($birthday, "DateTime");

#test 4
ok($birthday = calculate_birthday(
	first_day_of_last_period => $dt,
	period_cycle_length      => 28,
));

#test 5
isa_ok($birthday, "DateTime");

#test 6
is(calculate_birthday(), undef);

#test 7
ok($birthday = calculate_birthday(
	first_day_of_last_period => $dt,
	method                   => '40weeks',
));

#test 8
isa_ok($birthday, "DateTime");

#test 9
ok($birthday = calculate_birthday(
	first_day_of_last_period => $dt,
	method                   => '266days',
));

#test 10
isa_ok($birthday, "DateTime");

#test 11
ok($birthday = calculate_birthday(
	first_day_of_last_period => $dt,
	method                   => '266days',
	period_cycle_length      => 28,
));

#test 12
isa_ok($birthday, "DateTime");

#test 13
ok($birthday = calculate_birthday(
	first_day_of_last_period => $dt,
	method                   => '266days',
	period_cycle_length      => 29,
));

#test 14
isa_ok($birthday, "DateTime");

#test 15-17
is($birthday->day, 26);
is($birthday->year, 2004);
is($birthday->month, 12);
