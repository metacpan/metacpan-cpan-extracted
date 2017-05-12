#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_numeric
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_numeric);

my $t = ExtUtils::TBone->typical();

$t->begin(8);
$t->msg("testing is_numeric...");

# normal integer
$t->ok(defined(is_numeric(5)), "5 should pass");

# normal integer
$t->ok(defined(is_numeric(0)), "0 should pass");

# big integer
$t->ok(defined(is_numeric(-9223372036854775808)), "-9223372036854775808 should pass");

# float
$t->ok(defined(is_numeric(1.01)), "1.01 should pass");

# non-numeric
$t->ok(!defined(is_numeric('hi')), "'hi' should fail");

# non-numeric
$t->ok(!defined(is_numeric('1.0hi')), "'1.0hi' should fail");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_numeric(5)), "5 should pass (object)");
$t->ok(!defined($v->is_numeric('hi')), "'hi' should fail (object)");

# we're done
$t->end();

