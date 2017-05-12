#!perl

use strict;
use warnings;

use Chess::FIDE::Player;
use Test::More tests => 6;

my $player = Chess::FIDE::Player->new(
	id => 10,
	srtng => 2000,
	fideblah => 'blah',
);
isa_ok($player, 'Chess::FIDE::Player');
is($player->id, 10, "Id correct");
is($player->srtng, 2000, "rating correct");
is($player->fideblah, undef, "non-existant property");
is($player->id(20), 20, "Id updated");
is($player->fideblah(20), undef, "non-existant no update");
