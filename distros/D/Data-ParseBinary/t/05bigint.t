#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use Data::ParseBinary;
use Math::BigInt;
use Test::More tests => 16;
#use Test::More qw(no_plan);
$| = 1;

my ($s, $data, $string);

$s = SBInt64("BigOne");

$data = 1;
$string = "\0\0\0\0\0\0\0\1";
is_deeply($s->parse($string), $data, "SBInt64: Parse: one");
ok( $s->build($data) eq $string, "SBInt64: Build: one");
$data = -256;
$string = "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\0";
is_deeply($s->parse($string), $data, "SBInt64: Parse: minus 256");
ok( $s->build($data) eq $string, "SBInt64: Build: minus 256");

$s = SLInt64("BigOne");

$data = 1;
$string = "\1\0\0\0\0\0\0\0";
is_deeply($s->parse($string), $data, "SLInt64: Parse: one");
ok( $s->build($data) eq $string, "SLInt64: Build: one");
$data = -256;
$string = "\0\xFF\xFF\xFF\xFF\xFF\xFF\xFF";
is_deeply($s->parse($string), $data, "SLInt64: Parse: minus 256");
ok( $s->build($data) eq $string, "SLInt64: Build: minus 256");

$s = UBInt64("BigOne");

$data = 1;
$string = "\0\0\0\0\0\0\0\1";
is_deeply($s->parse($string), $data, "UBInt64: Parse: one");
ok( $s->build($data) eq $string, "UBInt64: Build: one");
$data = Math::BigInt->new("18446744073709551360");
$string = "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\0";
is_deeply($s->parse($string), $data, "UBInt64: Parse: minus 256 (18446744073709551360)");
my $ans = $s->build($data);
ok( $ans eq $string, "UBInt64: Build: minus 256 (got:".unpack("H*", $ans).")");

$s = ULInt64("BigOne");

$data = 1;
$string = "\1\0\0\0\0\0\0\0";
is_deeply($s->parse($string), $data, "ULInt64: Parse: one");
ok( $s->build($data) eq $string, "ULInt64: Build: one");
$data = Math::BigInt->new("18446744073709551360");
$string = "\0\xFF\xFF\xFF\xFF\xFF\xFF\xFF";
is_deeply($s->parse($string), $data, "ULInt64: Parse: minus 256 (18446744073709551360)");
$ans = $s->build($data);
ok( $ans eq $string, "ULInt64: Build: minus 256 (got:".unpack("H*", $ans).")");

