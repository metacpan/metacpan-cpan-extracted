use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;

use Acme::PrettyCure;

# skip warnings
binmode(Test::More->builder->$_, ':utf8') for qw/failure_output output todo_output/;

my ($saki, $mai) = Acme::PrettyCure->members('SplashStar');

isa_ok $saki, 'Acme::PrettyCure::CureBloom';
isa_ok $mai,  'Acme::PrettyCure::CureEgret';

throws_ok { $saki->transform } qr/ラピ/, 'SSも単独変身不可能';
throws_ok { $saki->transform($saki) } qr/ラピ/, '舞以外とも変身は出来ない';

throws_ok { $mai->transform } qr/チョピ/, '初代は単独変身不可能';
throws_ok { $mai->transform($mai) } qr/チョピ/, '咲以外とも変身は出来ない';

is $saki->name, '日向咲';
is $mai->name, '美翔舞';

$saki->transform($mai);

is $saki->name, 'キュアブルーム';
is $mai->name, 'キュアイーグレット';

$saki = $saki->powerup;
$mai = $mai->powerup;

isa_ok $saki, 'Acme::PrettyCure::CureBloom';
isa_ok $mai,  'Acme::PrettyCure::CureEgret';

is $saki->name, 'キュアブライト';
is $mai->name, 'キュアウィンディ';

done_testing;

