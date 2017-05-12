#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_odd
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_odd);

my $t = ExtUtils::TBone->typical();

$t->begin(8);
$t->msg("testing is_odd...");

# integers
$t->ok(!defined(is_odd(0)), "0 is even");
$t->ok(!defined(is_odd(2)), "2 is even");
$t->ok(defined(is_odd(1)), "1 is odd");
$t->ok(defined(is_odd(5)), "5 is odd");

# non-integers
$t->ok(!defined(is_odd(0.1)), "0.1 is not an integer");
$t->ok(!defined(is_odd('foo')), "'foo' is not an integer");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_odd(1)), "1 is odd (object)");
$t->ok(!defined($v->is_odd(0)), "0 is even (object)");

# we're done
$t->end();

