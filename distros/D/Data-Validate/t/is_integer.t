#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_integer
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_integer);

my $t = ExtUtils::TBone->typical();

$t->begin(8);
$t->msg("testing is_integer...");

# normal integer
$t->ok(defined(is_integer(5)), "5 should pass");

# normal integer
$t->ok(defined(is_integer(0)), "0 should pass");

# long integer
$t->ok(defined(is_integer(20041222113730)), "20041222113730 should pass");

# very long integer
$t->ok(defined(is_integer('-9223372036854775808')), "-9223372036854775808 should pass");

# float
$t->ok(!defined(is_integer(1.01)), "1.01 should fail");

# non-numeric
$t->ok(!defined(is_integer('hi')), "'hi' should fail");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_integer(0)), "0 should pass (object)");
$t->ok(!defined($v->is_integer('hi')), "'hi' should fail (object)");

# we're done
$t->end();

