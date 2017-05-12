#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;

use Test::More tests => 36;
use Test::More;

use Acme::Honkidasu;

my @list = <DATA>;
$Acme::Honkidasu::LIST_HONKIDASU = \@list;
for my $i (1..12) {
    my $t = Time::Piece->strptime(sprintf('%02d', $i), '%m');
    chomp( my $msg = $list[ ( $i % scalar(@list) ) - 1 ] );
    cmp_ok $t->honkidasu, 'eq', $msg;
    cmp_ok $t->strftime('%('), 'eq', $msg;
}

$Acme::Honkidasu::LIST_HONKIDASU = [];
for my $i (1..12) {
    my $t = Time::Piece->strptime(sprintf('%02d', $i), '%m');
    chomp( my $msg = $list[ ( $i % scalar(@list) ) - 1 ] );
    ok ! $t->honkidasu;
}

done_testing;

__DATA__
ほげ
ふが
ぴよ
ふー
