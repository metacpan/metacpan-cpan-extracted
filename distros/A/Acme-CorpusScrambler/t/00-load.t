#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::CorpusScrambler' );
}

diag( "Testing Acme::CorpusScrambler $Acme::CorpusScrambler::VERSION, Perl $], $^X" );
