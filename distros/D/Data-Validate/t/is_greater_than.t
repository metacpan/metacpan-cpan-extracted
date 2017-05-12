#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_greater_than
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_greater_than);

my $t = ExtUtils::TBone->typical();

$t->begin(6);
$t->msg("testing is_greater_than...");

# normal integer
$t->ok(defined(is_greater_than(5, 1)), "5 is greater than 1");

# normal float
$t->ok(defined(is_greater_than(5.5, 1)), "5.5 is greater than 1");

# below bound
$t->ok(!defined(is_greater_than(5, 10)), "5 is less than 10");

# non-numeric
$t->ok(!defined(is_greater_than('foo', 1)), "'foo' is non-numeric");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_greater_than(5, 1)), "5 is greater than 1 (object)");
$t->ok(!defined($v->is_greater_than(5, 10)), "5 is less than 10 (object)");

# we're done
$t->end();

