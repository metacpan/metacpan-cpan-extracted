#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Password::passwdqc' ) || print "Bail out!\n";
}

diag( "Testing Data::Password::passwdqc $Data::Password::passwdqc::VERSION, Perl $], $^X" );
