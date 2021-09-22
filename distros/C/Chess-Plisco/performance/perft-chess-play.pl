#! /usr/bin/env perl

use strict;

use Chess::Play;
use Storable qw(dclone);

use constant COPY => 1;

sub perftWithOutput;
sub perft;

my ($depth, @fen) = @ARGV;

die "usage: DEPTH[, FEN]" if (!$depth || $depth !~ /^[1-9][0-9]*/);

autoflush STDOUT, 1;

my $fen = join ' ', @fen;
my $pos = Chess::Play->new;
if ($fen) {
	$pos->import_fen($fen);
} else {
	$pos->reset;
}

perftWithOutput $pos, $depth, \*STDOUT;

sub perftWithOutput {
	my ($pos, $depth, $fh) = @_;

	return if $depth <= 0;

	require Time::HiRes;
	my $started = [Time::HiRes::gettimeofday()];

	my $nodes = 0;

	my @saved_board = @{$pos->{BOARD} };
	my @saved_last_double_move = @{$pos->{LAST_DOUBLE_MOVE} };
	my %saved_castle_ok = %{ $pos->{CASTLE_OK} };
	my %saved_under_check = %{$pos->{UNDER_CHECK} };
	my $saved_rule_50_moves = $pos->{RULE_50_MOVES};
	my $saved_color_to_move = $pos->{COLOR_TO_MOVE};
	my $saved_move_number = $pos->{FEN_MOVE_NUMBER};
 
	foreach my $move ($pos->generate_legal_moves($pos->{COLOR_TO_MOVE})) {
		$pos->execute_move($move);

		my $movestr = Chess::Play::move_to_coord($move);
		$fh->print("$movestr: ");

		my $subnodes;

		if ($depth > 1) {
			$subnodes = perft($pos, $depth - 1);
		} else {
			$subnodes = 1;
		}

		$nodes += $subnodes;

		$fh->print("$subnodes\n");

		@{$pos->{BOARD}} = @saved_board;
		@{$pos->{LAST_DOUBLE_MOVE}} = @saved_last_double_move;
		%{$pos->{CASTLE_OK}} = %saved_castle_ok;
		%{$pos->{UNDER_CHECK}} = %saved_under_check;
		$pos->{RULE_50_MOVES} = $saved_rule_50_moves;
		$pos->{COLOR_TO_MOVE} = $saved_color_to_move;
		$pos->{FEN_MOVE_NUMBER} = $saved_move_number;
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

	my @saved_board = @{$pos->{BOARD} };
	my @saved_last_double_move = @{$pos->{LAST_DOUBLE_MOVE} };
	my %saved_castle_ok = %{ $pos->{CASTLE_OK} };
	my %saved_under_check = %{$pos->{UNDER_CHECK} };
	my $saved_rule_50_moves = $pos->{RULE_50_MOVES};
	my $saved_color_to_move = $pos->{COLOR_TO_MOVE};
	my $saved_move_number = $pos->{FEN_MOVE_NUMBER};
 
	foreach my $move ($pos->generate_legal_moves($pos->{COLOR_TO_MOVE})) {
		$pos->execute_move($move);

		if ($depth > 1) {
			$nodes += perft($pos, $depth - 1);
		} else {
			++$nodes;
		}

		@{$pos->{BOARD}} = @saved_board;
		@{$pos->{LAST_DOUBLE_MOVE}} = @saved_last_double_move;
		%{$pos->{CASTLE_OK}} = %saved_castle_ok;
		%{$pos->{UNDER_CHECK}} = %saved_under_check;
		$pos->{RULE_50_MOVES} = $saved_rule_50_moves;
		$pos->{COLOR_TO_MOVE} = $saved_color_to_move;
		$pos->{FEN_MOVE_NUMBER} = $saved_move_number;
	}

	return $nodes;
}
