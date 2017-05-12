#!/usr/local/bin/perl

# Test private routines
# $Id: Config-Wrest-internals.t,v 1.3 2005/09/23 10:30:26 piersk Exp $

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

chdir 't' if -d 't';

my ($rv);
my ($is54, $is56, $is58) = (0, 0, 0);

if ($] && $] < 5.006001) {
	$is54 = 1;
} elsif ($^V && $^V ge chr(5).chr(8).chr(0)) {
	$is58 = 1;
	binmode(STDOUT, ':utf8');
} else {
	$is56 = 1;
}

plan tests;

TRACE("Perl version detection: 5.4 <$is54>, 5.6 <$is56>, 5.8 <$is58>");

######################################################################

$rv = Config::Wrest::_unescape('0');
ASSERT($rv eq "\x00", "unescaping");

$rv = Config::Wrest::_unescape('a');
ASSERT($rv eq "\x0A", "unescaping");

$rv = Config::Wrest::_unescape('41');
ASSERT($rv eq 'A', "unescaping");

$rv = Config::Wrest::_unescape('a9');
ASSERT($rv eq "\xA9", "unescaping");

$rv = Config::Wrest::_unescape('Ff');
ASSERT($rv eq "\xFF", "unescaping");

$rv = Config::Wrest::_unescape('153');
ASSERT(($is54 ? ($rv eq "S"):($rv eq "\x{153}")), "unescaping");	# perl 5.4 takes the low byte only

$rv = Config::Wrest::_unescape('201C');
ASSERT(($is54 ? ($rv eq "\x1C"):($rv eq "\x{201C}")), "unescaping");	# perl 5.4 takes the low byte only

######################################################################

$rv = Config::Wrest::_escape(undef());
ASSERT(!defined($rv), "escaping <undefined>");

$rv = Config::Wrest::_escape('');
ASSERT(defined($rv), "escaping <defined>");
ASSERT($rv eq '', "escaping <$rv>");

$rv = Config::Wrest::_escape("a\x00b");
ASSERT($rv eq 'a%00b', "escaping <$rv>");

$rv = Config::Wrest::_escape("a");
ASSERT($rv eq 'a', "escaping <$rv>");

$rv = Config::Wrest::_escape("a b");
ASSERT($rv eq 'a%20b', "escaping <$rv>");

$rv = Config::Wrest::_escape("\xa9");
ASSERT($rv eq '%A9', "escaping <$rv>");

$rv = Config::Wrest::_escape("a!\@}\xa9b");
ASSERT($rv eq 'a%21%40%7D%A9b', "escaping <$rv>");

$rv = Config::Wrest::_escape("\x{153}");
ASSERT(($is54 ? ($rv eq '%00%7B153%7D'):($rv eq '%{153}')), "escaping <$rv>");

$rv = Config::Wrest::_escape("\x{201c}");
ASSERT(($is54 ? ($rv eq '%00%7B201c%7D'):($rv eq '%{201C}')), "escaping <$rv>");

$rv = Config::Wrest::_escape("a\x{153}b");
ASSERT(($is54 ? ($rv eq 'a%00%7B153%7Db'):($rv eq 'a%{153}b')), "escaping <$rv>");

$rv = Config::Wrest::_escape("a\x{201c}b");
ASSERT(($is54 ? ($rv eq 'a%00%7B201c%7Db'):($rv eq 'a%{201C}b')), "escaping <$rv>");

$rv = Config::Wrest::_escape("\xA9\x{153}");
ASSERT(($is54 ? ($rv eq '%A9%00%7B153%7D'):($rv eq '%A9%{153}')), "escaping <$rv>");

$rv = Config::Wrest::_escape("\xA9\x{201c}");
ASSERT(($is54 ? ($rv eq '%A9%00%7B201c%7D'):($rv eq '%A9%{201C}')), "escaping <$rv>");

$rv = Config::Wrest::_escape("a\xA9\x{153}b");
ASSERT(($is54 ? ($rv eq 'a%A9%00%7B153%7Db'):($rv eq 'a%A9%{153}b')), "escaping <$rv>");

$rv = Config::Wrest::_escape("a\xA9\x{201c}b");
ASSERT(($is54 ? ($rv eq 'a%A9%00%7B201c%7Db'):($rv eq 'a%A9%{201C}b')), "escaping <$rv>");

######################################################################

$rv = Config::Wrest::_unique_id();
ASSERT( scalar($rv =~ m/^\d+$/), "ID generator");

######################################################################

eval {
	local $^W = 0;
	$rv = Config::Wrest::_ok_token();
};
chomp($@);
ASSERT( $@, "ok token trapped error: $@");

eval {
	$rv = Config::Wrest::_ok_token('');
};
chomp($@);
ASSERT( $@, "ok token trapped error: $@");

eval {
	$rv = Config::Wrest::_ok_token('*');
};
chomp($@);
ASSERT( $@, "ok token trapped error: $@");

eval {
	$rv = Config::Wrest::_ok_token("zo\xEB");
};
chomp($@);
ASSERT( $@, "ok token trapped error: $@");

eval {
	$rv = Config::Wrest::_ok_token( $is54 ? "BAD BAD" : "puct\x{201C}uation");
};
chomp($@);
ASSERT( $@, "ok token trapped error: $@");

Config::Wrest::_ok_token("a");
ASSERT( 1, "ok token");

Config::Wrest::_ok_token("long_long");
ASSERT( 1, "ok token");

Config::Wrest::_ok_token("long-bar.jpg");
ASSERT( 1, "ok token");

Config::Wrest::_ok_token("...boo");
ASSERT( 1, "ok token");

######################################################################

$rv = Config::Wrest::_str2array(\"Dosline1\x0D\x0ADosline2\x0D\x0A");
DUMP($rv);
ASSERT(_ARRAY_EQUAL($rv, ['Dosline1', 'Dosline2']), "string to array on DOS line endings");

$rv = Config::Wrest::_str2array(\"foo\rbar\r");
DUMP($rv);
ASSERT(_ARRAY_EQUAL($rv, ['foo', 'bar']), "string to array on \\r line endings");

$rv = Config::Wrest::_str2array(\"foo\nbar\n");
DUMP($rv);
ASSERT(_ARRAY_EQUAL($rv, ['foo', 'bar']), "string to array on \\n line endings");

$rv = Config::Wrest::_str2array(\"foo\x85bar\x85");
DUMP($rv);
ASSERT(_ARRAY_EQUAL($rv, ["foo\x85bar\x85"]), "string to array on \\x85 line endings");

######################################################################
# For testing under 5.004, we don't have Test::More installed
sub _ARRAY_EQUAL {
	my ($v1, $v2) = @_;
	return 0 if (@$v1 != @$v2);
	for my $i (0..$#$v1) {
		return 0 if ($v1->[$i] ne $v2->[$i]);
	}
	return 1;
}
