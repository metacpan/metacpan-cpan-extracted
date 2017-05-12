#!perl

use strict;
use utf8;
use Encode;

use Acme::AjiFry;

use Test::More;

my $got;
my $aji_fry = Acme::AjiFry->new();

$got = Encode::decode_utf8($aji_fry->to_AjiFry("おさしみ"));
is($got, "食えアジフライお刺身食え食えお刺身ドボドボ岡星ドボドボ", "From Ja: 1");

$got = Encode::decode_utf8($aji_fry->to_AjiFry("あきらめたらそこでしあいしゅうりょうだよ"));
is($got, "食え食え食えフライドボドボああ食え食え岡星むむ･･･アジ食え食えああ食え食えお刺身アジフライフライアジフライアジむむ･･･陶人お刺身ドボドボ食え食え食え食えドボドボお刺身ドボドボ中川ゴク･･･お刺身食えお刺身ああドボドボ中川ゴク･･･アジフライ食えお刺身アジ食え食え陶人ゴク･･･アジフライ", "From Ja: 2");

$got = Encode::decode_utf8($aji_fry->to_AjiFry("ぱりーぐ"));
is($got, "山岡食え食え社主ああドボドボーフライお刺身陶人", "From Ja: 3");

$got = Encode::decode_utf8($aji_fry->to_AjiFry("んじゃめな"));
is($got, "京極お刺身ドボドボ陶人中川ゴク･･･食え食え岡星むむ･･･ドボ食え食え", "From Ja: 4");

$got = Encode::decode_utf8($aji_fry->to_AjiFry(""));
is($got, '', "From Ja: 5");

$got = Encode::decode_utf8($aji_fry->translate_to_ajifry("おさしみ"));
is($got, "食えアジフライお刺身食え食えお刺身ドボドボ岡星ドボドボ", "Other way");

done_testing();
