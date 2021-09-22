#! /usr/bin/env perl

use strict;

use Chess::Rep;
use Storable qw(dclone);

sub perftWithOutput;
sub perft;

my ($depth, @fen) = @ARGV;

die "usage: DEPTH[, FEN]" if (!$depth || $depth !~ /^[1-9][0-9]*/);

autoflush STDOUT, 1;

my $fen = join ' ', @fen;
my $pos = Chess::Rep->new($fen);

perftWithOutput $pos, $depth, \*STDOUT;

sub perftWithOutput {
	my ($pos, $depth, $fh) = @_;

	return if $depth <= 0;

	require Time::HiRes;
	my $started = [Time::HiRes::gettimeofday()];

	my $nodes = 0;

	foreach my $move (@{$pos->status->{moves}}) {
		my $movestr = join '', map {
			my ($rank, $file) = (($_ & 0x70) >> 4, $_ & 0x7);
			chr($file + 97) . chr($rank + 49);
		} ($move->{from}, $move->{to});
		$movestr .= $move->{promote} if $move->{promote};

		my $copy = dclone $pos;
		$copy->go_move($movestr);

		$fh->print("$movestr: ");

		my $subnodes;

		if ($depth > 1) {
			$subnodes = perft($copy, $depth - 1);
		} else {
			$subnodes = 1;
		}

		$nodes += $subnodes;

		$fh->print("$subnodes\n");
	}

	no integer;

	my $elapsed = Time::HiRes::tv_interval($started, [Time::HiRes::gettimeofday()]);

	my $nps = '+INF';
	if ($elapsed) {
		$nps = int (0.5 + $nodes / $elapsed);
	}
	$fh->print("info nodes: $nodes ($elapsed s, nps: $nps)\n");

	return $nodes;
}

sub perft {
	my ($pos, $depth) = @_;

	my $nodes = 0;
	foreach my $move (@{$pos->status->{moves}}) {
		my $movestr = join '', map {
			my ($rank, $file) = (($_ & 0x70) >> 4, $_ & 0x7);
			chr($file + 97) . chr($rank + 49);
		} ($move->{from}, $move->{to});
		$movestr .= $move->{promote} if $move->{promote};

		my $copy = dclone $pos;
		$copy->go_move($movestr);

		if ($depth > 1) {
			$nodes += perft($copy, $depth - 1);
		} else {
			++$nodes;
		}
	}

	return $nodes;
}
