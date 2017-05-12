#!/usr/bin/perl -w

use strict;

BEGIN   { $| = 1; print "1..66\n"; }
END     { print "not ok 1\n" unless $::XBaseloaded; }

$| = 1;

print "Load the module: use XBase\n";
use XBase;
$::XBaseloaded = 1;
print "ok 1\n";

my $dir = ( -d "t" ? "t" : "." );

$XBase::Base::DEBUG = 1;        # We want to see any problems


print "Open table $dir/ntx-char\n";
my $table = new XBase "$dir/ntx-char" or do
	{
	print XBase->errstr, "not ok 2\n";
	exit
	};
print "ok 2\n";

print "prepare_select\n";
my $cur = $table->prepare_select or print $table->errstr, 'not ';
print "ok 3\n";

print "fetch all rows and sort them\n";
my @expected;
while (my @row = $cur->fetch)
	{ push @expected, @row; }

my @sorted = sort @expected;
my $expected = join "\n", @sorted, '';

print "ok 4\n";

print "prepare_select_with_index $dir/ntx-char.ntx\n";
$cur = $table->prepare_select_with_index("$dir/ntx-char.ntx") or
	print $table->errstr, 'not ';
print "ok 5\n";

my $got = '';
while (my @row = $cur->fetch)
	{ $got .= "@row\n"; }

if ($got ne $expected)
	{ print "Expected:\n${expected}Got:\n${got}not "; }
print "ok 6\n";

my $test = 7;

my $prev = '';
for (my $i = 0; $i < @sorted; $i++)
	{
	next if $sorted[$i] eq $prev;
	$prev = $sorted[$i];
	print "find_eq($sorted[$i])\n";
	$cur->find_eq($sorted[$i]) or print "not ";
	print "ok $test\n";
	$test++;

	my $got = '';
	while (my @row = $cur->fetch)
		{ $got .= "@row\n"; }
	
	my $expected = join "\n", @sorted[$i .. $#sorted], '';

	print "compare results\n";
	if ($got ne $expected)
		{ print "Index $i, find_eq($sorted[$i])\nExpected:\n${expected}Got:\n${got}not "; }
	
	print "ok $test\n";
	$test++;
	}

