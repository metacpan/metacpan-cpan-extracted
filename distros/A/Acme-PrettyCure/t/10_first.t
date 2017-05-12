use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use t::Utils;

use Acme::PrettyCure;

# skip warnings
binmode(Test::More->builder->$_, ':utf8') for qw/failure_output output todo_output/;

my ($nagi, $hono) = Acme::PrettyCure->girls('First');

isa_ok $nagi, 'Acme::PrettyCure::Girl::CureBlack';
isa_ok $hono, 'Acme::PrettyCure::Girl::CureWhite';

throws_ok { $nagi->transform } qr/メポ/, '初代は単独変身不可能';
throws_ok { $nagi->transform($nagi) } qr/メポ/, 'ほのか以外とも変身は出来ない';

throws_ok { $hono->transform } qr/ミポ/, '初代は単独変身不可能';
throws_ok { $hono->transform($hono) } qr/ミポ/, 'なぎさ以外とも変身は出来ない';

is $nagi->name, '美墨なぎさ';
is $hono->name, '雪城ほのか';

is_output sub { $nagi->transform($hono); }, <<EOS, '変身時の台詞';
光の使者、キュアブラック!
光の使者、キュアホワイト!
ふたりはプリキュア!
闇の力の僕たちよ!
とっととおうちに帰りなさい!
EOS

is $nagi->name, 'キュアブラック';
is $hono->name, 'キュアホワイト';

done_testing;

