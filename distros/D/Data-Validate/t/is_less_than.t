#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_less_than
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_less_than);

my $t = ExtUtils::TBone->typical();

$t->begin(6);
$t->msg("testing is_less_than...");

# normal integer
$t->ok(defined(is_less_than(5, 10)), "5 is less than 10");

# normal float
$t->ok(defined(is_less_than(5.5, 10)), "5.5 is less than 10");

# above bound
$t->ok(!defined(is_less_than(5, 1)), "5 is greater than 1");

# non-numeric
$t->ok(!defined(is_less_than('foo', 1)), "'foo' is non-numeric");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_less_than(5, 10)), "5 is less than 10 (object)");
$t->ok(!defined($v->is_less_than(5, 1)), "5 is greater than 1 (object)");

# we're done
$t->end();

