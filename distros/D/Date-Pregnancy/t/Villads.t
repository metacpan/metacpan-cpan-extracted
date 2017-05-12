# $Id$

use strict;
use Test::More tests => 10;
use DateTime;

use_ok( "Date::Pregnancy", qw(calculate_birthday calculate_week calculate_month));

my $dt = DateTime->new(
	year  => 2004,
	month => 3,
	day   => 19,
);

my $villads_birthday_266days = calculate_birthday(
	first_day_of_last_period => $dt
);

is($villads_birthday_266days->day, 24);
is($villads_birthday_266days->month, 12);
is($villads_birthday_266days->year, 2004);

my $villads_birthday_40weeks = calculate_birthday(
	first_day_of_last_period => $dt,
	method                   => '40weeks'
);

is($villads_birthday_40weeks->day, 24);
is($villads_birthday_40weeks->month, 12);
is($villads_birthday_40weeks->year, 2004);

my $villads_birthday_countback = calculate_birthday(
	first_day_of_last_period => $dt,
	method                   => 'countback'
);

is($villads_birthday_countback->day, 26);
is($villads_birthday_countback->month, 12);
is($villads_birthday_countback->year, 2004);

print STDERR "\nVillads' birthday is calculated to be:\n";
print STDERR $villads_birthday_266days->dmy." according to the 266 days method\n";
print STDERR $villads_birthday_40weeks->dmy." according to the 40 weeks method\n";
print STDERR $villads_birthday_countback->dmy." according to the count back method\n";
