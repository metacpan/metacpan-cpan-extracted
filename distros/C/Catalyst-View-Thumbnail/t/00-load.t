#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::View::Thumbnail' );
}

diag( "Testing Catalyst::View::Thumbnail $Catalyst::View::Thumbnail::VERSION, Perl $], $^X" );
