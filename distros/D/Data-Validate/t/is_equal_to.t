#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_equal_to
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_equal_to);

my $t = ExtUtils::TBone->typical();

$t->begin(8);
$t->msg("testing is_equal_to...");

# integer
$t->ok(defined(is_equal_to(5, 5)), "5 == 5");
$t->ok(!defined(is_equal_to(5, 10)), "5 != 10");

# float
$t->ok(defined(is_equal_to(5.5, 5.5)), "5.5 == 5.5");
$t->ok(!defined(is_equal_to(5.5, 5.6)), "5.5 != 5.6");

# string
$t->ok(defined(is_equal_to('foo', 'foo')), "foo eq foo");
$t->ok(!defined(is_equal_to('foo', 'bar')), "foo ne bar");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_equal_to(5, 5)), "5 == 5 (object)");
$t->ok(!defined($v->is_equal_to(5, 10)), "5 != 10 (object)");

# we're done
$t->end();

