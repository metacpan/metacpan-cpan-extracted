#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_hex
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_hex);

my $t = ExtUtils::TBone->typical();

$t->begin(9);
$t->msg("testing is_hex...");

# normal integer
$t->ok(defined(is_hex(5)), "5 should pass");

# normal integer
$t->ok(defined(is_hex(0)), "0 should pass");

# normal integer
$t->ok(defined(is_hex('a')), "a should pass");

# normal integer
$t->ok(defined(is_hex('ffffff')), "ffffff should pass");

# normal integer
$t->ok(defined(is_hex('FFFFFF')), "FFFFFF should pass");

# non-numeric
$t->ok(!defined(is_hex('hi')), "'hi' should fail");

# non-numeric
$t->ok(!defined(is_hex('1.0hi')), "'1.0hi' should fail");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_hex(5)), "5 should pass (object)");
$t->ok(!defined($v->is_hex('hi')), "'hi' should fail (object)");

# we're done
$t->end();

