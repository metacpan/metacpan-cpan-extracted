#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Devel::REPL' );
	use_ok( 'Carp::REPL' );
	use_ok( 'Devel::REPL::Plugin::Carp::REPL' );
}


diag("Carp::REPL $Carp::REPL::VERSION");
diag("Devel::REPL $Devel::REPL::VERSION");
diag("Perl $], $^X");

