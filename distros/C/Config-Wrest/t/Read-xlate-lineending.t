#!/usr/local/bin/perl

# The documentation says that we can translate unusual line endings
# to \n - this test verifies that
# $Id: Read-xlate-lineending.t,v 1.4 2005/10/04 16:17:27 piersk Exp $

use strict;
use Getopt::Std;
use lib("./lib","../lib");
use Config::Wrest;
use Test::Assertions('test');
use Log::Trace;

use vars qw($opt_t $opt_T);

getopts('tT');
if($opt_t) {
	import Log::Trace qw(print);
}
if($opt_T) {
	import Log::Trace qw(print), { Deep => 1 };
}

plan tests;

my $cr = new Config::Wrest( WriteWithHeader => 0 );

# Test NEL as used on some mainframes, e.g. OS/390
my $str = "Colour red\x85Size 16\x85"; # pretend we read this from a file which came from an OS/390 machine
$str =~ s/\x85/\n/g;	# alter it to local newlines (whatever they happen to be)
my $vardata = $cr->deserialize($str);
DUMP('Variables', $vardata);
ASSERT($vardata->{'Colour'} eq 'red', "Read correct colour after translation: $vardata->{'Colour'}");
ASSERT($vardata->{'Size'} eq '16', "Read correct size after translation: $vardata->{'Size'}");

# Test VT-CR-FF
$str = "Colour blue\x0B\x0D\x0C# comment\x0B\x0D\x0CSize 10\x0B\x0D\x0C"; # pretend we read this from a file which came from an unusual OS
$str =~ s/\x0B\x0D\x0C/\n/g;	# alter it to local newlines (whatever they happen to be)
$vardata = $cr->deserialize($str);
DUMP('Variables', $vardata);
ASSERT($vardata->{'Colour'} eq 'blue', "Read correct colour after translation: $vardata->{'Colour'}");
ASSERT($vardata->{'Size'} eq '10', "Read correct size after translation: $vardata->{'Size'}");

# Check we get \n as the line ending
$str = $cr->serialise({ 'red' => [ 'a', 'b' ] });
TRACE(">>>$str<<<");
$str =~ s/\n/\x0B\x0D\x0C/g;
ASSERT(($str eq "[red]\x0B\x0D\x0C\t'a'\x0B\x0D\x0C\t'b'\x0B\x0D\x0C[/red]\x0B\x0D\x0C"), "serialized and line-endings changed OK");
