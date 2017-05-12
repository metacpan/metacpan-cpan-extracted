#!/usr/local/bin/perl

# Unicode-related functionality
# $Id: Read-unicode1.t,v 1.1 2006/08/25 14:26:34 mattheww Exp $

use strict;
use Getopt::Std;
use lib("./lib","../lib");
use Config::Wrest;
use Test::Assertions('test');
use Log::Trace;
use Cwd;

use vars qw($opt_t $opt_T);

getopts('tT');
if($opt_t) {
	import Log::Trace qw(print);
}
if($opt_T) {
	deep_import Log::Trace qw(print);
}

BEGIN {
	if ($] && $] < 5.006001) {
		print "1..1\n";
		print "ok 1 (Skipping all - perl version is $] which is too low for these unicode-related tests)\n";
		exit(0);
	}
}

#########################################################
#
# Note: 
# Some of these tests are known to fail on perl 5.6.1
# This is how it should behave because of various known
# issues with the 5.6 unicode implementation. I think
# that the main issue is the way that regexps don't
# create polymorphic opcodes, and hence when a string
# goes through a regexp it goes from wide-chars to bytes.
# The config parsing is done with regexes so this can be
# an issue (esp. when the config data is a string
# containing wide-chars, rather than a file continaing
# escape sequences.
#
# Please see the perlunicode page for perl 5.6.1 for
# more information
#
#########################################################

my $is_5_point_6 = 0;

if ($^V && $^V ge chr(5).chr(8).chr(0)) {
	binmode(STDOUT, ':utf8');
} else {
	$is_5_point_6 = 1;
}
plan tests => 5;

chdir 't' if -d 't';

my $cr = new Config::Wrest( Escapes => 1, UseQuotes => 1 );

#########################################################
# from a string containing unicode data
my $vars = $cr->deserialize(
	"midorder 'copy\x{a9}right'\n".
	"highorder 'c\x{153}ur'"
);
ASSERT(ref($cr), 'new object created from unicode string');
DUMP('Variables', $vars);

my $str = $vars->{'midorder'};
my $l = length($str);
if ($is_5_point_6) {
	ASSERT(1, "skipped - String contents test");
	ASSERT(1, "skipped - length test");
} else {
	ASSERT($str eq "copy\x{a9}right", "String is <$str>");
	ASSERT(($l == 10), "length is $l");
}

$str = $vars->{'highorder'};
$l = length($str);
ASSERT($str eq "c\x{153}ur", "String is <$str>");
if ($is_5_point_6) {
	ASSERT(1, "skipped - length test");
} else {
	ASSERT(($l == 4), "length is $l");
}
