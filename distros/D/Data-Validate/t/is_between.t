#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_between
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_between);

my $t = ExtUtils::TBone->typical();

$t->begin(10);
$t->msg("testing is_between...");

# normal integer
$t->ok(defined(is_between(5, 0,10)), "5 should be between 0 and 10");

# normal float
$t->ok(defined(is_between(5.5, 0, 10)), "5.5 should be between 0 and 10");

# very long integer
$t->ok(defined(is_between('9223372036854775808', '9223372036854775807', '9223372036854775809')), "9223372036854775808 should be between 9223372036854775807 and 9223372036854775809");

# very long integer
$t->ok(!defined(is_between('9223372036854775810', '9223372036854775807', '9223372036854775809')), "9223372036854775810 is not between 9223372036854775807 and 9223372036854775809");

# out of range positive
$t->ok(!defined(is_between(500, 0,10)), "500 should not be between 0 and 10");

# out of range negative
$t->ok(!defined(is_between(-500, 0,10)), "-500 should not be between 0 and 10");

# undefined positive range
$t->ok(defined(is_between(500, 0)), "500 should be between 0 and undef");

# undefined negative range
$t->ok(defined(is_between(-500, undef, 1)), "-500 should be between undef and 1");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_between(5, 0,10)), "5 should be between 0 and 10 (object)");
$t->ok(!defined($v->is_between(500, 0,10)), "500 should not be between 0 and 10 (object)");

# we're done
$t->end();

