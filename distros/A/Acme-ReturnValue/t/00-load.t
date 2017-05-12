#!/opt/perl5.10/bin/perl
# generated with /opt/perl5.10/bin/generate_00-load_t.pl
use Test::More tests => 2;


BEGIN {
	use_ok( 'Acme::ReturnValue' );
}

diag( "Testing Acme::ReturnValue Acme::ReturnValue->VERSION, Perl $], $^X" );

use_ok( 'Acme::ReturnValue::MakeSite' );
