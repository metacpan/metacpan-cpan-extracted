#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('Convert::Base91', qw/encode_base91 decode_base91/) };

is encode_base91("Hello, World!\n"), '>OwJh>}AQ;r@@Y?FF', 'encode';
is decode_base91('>OwJh>}AQ;r@@Y?FF'), "Hello, World!\n", 'decode';

my $str = 'abc_def';
is decode_base91(encode_base91($str)), $str, 'roundtrip';

my $base91 = Convert::Base91->new;
$base91->encode('Hello, ');
$base91->encode('World!');
$base91->encode("\n");
my $encoded = $base91->encode_end;
is $encoded, '>OwJh>}AQ;r@@Y?FF', 'OO encode';

$base91->decode('>OwJh>}AQ');
$base91->decode(';r@@Y?FF');
my $decoded = $base91->decode_end;
is $decoded, "Hello, World!\n", 'OO decode';
