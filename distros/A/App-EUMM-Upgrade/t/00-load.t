#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::EUMM::Upgrade' );
}

diag( "Testing App::EUMM::Upgrade $App::EUMM::Upgrade::VERSION, Perl $], $^X" );
