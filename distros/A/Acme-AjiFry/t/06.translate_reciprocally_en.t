#!perl

use strict;
use utf8;
use Encode;

use Acme::AjiFry::EN;

use Test::More;

my $got;
my $aji_fry_en = Acme::AjiFry::EN->new();

$got = $aji_fry_en->to_English($aji_fry_en->to_AjiFry("0123456789"));
is($got, "0123456789", "Translate reciprocally En: Number");

$got = $aji_fry_en->to_English($aji_fry_en->to_AjiFry("abcdefghijklmnopqrstuvwxyz"));
is($got, "abcdefghijklmnopqrstuvwxyz", "Translate reciprocally En: Small Letter");

$got = $aji_fry_en->to_English($aji_fry_en->to_AjiFry("ABCDEFGHIJKLMNOPQRSTUVWXYZ"));
is($got, "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "Translate reciprocally En: Capital Letter");

$got = $aji_fry_en->to_English($aji_fry_en->to_AjiFry("012abcDEFgH!4~-+::Z"));
is($got, "012abcDEFgH!4~-+::Z", "Translate reciprocally En: Mix");

done_testing();
