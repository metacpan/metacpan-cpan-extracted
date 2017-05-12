#!perl -T

use strict;
use warnings;

use Test::FailWarnings;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Data::Validate::Type' );
}

diag( "Testing Data::Validate::Type $Data::Validate::Type::VERSION, Perl $], $^X" );
