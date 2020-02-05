#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Config;
use Data::Peek;

my $is_ebcdic = ($Config{ebcdic} || "undef") eq "define" ? 1 : 0;

is (DHexDump (undef),		undef,			'undef');
is (DHexDump (""),		"",			'""');

for (split m/##\n/ => test_data ()) {
    my ($desc, $in, @out) = split m/\n-\n/, $_, 4;
    my $out = $out[$is_ebcdic];
    $out =~ s/\n*\z/\n/;

    if ($in =~ s/\t(\d+)$//) {
	is (scalar DHexDump ($in, $1), $out,	"HexDump $desc");
	}
    else {
	is (scalar DHexDump ($in),     $out,	"HexDump $desc");
	}
    }

done_testing;

sub test_data {
    return <<"EOTD";
Single 0
-
0
-
0000  30                                                0
-
0000  f0                                                0
##
Documentation example
-
abc\x{0a}de\x{20ac}fg
-
0000  61 62 63 0a 64 65 e2 82  ac 66 67                 abc.de...fg
-
0000  81 82 83 0a 84 85 ca 46  53 86 87                 abc.de...fg
##
Documentation example with length
-
abc\x{0a}de\x{20ac}fg	6
-
0000  61 62 63 0a 64 65                                 abc.de
-
0000  81 82 83 0a 84 85                                 abc.de
##
Binary data
-
\x01Great wide open space\x02\x{20ac}\n
-
0000  01 47 72 65 61 74 20 77  69 64 65 20 6f 70 65 6e  .Great wide open
0010  20 73 70 61 63 65 02 e2  82 ac 0a                  space.....
-
0000  01 c7 99 85 81 a3 40 a6  89 84 85 40 96 97 85 95  .Great wide open
0010  40 a2 97 81 83 85 02 ca  46 53 15                  space.....
##
EOTD
    } # test_data
