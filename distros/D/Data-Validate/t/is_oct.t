#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_oct
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_oct);

my $t = ExtUtils::TBone->typical();

$t->begin(7);
$t->msg("testing is_oct...");

# normal integer
$t->ok(defined(is_oct(5)), "5 should pass");

# normal integer
$t->ok(defined(is_oct(0)), "0 should pass");

# normal integer
$t->ok(defined(is_oct('777777')), "777777 should pass");

# non-numeric
$t->ok(!defined(is_oct('hi')), "'hi' should fail");

# non-numeric
$t->ok(!defined(is_oct('8')), "'8' should fail");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_oct(5)), "5 should pass (object)");
$t->ok(!defined($v->is_oct('hi')), "'hi' should fail (object)");

# we're done
$t->end();

