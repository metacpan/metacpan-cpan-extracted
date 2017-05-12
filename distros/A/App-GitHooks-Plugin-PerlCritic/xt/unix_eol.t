#!perl

use strict;
use warnings;

use Test::More;


# Load the test module.
eval
{
	require Test::EOL;
};
plan( skip_all => 'Test::EOL is required to check line endings.' )
	if $@;

# Check the line endings.
Test::EOL::all_perl_files_ok( { trailing_whitespace => 0 } );
