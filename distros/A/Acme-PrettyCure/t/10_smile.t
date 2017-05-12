use strict;
use warnings;
use utf8;
use Test::More;
use t::Utils;

use Acme::PrettyCure;

my ($miyuki, $akane, $yayoi, $nao, $reika) = Acme::PrettyCure->girls('Smile');

isa_ok $miyuki,  'Acme::PrettyCure::Girl::CureHappy';
isa_ok $akane,   'Acme::PrettyCure::Girl::CureSunny';
isa_ok $yayoi,   'Acme::PrettyCure::Girl::CurePeace';
isa_ok $nao,     'Acme::PrettyCure::Girl::CureMarch';
isa_ok $reika,   'Acme::PrettyCure::Girl::CureBeauty';

is_output sub { $miyuki->transform($akane, $yayoi, $nao, $reika); }, <<EOS, '変身時の台詞';
キラキラ輝く未来の光! キュアハッピー!
太陽サンサン熱血パワー! キュアサニー!
ピカピカぴかりんじゃんけんぽん♪ キュアピース!
勇気リンリン直球勝負! キュアマーチ!
しんしんと降りつもる清き心! キュアビューティ!
五つの心が導く未来!
輝け! スマイルプリキュア!
EOS

done_testing;

