#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use FindBin ();
use Class::Superclasses;

my $testfile = $FindBin::Bin . '/test_expression_isa.pm';
my $parser   = Class::Superclasses->new( $testfile );

my @expected     = qw'expression isa';
my @superclasses = $parser->superclasses;
my $ref          = $parser->superclasses;

is_deeply \@superclasses, \@expected;
is_deeply $ref, \@expected;

done_testing();
