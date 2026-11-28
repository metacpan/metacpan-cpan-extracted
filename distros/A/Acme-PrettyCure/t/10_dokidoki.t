use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';
use Test::PrettyCure;

use Acme::PrettyCure;

my ($mana, $rikka, $arisu, $makoto, $aguri) = Acme::PrettyCure->girls('DokiDoki');

isa_ok $mana,   'Acme::PrettyCure::Girl::CureHeart';
isa_ok $rikka,  'Acme::PrettyCure::Girl::CureDiamond';
isa_ok $arisu,  'Acme::PrettyCure::Girl::CureRosetta';
isa_ok $makoto, 'Acme::PrettyCure::Girl::CureSword';
isa_ok $aguri,  'Acme::PrettyCure::Girl::CureAce';

is_output sub { $mana->transform($rikka, $arisu, $makoto, $aguri); }, <<EOS, '変身時の台詞';
プリキュア!!!!! ラブリンク!!!!! L・O・V・E!!!!!
みなぎる愛!キュアハート!
英知の光!キュアダイヤモンド!
ひだまりポカポカ♪キュアロゼッタ!
勇気の刃!キュアソード!
愛の切り札!キュアエース!
響け、愛の鼓動!!!!! ドキドキ!プリキュア!!!!!
EOS

done_testing;

