#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Biblio::Thesaurus::ModRewrite' );
}

diag( "Testing Biblio::Thesaurus::ModRewrite $Biblio::Thesaurus::ModRewrite::VERSION, Perl $], $^X" );
