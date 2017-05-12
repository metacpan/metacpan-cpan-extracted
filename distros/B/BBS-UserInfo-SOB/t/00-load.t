#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'BBS::UserInfo::SOB' );
}

diag( "Testing BBS::UserInfo::SOB $BBS::UserInfo::SOB::VERSION, Perl $], $^X" );
