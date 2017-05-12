#!perl 

use Test::More tests => 1;

use lib qw{ lib local/lib/perl5 };

BEGIN {
	use_ok( 'Config::Simple::Extended' );
}

diag( "Testing Config::Simple::Extended $Config::Simple::Extended::VERSION, Perl $], $^X" );
