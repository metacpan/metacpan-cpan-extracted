#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::View::GD::Thumbnail' );
}

diag( "Testing Catalyst::View::GD::Thumbnail $Catalyst::View::GD::Thumbnail::VERSION, Perl $], $^X" );
