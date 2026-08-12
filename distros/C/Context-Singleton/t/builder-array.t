#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use require::relative q (test-helper.pl);

plan tests => 3;

contrive q (dependency)
	=> value    => q (with-dependency)
	;

contrive q (with-array-dependencies)
	=> dep      => [qw[ dependency ]]
	=> as       => sub { [ @_ ] }
	;

contrive q (without-dep)
	=> as       => sub { q (without-dependencies) }
	;

it q (should pass resolved dependencies as positional arguments)
	=> got      => sub { deduce q (with-array-dependencies) }
	=> expect   => [ q (with-dependency) ]
	;

it q (should not need empty arrayref to deduce subroutine without dependencies)
	=> got      => sub { deduce q (without-dep) }
	=> expect   => q (without-dependencies)
	;

had_no_warnings;

done_testing;
