#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'BBS::UserInfo::Wretch' );
}

diag( "Testing BBS::UserInfo::Wretch $BBS::UserInfo::Wretch::VERSION, Perl $], $^X" );
