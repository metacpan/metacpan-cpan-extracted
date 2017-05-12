#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Config::IniRegEx' );
}

diag( "Testing Config::IniRegEx $Config::IniRegEx::VERSION, Perl $], $^X" );
