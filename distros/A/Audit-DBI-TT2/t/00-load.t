#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Audit::DBI::TT2' );
}

diag( "Testing Audit::DBI::TT2 $Audit::DBI::TT2::VERSION, Perl $], $^X" );
