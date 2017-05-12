#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use Data::ParseBinary;
#use Test::More tests => 177;
#use Test::More qw(no_plan);
use Test::More;

eval { require Encode; };
if ($@) {
    plan skip_all => 'This suit needs Encode';
} else {
    plan tests => 38;
}

$| = 1;

my ($ch, $oc, $s);

$s = Char("c", "utf8");

$ch = "a";
$oc = "a";
ok( $s->build($ch) eq $oc, "Char utf8: Build: Simple");
ok( $s->parse($oc) eq $ch, "Char utf8: Parse: Simple");

$ch = "\x{1abcd}";
$oc = "\xf0\x9a\xaf\x8d";
ok( $s->build($ch) eq $oc, "Char utf8: Build: four bytes");
ok( $s->parse($oc) eq $ch, "Char utf8: Parse: four bytes");

$ch = "\x{20AC}";
$oc = "\xE2\x82\xAC";
ok( $s->build($ch) eq $oc, "Char utf8: Build: three bytes");
ok( $s->parse($oc) eq $ch, "Char utf8: Parse: three bytes");

$ch = "\x{0430}";
$oc = "\xD0\xB0";
ok( $s->build($ch) eq $oc, "Char utf8: Build: two bytes");
ok( $s->parse($oc) eq $ch, "Char utf8: Parse: two bytes");

$s = Char("c", "UTF-16BE");

$ch = "\x{0430}";
$oc = "\x04\x30";
ok( $s->build($ch) eq $oc, "Char UTF-16BE: Build: single");
ok( $s->parse($oc) eq $ch, "Char UTF-16BE: Parse: single");

$ch = "\x{1abcd}";
$oc = "\xD8\x2A\xDF\xCD";
ok( $s->build($ch) eq $oc, "Char UTF-16BE: Build: Surrogate Pairs");
ok( $s->parse($oc) eq $ch, "Char UTF-16BE: Parse: Surrogate Pairs");

$s = Char("c", "UTF-16LE");

$ch = "\x{0430}";
$oc = "\x30\x04";
ok( $s->build($ch) eq $oc, "Char UTF-16LE: Build: single");
ok( $s->parse($oc) eq $ch, "Char UTF-16LE: Parse: single");

$ch = "\x{1abcd}";
$oc = "\x2A\xD8\xCD\xDF";
ok( $s->build($ch) eq $oc, "Char UTF-16LE: Build: Surrogate Pairs");
ok( $s->parse($oc) eq $ch, "Char UTF-16LE: Parse: Surrogate Pairs");

$s = Char("c", "UTF-32BE");

$ch = "\x{0430}";
$oc = "\0\0\x04\x30";
ok( $s->build($ch) eq $oc, "Char UTF-32BE: Build: single");
ok( $s->parse($oc) eq $ch, "Char UTF-32BE: Parse: single");

$ch = "\x{1abcd}";
$oc = "\0\1\xAB\xCD";
ok( $s->build($ch) eq $oc, "Char UTF-32BE: Build: high char");
ok( $s->parse($oc) eq $ch, "Char UTF-32BE: Parse: high char");

$s = Char("c", "UTF-32LE");

$ch = "\x{0430}";
$oc = "\x30\x04\0\0";
ok( $s->build($ch) eq $oc, "Char UTF-32LE: Build: single");
ok( $s->parse($oc) eq $ch, "Char UTF-32LE: Parse: single");

$ch = "\x{1abcd}";
$oc = "\xCD\xAB\1\0";
ok( $s->build($ch) eq $oc, "Char UTF-32LE: Build: high char");
ok( $s->parse($oc) eq $ch, "Char UTF-32LE: Parse: high char");

foreach my $enc (qw{UTF-32 utf UTF-16 UTF UTF8 ucs-2}) {
    eval { Char("c", $enc) };
    ok( $@, "Char died on encoding: $enc");
}

$s = Char("c", "iso-8859-8");

$ch = "\x{05D0}"; # the letter "Alef" in hebrew, in unicode
$oc = "\xE0"; # the same in iso-8859-8
ok( $s->build($ch) eq $oc, "Char hebrew: Build: simple");
ok( $s->parse($oc) eq $ch, "Char hebrew: Parse: simple");

my $love_decoded = "\x{05D0}\x{05D4}\x{05D1}\x{05D4}";
my $love_encoded = "\xd7\x90\xd7\x94\xd7\x91\xd7\x94";

$s = PaddedString("foo", 10, encoding => "utf8", padchar => "\0");

$oc = $love_encoded."\0\0";
ok( $s->build($love_decoded) eq $oc, "String: Build: love");
ok( $s->parse($oc) eq $love_decoded, "String: Parse: love");

$s = PascalString("foo", undef, "utf8");

$oc = "\x04".$love_encoded;
ok( $s->build($love_decoded) eq $oc, "PascalString: Build: love");
ok( $s->parse($oc) eq $love_decoded, "PascalString: Parse: love");

$s = CString("foo", encoding => "utf8");

$oc = $love_encoded."\0";
ok( $s->build($love_decoded) eq $oc, "CString: Build: love");
ok( $s->parse($oc) eq $love_decoded, "CString: Parse: love");
