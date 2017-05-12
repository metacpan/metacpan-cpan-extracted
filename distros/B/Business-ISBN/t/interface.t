#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

my $class = 'Business::ISBN';

my @methods = qw( as_isbn10 as_isbn13 _set_prefix 
	_set_type _hyphen_positions );

eval { Business::ISBN->_hyphen_positions };

foreach my $method ( @methods )
	{
	my $result = eval { no strict 'refs'; &{"${class}::$method"} };
	ok( defined $@, "Unimplemented method [$method] croaks" );
	}