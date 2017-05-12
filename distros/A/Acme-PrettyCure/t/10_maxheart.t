use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;

use Acme::PrettyCure;

# skip warnings
binmode(Test::More->builder->$_, ':utf8') for qw/failure_output output todo_output/;

my ($nagi, $hono, $hikari) = Acme::PrettyCure->girls('MaxHeart');

isa_ok $nagi,   'Acme::PrettyCure::Girl::CureBlackMH';
isa_ok $hono,   'Acme::PrettyCure::Girl::CureWhiteMH';
isa_ok $hikari, 'Acme::PrettyCure::Girl::ShinyLuminous';

throws_ok { $nagi->transform } qr/メポ/, '初代は単独変身不可能';
throws_ok { $nagi->transform($nagi) } qr/メポ/, 'ほのか以外とも変身は出来ない';

throws_ok { $hono->transform } qr/ミポ/, '初代は単独変身不可能';
throws_ok { $hono->transform($hono) } qr/ミポ/, 'なぎさ以外とも変身は出来ない';

is $nagi->name, '美墨なぎさ';
is $hono->name, '雪城ほのか';

$nagi->transform($hono);

is $nagi->name, 'キュアブラック';
is $hono->name, 'キュアホワイト';

done_testing;

