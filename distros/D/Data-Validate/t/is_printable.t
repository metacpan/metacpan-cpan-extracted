#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_printable
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate qw(is_printable);

my $t = ExtUtils::TBone->typical();

$t->begin(8);
$t->msg("testing is_printable...");

# valid strings
$t->ok(defined(is_printable('')), "'' is valid");
$t->ok(defined(is_printable('the fat cat sat on a mat')), "'the fat cat sat on a mat' is valid");
$t->ok(defined(is_printable("foo\tbar\nbaz")), "strings with tabs and newlines are valid");
$t->ok(defined(is_printable('0')), "'0' is valid");

# invalid strings
$t->ok(!defined(is_printable("\a")), '\a is invalid');
$t->ok(!defined(is_printable("\0x0")), '\0x0 is invalid');

# as an object
my $v = Data::Validate->new();
$t->ok(defined($v->is_printable('')), "'' is valid (object)");
$t->ok(!defined($v->is_printable("\a")), '\a is invalid (object)');

# we're done
$t->end();

