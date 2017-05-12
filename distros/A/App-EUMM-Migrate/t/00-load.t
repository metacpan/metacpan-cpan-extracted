#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::EUMM::Migrate' );
}

diag( "Testing App::EUMM::Migrate $App::EUMM::Migrate::VERSION, Perl $], $^X" );
