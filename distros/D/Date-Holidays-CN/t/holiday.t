#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Date::Holidays::CN' );
}

diag( "Testing Date::Holidays::CN $Date::Holidays::CN::VERSION, Perl $]" );

is( is_cn_holiday( 2006, 1, 1 ), '元旦', 'Happy new year' );
