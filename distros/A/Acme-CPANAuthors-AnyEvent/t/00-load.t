#!/usr/bin/env perl -w

use Test::More tests => 5;
use Test::NoWarnings;
use lib::abs "../lib";

BEGIN {
	use_ok('Acme::CPANAuthors::Register');
	use_ok('Acme::CPANAuthors');
	use_ok('Acme::CPANAuthors::AnyEvent');
}
ok + Acme::CPANAuthors->new('AnyEvent'), 'new';

diag( "Testing Acme::CPANAuthors::AnyEvent $Acme::CPANAuthors::AnyEvent::VERSION, Perl $], $^X" );
