#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Paginator' );
}

diag( "Testing Data::Paginator $Data::Paginator::VERSION, Perl $], $^X" );
