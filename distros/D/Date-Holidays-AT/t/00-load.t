#!perl -T

# This tests if Date::Holidays::AT can be loaded fully

use Test::More tests => 1;

BEGIN {
	use_ok( 'Date::Holidays::AT' );
}
