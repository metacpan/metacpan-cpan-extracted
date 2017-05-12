#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Munge' );
}

diag( "Testing Data::Munge $Data::Munge::VERSION, Perl $], $^X" );
