#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'BBS::UserInfo' );
}

diag( "Testing BBS::UserInfo $BBS::UserInfo::VERSION, Perl $], $^X" );
