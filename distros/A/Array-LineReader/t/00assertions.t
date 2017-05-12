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


### Test if module croaks with missing filename
eval{ tie(@lines, $TEST_CLASS) };
ok($@);
untie @lines;

### Test if module simulates an empty array with not existing filename
ok(tie(@lines, $TEST_CLASS, "_".$TEST_FILE."_"));
ok(scalar(@lines),0);	# should be empty
ok(scalar(map{1}@lines),0); # and has really no lines
untie @lines;

### Test if module croaks with odd parameters
eval{ tie(@lines, $TEST_CLASS, $TEST_FILE, 1,2,3) };
ok($@);
untie @lines; 

### Test if module returns undef with too big index ###
eval{ tie(@lines, $TEST_CLASS, $TEST_FILE) };
ok(!$@);
ok(@lines);	# there are some lines
ok($lines[scalar(@lines)],undef); # but not behind the last one
ok($lines[scalar(@lines)+10],undef); # but not behind the last one
untie @lines;

### Test if module croaks on changing values ###
eval{ tie(@lines, $TEST_CLASS, $TEST_FILE) };
ok(!$@);	# no messages is ok

eval{ shift @lines };	# should shorten the array
ok($@);	# but croakes
ok(@lines,@testLines);	# and all is in place yet
eval{ 1==1 };	# cleans up "$@"

eval{ unshift @lines, " " };	# should grow up the array
ok($@);	# but croakes
ok(@lines,@testLines);	# and all is in place yet
eval{ 1==1 };	# cleans up "$@"

eval{ pop @lines};	# should shorten the array
ok($@);	# but croakes
ok(@lines,@testLines);	# and all is in place yet
eval{ 1==1 };	# cleans up "$@"

eval{ push @lines," "};	# should grow up the array
ok($@);	# but croakes
ok(@lines,@testLines);	# and all is in place yet
eval{ 1==1 };	# cleans up "$@"

eval{ $lines[0] = undef};	# should change the array
ok($@);	# but croakes
untie @lines;

eval{ tie(@lines, $TEST_CLASS, $TEST_FILE) };
ok(!$@);
ok( exists $lines[0]);	# should return true
ok(!exists $lines[scalar(@lines)+1000]);	# should return false
ok(!defined $lines[scalar(@lines)+1000]);	# should return false
ok( defined $lines[0]);	# should return true


### This is the last line of this testprogram. Don`t add anything behind it ###
