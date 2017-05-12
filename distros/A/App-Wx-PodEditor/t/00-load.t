#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Wx::PodEditor' );
}

diag( "Testing App::Wx::PodEditor $App::Wx::PodEditor::VERSION, Perl $], $^X" );
