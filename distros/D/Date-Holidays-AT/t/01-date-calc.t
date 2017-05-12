#!perl -T

# This tests if Data::Calc is really installed.

use Test::More tests => 1;

BEGIN {
	use_ok( 'Date::Calc', 5.0);
}
