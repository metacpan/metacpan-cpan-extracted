use strict;
use warnings;
use utf8;
use Test::More;
use t::Utils;

use Acme::PrettyCure;

my ($love, $miki, $bukky, $setsu) = Acme::PrettyCure->girls('Fresh');

isa_ok $love,  'Acme::PrettyCure::Girl::CurePeach';
isa_ok $miki,  'Acme::PrettyCure::Girl::CureBerry';
isa_ok $bukky, 'Acme::PrettyCure::Girl::CurePine';
isa_ok $setsu, 'Acme::PrettyCure::Girl::CurePassion';

is_output sub { $love->transform($miki, $bukky, $setsu); }, <<EOS, '変身時の台詞';
チェインジ・プリキュア! ビートアップ!!!!
ピンクのハートは愛ある印
もぎたてフレッシュ、キュアピーチ!
ブルーのハートは希望の印
つみたてフレッシュ、キュアベリー!
イエローハートは祈りの印
とれたてフレッシュ、キュアパイン!
真っ赤なハートは幸せの証
うれたてフレッシュ、キュアパッション!
フレッシュプリキュア!!!!
EOS

done_testing;

