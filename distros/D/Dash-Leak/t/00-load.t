#!usr/bin/env perl

use strict;
use warnings;
use lib::abs '../lib';

BEGIN {
	return if $^O eq 'MSWin32';
	require Test::NoWarnings;
	Test::NoWarnings->import;
}

BEGIN {
	require Test::More;
	my $test_count = 2;
	$test_count-- if $^O eq 'MSWin32';
	Test::More->import( tests => $test_count );
}

BEGIN {
	use_ok( 'Dash::Leak' );
}

diag( "Testing Dash::Leak $Dash::Leak::VERSION, Perl $], $^X" );
