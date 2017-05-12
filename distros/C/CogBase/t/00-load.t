#!perl -T

use Test::More tests => 1;

BEGIN {
        use_ok( 'CogBase' );
}

diag( "Testing CogBase $CogBase::VERSION, Perl $], $^X" );
