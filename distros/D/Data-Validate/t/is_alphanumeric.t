#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_alphanumeric
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_alphanumeric);

my $t = ExtUtils::TBone->typical();

$t->begin(10);
$t->msg("testing is_alphanumeric...");

# valid strings
$t->ok(defined(is_alphanumeric('')), "'' is valid");
$t->ok(defined(is_alphanumeric('foo')), "'foo' is valid");
$t->ok(defined(is_alphanumeric('FOO')), "'FOO' is valid");
$t->ok(defined(is_alphanumeric('0')), "'0' is valid");

# invalid strings
$t->ok(!defined(is_alphanumeric('&')), "'&' is invalid");
$t->ok(!defined(is_alphanumeric("\t")), '"\t" is invalid');
$t->ok(!defined(is_alphanumeric("\n")), '"\n" is invalid');
$t->ok(!defined(is_alphanumeric('hello world')), "'hello world' is invalid");

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_alphanumeric('')), "'' is valid (object)");
$t->ok(!defined($v->is_alphanumeric('&')), "'&' is invalid (object)");

# we're done
$t->end();

