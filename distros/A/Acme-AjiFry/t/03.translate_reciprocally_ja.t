#!perl

use strict;
use utf8;
use Encode;

use Acme::AjiFry;

use Test::More;

my $got;
my $aji_fry = Acme::AjiFry->new();

$got = Encode::decode_utf8($aji_fry->to_Japanese($aji_fry->to_AjiFry("おさしみ")));
is($got, "おさしみ", "Translate reciprocally Ja: 1");

$got = Encode::decode_utf8($aji_fry->to_Japanese($aji_fry->to_AjiFry("ぱりーぐ")));
is($got, "ぱりーぐ", "Translate reciprocally Ja: 2");

$got = Encode::decode_utf8($aji_fry->to_Japanese($aji_fry->to_AjiFry("あきらめたらそこでしあいしゅうりょうだよ")));
is($got, "あきらめたらそこでしあいしゅうりょうだよ", "Translate reciprocally Ja: 3");

$got = Encode::decode_utf8($aji_fry->to_Japanese($aji_fry->to_AjiFry("んじゃめな")));
is($got, "んじゃめな", "Translate reciprocally Ja: 4");

done_testing();
