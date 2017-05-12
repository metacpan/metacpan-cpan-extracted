use strict;
use warnings;
use utf8;
use Test::More;
use t::Utils;

use Acme::PrettyCure;

my ($nozomi, $rin, $urara, $komachi, $karen) = Acme::PrettyCure->girls('Five');

isa_ok $nozomi,  'Acme::PrettyCure::Girl::CureDream';
isa_ok $rin,     'Acme::PrettyCure::Girl::CureRouge';
isa_ok $urara,   'Acme::PrettyCure::Girl::CureLemonade';
isa_ok $komachi, 'Acme::PrettyCure::Girl::CureMint';
isa_ok $karen,   'Acme::PrettyCure::Girl::CureAqua';

is_output sub { $nozomi->transform($rin, $urara, $komachi, $karen); }, <<EOS, '変身時の台詞';
大いなる希望の力、キュアドリーム!
情熱の赤い炎、キュアルージュ!
はじけるレモンの香り、キュアレモネード!
やすらぎの緑の大地、キュアミント!
知性の青き泉、キュアアクア!
希望の力と、未来の光
華麗に羽ばたく五つの心!
Yes! プリキュア5!
EOS

done_testing;

