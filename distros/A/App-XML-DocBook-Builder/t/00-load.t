#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::XML::DocBook::Builder' );
}

diag( "Testing App::XML::DocBook::Builder $App::XML::DocBook::Builder::VERSION, Perl $], $^X" );
