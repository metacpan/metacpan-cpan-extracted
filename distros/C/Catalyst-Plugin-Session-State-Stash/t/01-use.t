#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::Session::State::Stash' );
}

diag( "Testing Catalyst::Plugin::Session::State::Stash $Catalyst::Plugin::Session::State::Stash::VERSION, Perl $], $^X" );
