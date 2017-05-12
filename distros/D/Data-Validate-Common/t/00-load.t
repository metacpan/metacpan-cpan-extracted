#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Validate::Common' ) || print "Bail out!\n";
}

diag( "Testing Data::Validate::Common $Data::Validate::Common::VERSION, Perl $], $^X" );
