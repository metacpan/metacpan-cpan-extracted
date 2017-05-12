#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
	use_ok( 'App::Nopaste::Service::WerePaste' ) || print "Bail out!\n";
}

diag( "Testing App::Nopaste::Service::WerePaste $App::Nopaste::Service::WerePaste::VERSION, Perl $], $^X" );