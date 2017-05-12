#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'PrimaX::InputHistory' )
		or BAIL_OUT('Unable to load PrimaX::InputHistory!');
}

use App::Prima::REPL;
diag( "Testing PrimaX::InputHistory from App::Prima::REPL v $App::Prima::REPL::VERSION, Perl $], $^X" );