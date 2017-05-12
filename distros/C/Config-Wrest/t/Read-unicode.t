#!/usr/local/bin/perl

# Unicode-related functionality
# $Id: Read-unicode.t,v 1.2 2006/08/25 14:26:34 mattheww Exp $

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

eval "use HTML::Template;";
if ($@) {
	print "1..1\n";
	print "ok 1 (Skipping all - HTML::Template required for testing this templated configuration)\n";
	exit (0);
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
	plan tests => 53;
} else {
	$is_5_point_6 = 1;
	plan tests => 26;
}

chdir 't' if -d 't';

my $cr = new Config::Wrest( TemplateBackend => "HTML::Template", TemplateOptions => { die_on_bad_params => 0 }, Escapes => 1, UseQuotes => 1 );

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

#########################################################
# from a file with unicode escapes - not /read/ as actual utf8 though
$cr = new Config::Wrest( TemplateBackend => "HTML::Template", TemplateOptions => { die_on_bad_params => 0 }, Escapes => 1, UseQuotes => 1, Subs => 1 );
$vars = $cr->parse_file("./data/Reader_unicode.cfg");
ASSERT(ref($cr), 'new object created from file');

my $d = $vars->{"unicode_tests"};
DUMP("test data block", $d);
ASSERT(ref($d), "some data returned");

$str = $d->{"loworder"};
$l = length($str);
ASSERT( $str eq "C BBC" , "String is <$str>");
ASSERT(($l == 5), "length is $l");

$str = $d->{"midorder1"};
$l = length($str);
ASSERT( $str eq "\xA9 BBC" , "String is <$str>");
ASSERT(($l == 5), "length is $l");

$str = $d->{"midorder2"};
$l = length($str);
ASSERT( $str eq "\x{A9} BBC" , "String is <$str>");
ASSERT(($l == 5), "length is $l");

$str = $d->{"highorder"};
$l = length($str);
ASSERT( $str eq "C\x{153}ur et amour" , "String is <$str>");
ASSERT(($l == 13), "length is $l");

$str = $d->{"list"}[0];
$l = length($str);
ASSERT( $str eq "foo\xA9bbc" , "String is <$str>");
ASSERT(($l == 7), "length is $l");

$str = $d->{"list"}[1];
$l = length($str);
ASSERT( $str eq "foo\xA9bbc" , "String is <$str>");
ASSERT(($l == 7), "length is $l");

$str = $d->{"list"}[2];
$l = length($str);
ASSERT( $str eq "C\x{153}ur" , "String is <$str>");
ASSERT(($l == 4), "length is $l");

$str = $d->{"list"}[3];
$l = length($str);
ASSERT( $str eq "C\x{153}ur" , "String is <$str>");
ASSERT(($l == 4), "length is $l");

$str = $d->{"list"}[4];
$l = length($str);
ASSERT( $str eq "C\x{153}ur" , "String is <$str>");
if ($is_5_point_6) {
	ASSERT(1, "skipped - length test");
} else {
	ASSERT(($l == 4), "length is $l");
}


#########################################################
# brief test of externally-read files
# irrelevant, and indeed error-causing, for perl 5.6
if ($is_5_point_6) {
	ASSERT(1, "skipped - remaining tests are not relevant to perl 5.6");
	exit(0);
}



$str = _read_disc("./data/Reader_unicode.cfg", "utf8");
$cr = new Config::Wrest( TemplateBackend => "HTML::Template", TemplateOptions => { die_on_bad_params => 0 }, Escapes => 1, UseQuotes => 1, Subs => 1 );
$vars = $cr->deserialize($str);

$d = $vars->{"unicode_tests"};
DUMP("file read - test data block", $d);

$str = $d->{"highorder"};
$l = length($str);
ASSERT( $str eq "C\x{153}ur et amour" , "String is <$str>");
ASSERT(($l == 13), "length is $l");



$str = _read_disc("./data/Reader_unicode2.cfg", "utf8");
$cr = new Config::Wrest( TemplateBackend => "HTML::Template", TemplateOptions => { die_on_bad_params => 0 }, Escapes => 1, UseQuotes => 1, Subs => 1 );
$vars = $cr->deserialize($str);
$d = $vars->{"io_tests"};
DUMP("file read - test data block", $d);

$str = $d->{"gar\x{e7}on"};
ASSERT( ref($str), "Data against unicode key");

$str = $d->{"gar\x{e7}on"}{"\x{de}e_old_tea_shoppe"}[0];
$l = length($str);
ASSERT( $str eq "\x{b1}23volts", "String is <$str>");
ASSERT(($l == 8), "length is $l");

$str = $d->{"gar\x{e7}on"}{"\x{de}e_old_tea_shoppe"}[1];
$l = length($str);
ASSERT( $str eq "\x{201c}Hello!\x{201d}", "String is <$str>");
ASSERT(($l == 8), "length is $l");

$str = $d->{"gar\x{e7}on"}{"\x{de}e_old_tea_shoppe"}[2];
$l = length($str);
ASSERT( $str eq "\x{201c}Hello!\x{201d} said Kate", "String is <$str>");
ASSERT(($l == 18), "length is $l");

$str = $d->{"bobby"}[0];
$l = length($str);
ASSERT( $str eq "\x{b1}23volts", "String via reference is <$str>");
ASSERT(($l == 8), "length is $l");

$str = $d->{"bobby"}[1];
$l = length($str);
ASSERT( $str eq "\x{201c}Hello!\x{201d}", "String via reference is <$str>");
ASSERT(($l == 8), "length is $l");

$str = $d->{"bobby"}[2];
$l = length($str);
ASSERT( $str eq "\x{201c}Hello!\x{201d} said Kate", "String via reference is <$str>");
ASSERT(($l == 18), "length is $l");

$str = $d->{"plainname"};
$l = length($str);
ASSERT( $str eq "cre\x{e9}me", "String is <$str>");
ASSERT(($l == 6), "length is $l");

$str = $d->{"\x{e9}lan"};
$l = length($str);
ASSERT( $str eq "brulee", "String is <$str>");
ASSERT(($l == 6), "length is $l");

$str = $d->{"inserted"};
$l = length($str);
ASSERT( $str eq "soup\x{e7}on", "String is <$str>");
ASSERT(($l == 7), "length is $l");



### We will assume that other input disciplines have been suitably well-tested
### and that they work, but we'll do a quick test here just to check

$str = _read_disc("./data/Reader_unicode3.cfg", "encoding(iso-8859-7)");
$cr = new Config::Wrest( TemplateBackend => "HTML::Template", TemplateOptions => { die_on_bad_params => 0 }, Escapes => 1, UseQuotes => 1, Subs => 1 );
$vars = $cr->deserialize($str);
$d = $vars;
DUMP("file read - test data block", $d);

$str = $d->{'plainname'};
$l = length($str);
ASSERT( $str eq "delta", "String is <$str>");
ASSERT(($l == 5), "length is $l");

$str = $d->{"\x{394}\x{3b5}\x{3bb}\x{3c4}\x{3b1}"};
$l = length($str);
ASSERT( $str eq "Force", "String is <$str>");
ASSERT(($l == 5), "length is $l");

$str = $d->{"\x{3a3}umma"};
ASSERT(ref($str), "Data against unicode key");

$str = $d->{"\x{3a3}umma"}[0];
$l = length($str);
ASSERT( $str eq "\x{391}\x{3b8}ens", "String is <$str>");
ASSERT(($l == 5), "length is $l");



#########################################################

sub _read_disc {
	my ($fn, $disc) = @_;

	open(IN, "<:$disc", $fn) || die "Cannot open file $fn with discipline $disc: $!";
	my $filecontent = '';
	while (<IN>) { $filecontent .= $_; }
	close(IN);
	return $filecontent;
}
