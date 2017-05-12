#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_even
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_even);

my $t = ExtUtils::TBone->typical();

$t->begin(8);
$t->msg("testing is_even...");

# integers
$t->ok(defined(is_even(0)), "0 is even");
$t->ok(defined(is_even(2)), "2 is even");
$t->ok(!defined(is_even(1)), "1 is odd");
$t->ok(!defined(is_even(5)), "5 is odd");

# non-integers
$t->ok(!defined(is_even(0.1)), "0.1 is not an integer");
$t->ok(!defined(is_even('foo')), "'foo' is not an integer");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_even(0)), "0 is even (object)");
$t->ok(!defined($v->is_even(1)), "1 is odd (object)");

# we're done
$t->end();

