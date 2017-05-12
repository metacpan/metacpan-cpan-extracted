#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DateTime::Span::Common' );
}

diag( "Testing DateTime::Span::Common $DateTime::Span::Common::VERSION, Perl $], $^X" );
