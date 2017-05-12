#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Audit::DBI' );
}

diag( "Testing Audit::DBI $Audit::DBI::VERSION, Perl $], $^X" );
