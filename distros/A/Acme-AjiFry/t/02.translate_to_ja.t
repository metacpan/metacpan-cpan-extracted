#!perl

use strict;
use utf8;
use Encode;

use Acme::AjiFry;

use Test::More;

my $got;
my $aji_fry = Acme::AjiFry->new();

$got = Encode::decode_utf8($aji_fry->to_Japanese("食えアジフライお刺身食え食えお刺身ドボドボ岡星ドボドボ"));
is($got, "おさしみ", "To Ja: 1");

$got = Encode::decode_utf8($aji_fry->to_Japanese("山岡食え食え社主ああドボドボーフライお刺身陶人"));
is($got, "ぱりーぐ", "To Ja: 2");

$got = Encode::decode_utf8($aji_fry->to_Japanese("食え食え食えフライドボドボああ食え食え岡星むむ･･･アジ食え食えああ食え食えお刺身アジフライフライアジフライアジむむ･･･陶人お刺身ドボドボ食え食え食え食えドボドボお刺身ドボドボ中川ゴク･･･お刺身食えお刺身ああドボドボ中川ゴク･･･アジフライ食えお刺身アジ食え食え陶人ゴク･･･アジフライ"));
is($got, "あきらめたらそこでしあいしゅうりょうだよ", "To Ja: 3");

$got = Encode::decode_utf8($aji_fry->to_Japanese("京極お刺身ドボドボ陶人中川ゴク･･･食え食え岡星むむ･･･ドボ食え食え"));
is($got, "んじゃめな", "To Ja: 4");

$got = Encode::decode_utf8($aji_fry->to_Japanese(""));
is($got, "", "To Ja: 5");

$got = Encode::decode_utf8($aji_fry->translate_from_ajifry("食えアジフライお刺身食え食えお刺身ドボドボ岡星ドボドボ"));
is($got, "おさしみ", "To Ja: 1");

done_testing();
