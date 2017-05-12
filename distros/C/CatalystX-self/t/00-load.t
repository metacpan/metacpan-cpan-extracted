use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
	use_ok( 'CatalystX::self' );
}

diag( "Testing CatalystX::self $CatalystX::self::VERSION, Perl $], $^X" );
