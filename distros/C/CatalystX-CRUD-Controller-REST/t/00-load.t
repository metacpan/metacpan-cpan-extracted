#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CatalystX::CRUD::Controller::REST' );
}

diag( "Testing CatalystX::CRUD::Controller::REST $CatalystX::CRUD::Controller::REST::VERSION, Perl $], $^X" );
