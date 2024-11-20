#!perl

use utf8;
use Test::More tests => 2;

BEGIN {
	delete $ENV{'LANG'};
	delete $ENV{'LC_ALL'};
	delete $ENV{'LC_MESSAGES'};
	use_ok( 'Date::Holidays::BY' );
}
is Date::Holidays::BY::is_holiday(2024,1,1), 'New Year';

done_testing();
