#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Audit::DBI::Event' );
}

diag( "Testing Audit::DBI::Event $Audit::DBI::Event::VERSION, Perl $], $^X" );
