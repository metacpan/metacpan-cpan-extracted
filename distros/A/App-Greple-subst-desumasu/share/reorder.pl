#!/usr/bin/env perl

use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}

my @data = map {
    my($kana) = /(\S+)/;
    {
	line  => $_,
	kana  => $kana,
	regex => qr/(?!^)$kana$/,
    };
} <>;

use List::Util qw(first);
for my $i (1 .. $#data) {
    my $match =
	(first { $data[$i]->{kana} =~ $data[$_]->{regex} } 0 .. $i - 1)
	// next;
    splice @data, $match, 0 => splice @data, $i, 1;
}

print $_->{line} for @data;
