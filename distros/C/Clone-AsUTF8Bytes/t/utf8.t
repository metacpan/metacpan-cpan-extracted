#!/usr/bin/env perl

use strict;
use Test::More tests => 2;
use Clone::AsUTF8Bytes qw(clone_as_utf8_bytes);

my $leon     = "L\x{e9}on";       # probably not a utf8 flagged string
my $moose    = "M\x{f8}\x{f8}se"; # probably not a utf8 flagged string
my $snowman  = "\x{2603}";        # a utf8 flagged string 
my $thumbsup = "\x{1F44D}";       # a utf8 flagged string 

my $hash = {
	$snowman => $thumbsup,
	$leon => $moose,
	array => [1,2,3,undef],
};

my $cloned = clone_as_utf8_bytes($hash);

is_deeply $cloned, {
	"\x{E2}\x{98}\x{83}" => "\x{F0}\x{9F}\x{91}\x{8D}",
	"L\x{C3}\x{A9}on" => "M\x{C3}\x{B8}\x{C3}\x{B8}se",
	array => [1,2,3,undef],
};

$hash->{foo} = "extra";

is_deeply $cloned, {
	"\x{E2}\x{98}\x{83}" => "\x{F0}\x{9F}\x{91}\x{8D}",
	"L\x{C3}\x{A9}on" => "M\x{C3}\x{B8}\x{C3}\x{B8}se",
	array => [1,2,3,undef],
};

