#!perl

use strict;
use utf8;
use Encode;

use Acme::AjiFry::EN;

use Test::More;

my $got;
my $aji_fry_en = Acme::AjiFry::EN->new();

$got = Encode::decode_utf8($aji_fry_en->to_AjiFry("0123456789"));
is($got, "京極お刺身京極むむ･･･京極アジフライ陶人食え食え陶人ドボドボ陶人お刺身陶人むむ･･･陶人アジフライ社主食え食え社主ドボドボ", "Translate from En: 1");

$got = Encode::decode_utf8($aji_fry_en->to_AjiFry("abcdefghijklmnopqrstuvwxyz"));
is($got, "食え食え食え食えドボドボ食えお刺身食えむむ･･･食えアジフライフライ食え食えフライドボドボフライお刺身フライむむ･･･フライアジフライお刺身食え食えお刺身ドボドボお刺身お刺身お刺身むむ･･･お刺身アジフライアジ食え食えアジドボドボアジお刺身アジむむ･･･アジアジフライドボ食え食えドボドボドボドボお刺身ドボむむ･･･ドボアジフライ山岡食え食え", "Translate from En: 2");

$got = Encode::decode_utf8($aji_fry_en->to_AjiFry("ABCDEFGHIJKLMNOPQRSTUVWXYZ"));
is($got, "山岡ドボドボ山岡お刺身山岡むむ･･･山岡アジフライ岡星食え食え岡星ドボドボ岡星お刺身岡星むむ･･･岡星アジフライゴク･･･食え食えゴク･･･ドボドボゴク･･･お刺身ゴク･･･むむ･･･ゴク･･･アジフライああ食え食えああドボドボああお刺身ああむむ･･･ああアジフライ雄山食え食え雄山ドボドボ雄山お刺身雄山むむ･･･雄山アジフライ京極食え食え京極ドボドボ", "Translate from En: 3");

$got = Encode::decode_utf8($aji_fry_en->to_AjiFry("012abcDEFgH!4~-+::Z"));
is($got, "京極お刺身京極むむ･･･京極アジフライ食え食え食え食えドボドボ食えお刺身山岡アジフライ岡星食え食え岡星ドボドボフライドボドボ岡星むむ･･･!陶人ドボドボ~-+::京極ドボドボ", "Translate from En: 4");

$got = Encode::decode_utf8($aji_fry_en->to_AjiFry(""));
is($got, "", "Translate from En: 5");

$got = Encode::decode_utf8($aji_fry_en->translate_to_ajifry("0123456789"));
is($got, "京極お刺身京極むむ･･･京極アジフライ陶人食え食え陶人ドボドボ陶人お刺身陶人むむ･･･陶人アジフライ社主食え食え社主ドボドボ", "other way");

done_testing();
