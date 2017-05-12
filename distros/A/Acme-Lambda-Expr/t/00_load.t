#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
	use_ok 'Acme::Lambda::Expr';
}

diag( "Testing Acme::Lambda::Expr $Acme::Lambda::Expr::VERSION" );
