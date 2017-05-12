#!perl -T

use 5.008001;

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::Data::Inheritable::Translucent' );
}

diag( "Testing Class::Data::Inheritable::Translucent $Class::Data::Inheritable::Translucent::VERSION, Perl $], $^X" );
