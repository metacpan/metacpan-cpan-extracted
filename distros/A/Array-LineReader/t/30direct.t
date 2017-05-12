#!/usr/bin/perl -w
use strict;
use lib "..";
use Test;
use Array::LineReader;
$| = 1;
BEGIN{
	open(TEST,$0) or die "Big problem reading testfile \"$0\"!\n";
	plan tests => scalar(grep{/^\s*ok\(/} <TEST>);
	close TEST;
}

use vars qw( $TEST_CLASS $TEST_FILE );
$TEST_CLASS = 'Array::LineReader';	# the modul`s name
$TEST_FILE = $0;	# The file to be used as testfile

use vars qw( @lines @testLines $testCount @testOffsets $testOffsetCount );

### Read the lines of the testfile for further comparison ###
open(THIS,$TEST_FILE) || die "Can't read this testfile!\n";
binmode THIS;
@testLines = <THIS>;
close THIS;

$testCount = scalar(@testLines);

### Calculate the offsets for further comparison ###
for (my $offs = 0, my $count=0; $count < scalar(@testLines); $count++){
	$testOffsets[$count] = $offs;
	$offs += length($testLines[$count]);
}
$testOffsetCount = scalar(@testOffsets);


### access content through the elements of our array
ok(tie(@lines, $TEST_CLASS, $TEST_FILE));
ok(scalar(@testLines));
ok($testCount);	# positive number of lines to compare
ok(@lines);	# positive number of lines that are tied
ok(scalar(@lines),$testCount);	# equal number of lines
untie @lines;

### Test if the lines contain equal contents ###
ok(tie(@lines, $TEST_CLASS, $TEST_FILE));
ok(join("",@lines),join("",@testLines));	# equal content;
untie @lines;

### Test if the reversed lines contain equal contents ###
ok(tie(@lines, $TEST_CLASS, $TEST_FILE));
ok(join("",reverse @lines),join("",reverse @testLines));	# equal reversed content;
untie @lines;

### Create random numbers to be used in a test for random access ###
my @rand = map{int(rand($testCount))} @testLines;	# random numbers
ok(scalar(@rand),$testCount);	# enough random numbers?

### Test if randomly choosen lines contain equal content ###
ok(tie(@lines, $TEST_CLASS, $TEST_FILE));
ok(join("",map{$lines[$_]}@rand),join("",map{$testLines[$_]}@rand));
untie @lines; 

### This is the last line of this testprogram. Don`t add anything behind it ###
