use strict;
use warnings;
use utf8;
use Test::More;
use t::Utils;

use Acme::PrettyCure;

my ($mana, $makoto) = Acme::PrettyCure->girls('DokiDoki');

isa_ok $mana,   'Acme::PrettyCure::Girl::CureHeart';
isa_ok $makoto, 'Acme::PrettyCure::Girl::CureSword';
#isa_ok $rikka,  'Acme::PrettyCure::Girl::CureDiamond';
#isa_ok $arisu,  'Acme::PrettyCure::Girl::CureRosetta';

#is_output sub { $mana->transform($rikka, $arisu, $makoto); }, <<EOS, '変身時の台詞';
#みなぎる愛!キュアハート
#英知の光!キュアダイヤモンド
#ひだまりポカポカ!キュアロゼッタ
#勇気の刃!キュアソード
#ドキドキ!プリキュア!
#EOS

done_testing;

