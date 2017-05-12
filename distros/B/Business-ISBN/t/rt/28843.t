#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;

my $class = 'Business::ISBN';

use_ok( $class );

# this should not croak
my $isbn = eval { $class->new('1234567890123') };
ok( defined $isbn, "ISBN object is not defined (good)" );
isa_ok( $isbn, $class );

ok( ! $isbn->is_valid, "ISBN is not valid" );
is( $isbn->error, $isbn->INVALID_PREFIX, "Error is an invalid prefix" );

