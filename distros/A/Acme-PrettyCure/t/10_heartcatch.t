use strict;
use warnings;
use utf8;
use Test::More;
use t::Utils;

use Acme::PrettyCure;

my ( $tsubomi, $erika, $itsuki, $yuri )
    = Acme::PrettyCure->girls('HeartCatch');

isa_ok $tsubomi, 'Acme::PrettyCure::Girl::CureBlossom';
isa_ok $erika,   'Acme::PrettyCure::Girl::CureMarine';
isa_ok $itsuki,  'Acme::PrettyCure::Girl::CureSunshine';
isa_ok $yuri,    'Acme::PrettyCure::Girl::CureMoonlight';

is_output sub { $tsubomi->transform($erika, $itsuki, $yuri) }, <<EOS, '変身時の台詞';
プリキュア・オープンマイハート!!!!
大地に咲く一輪の花、キュアブロッサム!
海風に揺れる一輪の花、キュアマリン!
陽の光浴びる一輪の花、キュアサンシャイン!
月光に冴える一輪の花、キュアムーンライト!
ハートキャッチプリキュア!!!!
EOS

done_testing;

