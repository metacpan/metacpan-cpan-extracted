#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Manager' );
}

diag( "Testing Data::Manager $Data::Manager::VERSION, Perl $], $^X" );
