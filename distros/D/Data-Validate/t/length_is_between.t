#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::length_is_between
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(length_is_between);

my $t = ExtUtils::TBone->typical();

$t->begin(10);
$t->msg("testing length_is_between...");

# valid strings
$t->ok(defined(length_is_between('', 0, 1)), "'' is between 0 and 1");
$t->ok(defined(length_is_between('foo', 0, 3)), "'foo' is between 0 and 3");
$t->ok(defined(length_is_between('foo', 3, 10)), "'foo' is between 3 and 10");
$t->ok(defined(length_is_between('foobar', 3, undef)), "'foobar'is between 3 and infinity");
$t->ok(defined(length_is_between('foobar', undef, 10)), "'foobar'is between infinity and 10");

# invalid strings
$t->ok(!defined(length_is_between('', 1, 10)), "'' is not between 1 and 10");
$t->ok(!defined(length_is_between('foo', 4, 10)), "'foo'is not between 4 and 10");
$t->ok(!defined(length_is_between('foo', 0, 1)), "'foo'is not between 0 and 1");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->length_is_between('', 0, 1)), "'' is between 0 and 1 (object)");
$t->ok(!defined($v->length_is_between('', 1, 10)), "'' is not between 1 and 10 (object)");

# we're done
$t->end();

