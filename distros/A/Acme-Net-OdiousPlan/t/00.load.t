use Test::More tests => 2;

BEGIN {
use_ok( 'Acme::Net::OdiousPlan' );
}

diag( "Testing Acme::Net::OdiousPlan $Acme::Net::OdiousPlan::VERSION" );

my $str = Acme::Net::OdiousPlan->new;
ok ($str,$str);
