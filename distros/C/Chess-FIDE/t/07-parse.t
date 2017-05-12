#!perl

use strict;
use warnings;

use Chess::FIDE;
use Test::More qw(no_plan);

use Data::Dumper;

our $PLAYER;
our $ERROR;

use Sys::MemInfo qw(freemem freeswap);

sub my_like {
	no warnings 'uninitialized';
	my $error;
	unless (like($_[0], $_[1], "$_[2]: $_[0]")) {
		$ERROR = 1;
		BAIL_OUT("Failed $_[-1]");
	}
	use warnings FATAL => 'all';
}

if (freemem() + freeswap() < 1.5*10**9) {
	warn "You will need about 1.5G of memory to run this test file.\n";
	unless ($ENV{FORCE_LARGE_FILE_LOAD}) {
		pass("If you insist, set environment variable FORCE_LARGE_FILE_LOAD");
		exit 0;
	}
}

my $fide = Chess::FIDE->new(
 	-www => 1,
);
if (! $fide) {
	warn "You probably have problems with network connection or zip library\n";
	pass("No players parsed");
}
else {
	ok(scalar(@{$fide->{players}}) > 99999, "Lots of players parsed");
	unless ($ENV{WANT_TO_RUN_A_MILLION_TESTS}) {
		pass("If you want to run this test file completely, set environment variable WANT_TO_RUN_A_MILLION_TESTS");
		exit 0;
	}
	my %ids = ();
	$| = 1;
	my $p = 1;
	for my $player (@{$fide->{players}}) {
		$PLAYER = $player;
		my_like($player->id, qr/^\d+$/, "($p) id $player->{id} parsed");
		ok(!exists $ids{$player->id}, "no repeating id " . $player->id);
		$ids{$player->id} = 1;
		unless ($p % 50) {
			my_like($player->fidename, qr/\S/, 'fide name has a nonwhitespace');
			my_like($player->name, qr/\S/, 'there is a name');
			my_like($player->surname, qr/\S/, 'there is a surname');
			my_like($player->givenname, qr/\S/, 'there is a givenname');
			my_like($player->fed, qr/^[A-Z]{3}$/, 'federation is three letters');
			my_like($player->sex, qr/^(M|F)$/, 'sex is M or F');
			my_like($player->tit, qr/^W?(C|F|I|G)M/, 'valid title') if
				$player->tit && $player->tit ne 'WH';
			my_like($player->wtit, qr/^W(C|F|I|G)M/, 'valid women title') if
				$player->wtit && $player->wtit ne 'WH';
			my_like($player->srtng, qr/^\d{4}$/, 'four digit rating') if defined $player->srtng;
			my_like($player->sgm, qr/^\d+$/, 'rated games a number') if defined $player->sgm;
			my_like($player->sk, qr/^\d+$/, 'rated gamescoeff k a number') if defined $player->sk;
			my_like($player->rrtng, qr/^\d{4}$/, 'four digit rapid rating') if defined $player->rrtng;
			my_like($player->rgm, qr/^\d+$/, 'rated rapid games a number') if defined $player->rgm;
			my_like($player->rk, qr/^\d+$/, 'rated rapid gamescoeff k a number') if defined $player->rk;
			my_like($player->brtng, qr/^\d{4}$/, 'four digit blitz rating') if defined $player->brtng;
			my_like($player->bgm, qr/^\d+$/, 'rated blitz games a number') if defined $player->bgm;
			my_like($player->bk, qr/^\d+$/, 'rated blitz gamescoeff k a number') if defined $player->bk;
			my_like($player->bday, qr/^\d{4}$/, 'bday year a 4 digit number') if $player->bday;
			my_like($player->flag, qr/^w?i?/, 'flag can be w or i or wi or nothing');
		}
		$p++;
	}
}
END {
	print Dumper $PLAYER if $PLAYER && $ERROR;
}
