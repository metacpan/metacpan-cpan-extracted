
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use t::Utils;

use Acme::PrettyCure;

# skip warnings
binmode(Test::More->builder->$_, ':utf8') for qw/failure_output output todo_output/;

my ($hibi, $kana, $eren, $ako) = Acme::PrettyCure->girls('Suite');

isa_ok $hibi, 'Acme::PrettyCure::Girl::CureMelody';
isa_ok $kana, 'Acme::PrettyCure::Girl::CureRhythm';
isa_ok $eren, 'Acme::PrettyCure::Girl::CureBeat';
isa_ok $ako,  'Acme::PrettyCure::Girl::CureMuse';

throws_ok { $hibi->transform } qr/ニャ/, 'スイートのメロディ、リズムは単独変身不可能';
throws_ok { $hibi->transform($eren) } qr/ニャ/, '奏以外とも変身は出来ない';

throws_ok { $kana->transform } qr/ニャ/, 'スイートのメロディ、リズムは単独変身不可能';
throws_ok { $kana->transform($eren) } qr/ニャ/, '響以外とも変身は出来ない';

is $hibi->name, '北条響';
is $kana->name, '南野奏';
is $eren->name, '黒川エレン';
is $ako->name,  '調辺アコ';

is_output sub { $hibi->transform($kana, $eren, $ako) }, <<EOS, '変身時の台詞';
絶対に許さない!!!!
爪弾くは荒ぶる調べ! キュアメロディ!
爪弾くはたおやかな調べ! キュアリズム!
爪弾くは魂の調べ! キュアビート!
爪弾くは女神の調べ! キュアミューズ!
届け、みんなの組曲!
スイートプリキュア!!!!
EOS

is $hibi->name, 'キュアメロディ';
is $kana->name, 'キュアリズム';
is $eren->name, 'キュアビート';
is $ako->name,  'キュアミューズ';

done_testing;

