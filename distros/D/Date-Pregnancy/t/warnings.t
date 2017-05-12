# $Id: warnings.t 1596 2005-10-14 05:02:32Z jonasbn $

use strict;
use Test::More tests => 10;
use DateTime;

#test 1
use_ok( "Date::Pregnancy", qw(
	calculate_birthday
	calculate_week
	calculate_month
	_countback 
	_266days 
	_40weeks
));

#test 2
is(_40weeks(), undef);

#test 3
is(_266days(), undef);

my $dt = DateTime->new(
	year  => 2004,
	month => 3,
	day   => 19,
);

#test 4
is(_266days($dt), undef);

#test 5
is(_countback(), undef);

#test 6
is(calculate_birthday(), undef);

#test 7
is(calculate_week(), undef);

#test 8
is(calculate_week(date => $dt), undef);

#test 9
is(calculate_month(), undef);

#test 10
is(calculate_month(birtday => $dt), undef);
