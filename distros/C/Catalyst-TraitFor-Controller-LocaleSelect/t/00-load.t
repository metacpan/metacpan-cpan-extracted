#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::TraitFor::Controller::LocaleSelect' );
}

diag( "Testing Catalyst::TraitFor::Controller::LocaleSelect $Catalyst::TraitFor::Controller::LocaleSelect::VERSION, Perl $], $^X" );
