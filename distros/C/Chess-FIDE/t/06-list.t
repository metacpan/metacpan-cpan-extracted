#!perl

use strict;
use warnings FATAL => 'all';

use Chess::FIDE;
use Test::More tests => 213456;

my @inputs = qw(t/data/test-list.txt t/data/test-list-2.txt);
our $PLAYER;

my $i = 0;
for my $input (@inputs) {
	my $fide = Chess::FIDE->new(
		-file => $input,
	);
	my %ids = ();
	is(scalar(@{$fide->{players}}), 9999 - 2*$i, "All players parsed");
	$i++;
	for my $player (@{$fide->{players}}) {
		$PLAYER = $player;
		like($player->id, qr/^\d+$/, "id $player->{id} parsed");
		ok(!exists $ids{$player->id}, 'no repeating id');
		$ids{$player->id} = 1;
		like($player->fidename, qr/\S/, 'fide name has a nonwhitespace');
		like($player->name, qr/\S/, 'there is a name');
		like($player->surname, qr/\S/, 'there is a surname');
		like($player->givenname, qr/\S/, 'there is a givenname');
		like($player->fed, qr/^[A-Z]{3}$/, 'federation is three letters');
		like($player->sex, qr/^(M|F)$/, 'sex is M or F');
		like($player->tit, qr/^W?(C|F|I|G)M/, 'valid title') if
			$player->tit && $player->tit ne 'WH';
		like($player->wtit, qr/^W(C|F|I|G)M/, 'valid women title') if
			$player->wtit && $player->wtit ne 'WH';
		like($player->srtng, qr/^\d{4}$/, 'four digit rating') if defined $player->srtng;
		like($player->sgm, qr/^\d+$/, 'rated games a number') if defined $player->sgm;
		like($player->sk, qr/^\d+$/, 'rated gamescoeff k a number') if defined $player->sk;
		like($player->rrtng, qr/^\d{4}$/, 'four digit rapid rating') if defined $player->rrtng;
		like($player->rgm, qr/^\d+$/, 'rated rapid games a number') if defined $player->rgm;
		like($player->rk, qr/^\d+$/, 'rated rapid gamescoeff k a number') if defined $player->rk;
		like($player->brtng, qr/^\d{4}$/, 'four digit blitz rating') if defined $player->brtng;
		like($player->bgm, qr/^\d+$/, 'rated blitz games a number') if defined $player->bgm;
		like($player->bk, qr/^\d+$/, 'rated blitz gamescoeff k a number') if defined $player->bk;
		like($player->bday, qr/^\d{4}$/, 'bday year a 4 digit number') if $player->bday;
		like($player->flag, qr/^w?i?/, 'flag can be w or i or wi or nothing');
	}
}
