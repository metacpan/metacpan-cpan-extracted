#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::Tree;
$Chess::Plisco::Engine::Tree::VERSION = '0.2';
use strict;
use integer;

use Chess::Position qw(:all);
use Chess::Position::Macro;

use Time::HiRes qw(tv_interval);

use constant MATE => -10000;
use constant INF => ((-(MATE)) << 1);
use constant MAX_PLY => 512;
use constant DRAW => 0;

# For all combinations of promotion piece and captured piece, calculate a
# value suitable for sorting.  We choose the raw material balance minus the
# piece that moves.  That way, captures that the queen makes are less
# "attractive" than captures that the rook makes.
my @move_values = (0) x 369;

sub new {
	my ($class, $position, $info) = @_;

	my $self = {
		position => $position,
		info => $info || sub {},
	};

	bless $self, $class;
}

sub checkTime {
	my ($self) = @_;

	$self->{watcher}->check;

	no integer;

	my $elapsed = 1000 * tv_interval($self->{start_time});
	my $allocated = $self->{allocated_time};
	my $eta = $allocated - $elapsed;
	if ($eta < 4) {
		die "PLISCO_ABORTED\n";
	}

	my $nodes = $self->{nodes};
	my $nps = $elapsed ? (1000 * $nodes / $elapsed) : 10000;
	my $max_nodes_to_tc = $nps >> 3;
	my $nodes_to_tc = int(($eta * $nps) / 2000);

	$self->{nodes_to_tc} = $nodes + 
		(($nodes_to_tc < $max_nodes_to_tc) ? $nodes_to_tc : $max_nodes_to_tc);
}

# __BEGIN_MACROS
sub printPV {
	my ($self, $pline) = @_;

	no integer;
	my $position = $self->{position};
	my $score = $self->{score};
	my $mate_in;
	if ($score >= -(MATE + MAX_PLY)) {
		$mate_in = (-(MATE + $score)) >> 1;
	}

	my $nodes = $self->{nodes};
	my $elapsed = tv_interval($self->{start_time});
	my $nps = $elapsed ? (int(0.5 + $nodes / $elapsed)) : 0;
	my $scorestr = $mate_in ? "mate $mate_in" : "cp $score";
	my $pv = join ' ', $position->movesCoordinateNotation(@$pline);
	my $time = int(0.5 + (1000 * $elapsed));
	my $seldepth = @$pline;
	$self->{info}->("depth $self->{depth} seldepth $self->{seldepth}"
			. " score $scorestr nodes $nodes nps $nps time $time pv $pv");
}

sub alphabeta {
	my ($self, $ply, $depth, $alpha, $beta, $pline, $is_pv) = @_;

	my @line;

	# FIXME! Rather use local variables for all this stuff in order to save
	# hash dereferences.
	if (!$self->{max_depth} && ($self->{nodes} >= $self->{nodes_to_tc})) {
		$self->checkTime;
	}

	my $position = $self->{position};
	if ($depth <= 0) {
		return $self->quiesce($ply, $alpha, $beta, $pline, $is_pv);
	}

	my @moves = $position->pseudoLegalMoves;
	# Expand the moves with a score so that they can be sorted.
	foreach my $move (@moves) {
		my $victim = CP_NO_PIECE;
		my ($to, $promote) = (cp_move_to($move), cp_move_promote($move));
		my $to_mask = 1 << $to;
		my $pos_info = cp_pos_info $position;
		my $ep_shift = cp_pos_info_ep_shift($pos_info);
		my $mover = cp_move_piece $move;
		# En passant capture?
		if ($ep_shift && CP_PAWN == $mover && $ep_shift == $to) {
			$victim = CP_PAWN;
		}
		next if !($promote || ($to_mask & $position->[CP_POS_WHITE_PIECES
			+ !cp_pos_info_to_move($pos_info)]));
		if (!$victim) {
			if ($to_mask & cp_pos_pawns($position)) {
				$victim = CP_PAWN;
			} elsif ($to_mask & cp_pos_knights($position)) {
				$victim = CP_KNIGHT;
			} elsif ($to_mask & cp_pos_bishops($position)) {
				$victim = CP_BISHOP;
			} elsif ($to_mask & cp_pos_rooks($position)) {
				$victim = CP_ROOK;
			} else {
				$victim = CP_QUEEN;
			}
		}

		$move |= ($move_values[($victim << 6) | ($mover << 3) | $promote] << 32);
	}

	@moves = sort { $b <=> $a } @moves;
	if (@$pline >= $ply) {
		my $bestmove = $pline->[$ply - 1];
		for (my $i = 1; $i < @moves; ++$i) {
			if (cp_move_equivalent $moves[$i], $bestmove) {
				unshift @moves, splice @moves, $i, 1;
				last;
			}
		}
	}

	my $legal = 0;
	my $pv_found;
	foreach my $move (@moves) {
		my $state = $position->doMove($move) or next;
		$is_pv = $is_pv && !$legal;
		++$legal;
		++$self->{nodes};
		my $val;
		if ($pv_found) {
			$val = -$self->alphabeta($ply + 1, $depth - 1,
					-$alpha - 1, -$alpha, \@line, $is_pv);

			if (($val > $alpha) && ($val < $beta)) {
				$val = -$self->alphabeta($ply + 1, $depth - 1,
						-$beta, -$alpha, \@line, $is_pv);
			}
		} else {
			$val = -$self->alphabeta($ply + 1, $depth - 1,
					-$beta, -$alpha, \@line, $is_pv);
		}
		$position->undoMove($state);
		if ($val > $beta) {
			return $beta;
		}
		if ($val > $alpha) {
			$alpha = $val;
			$pv_found = 1;
			@$pline = ($move, @line);

			if ($is_pv) {
				$self->{score} = $val;
				$self->printPV($pline);
			}
		}
	}

	if (!$legal) {
		# Mate or stalemate.
		return DRAW if !$position->inCheck;

		return MATE + $ply - 1;
	}

	return $alpha;
}

sub quiesce {
	my ($self, $ply, $alpha, $beta, $pline, $is_pv) = @_;

	if (!$self->{max_depth} && ($self->{nodes} >= $self->{nodes_to_tc})) {
		$self->checkTime;
	}

	$self->{seldepth} = cp_max($ply, $self->{seldepth});

	my @line;
	my $position = $self->{position};
	if (cp_pos_in_check($position)) {
		return $self->alphabeta($ply, 1, $alpha, $beta, \@line, $is_pv);
	}

	my $val = $position->evaluate;
	if ($val >= $beta) {
		return $beta;
	}
	if ($val > $alpha) {
		$alpha = $val;
	}

	my @pseudo_legal = $position->pseudoLegalAttacks;
	my $pos_info = cp_pos_info $position;
	my $her_pieces = $position->[CP_POS_WHITE_PIECES
			+ !cp_pos_to_move($position)];
	my (@moves);
	foreach my $move (@pseudo_legal) {
		my $state = $position->doMove($move) or next;
		$position->undoMove($state);
		my $see = $position->SEE($move);

		# A marginal difference can occur if bishops and knights have different
		# values.  But we want to ignore that.
		next if $see <= -CP_PAWN_VALUE;

		push @moves, ($see << 32) | $move;
	}

	my $legal = 0;
	foreach my $move (sort { $b <=> $a } @moves) {
		my $state = $position->doMove($move);
		$is_pv = $is_pv && !$legal;
		++$self->{nodes};
		$val = -quiesce($self, $ply + 1, -$beta, -$alpha, $pline, $is_pv);
		$position->undoMove($state);
		if ($val >= $beta) {
			return $beta;
		}
		if ($val > $alpha) {
			$alpha = $val;
			@$pline = ($move, @line);
		}
	}

	return $alpha;
}

sub rootSearch {
	my ($self, $pline) = @_;

	$self->{nodes} = 0;

	my $position = $self->{position};

	my $max_depth = $self->{max_depth} || (MAX_PLY - 1);
	my $depth = $self->{depth} = 0;
	$self->{seldepth} = 0;
	my $score = $self->{score} = 0;

	my @line = @$pline;
	my $is_pv;
	eval {
		while (++$depth <= $max_depth) {
			$self->{depth} = $depth;
			$score = -$self->alphabeta(1, $depth, -INF, +INF, \@line, $is_pv);
			# FIXME! No need for abs() here?!
			if (cp_abs($score) > -(MATE + MAX_PLY)) {
				last;
			}
			$is_pv = 1;
		}
	};
	if ($@) {
		if ($@ ne "PLISCO_ABORTED\n") {
			$self->{info}->("ERROR: exception raised: $@");
		}
	}
	@$pline = @line;
}
# __END_MACROS__

sub think {
	my ($self, $tree, $watcher) = @_;

	my $position = $self->{position};
	my @legal = $position->legalMoves or return;

	my @line = ($legal[int rand @legal]);

	$self->{watcher} = $watcher;

	$self->{thinking} = 1;

	$self->rootSearch(\@line);

	delete $self->{thinking};

	$self->printPV(\@line);

	return $line[0];
}

# Fill the lookup table for the move values.
foreach my $mover (CP_PAWN .. CP_KING) {
	my @piece_values = (
		0,
		CP_PAWN_VALUE,
		CP_KNIGHT_VALUE,
		CP_BISHOP_VALUE,
		CP_ROOK_VALUE,
		CP_QUEEN_VALUE,
	);

	foreach my $victim (CP_NO_PIECE, CP_PAWN .. CP_QUEEN) {
		my $index = ($victim << 6) | ($mover << 3);
		my $value = $victim ? ($piece_values[$victim] - $mover) : 0;
		$move_values[$index] = $value;
		my $key = (CP_PIECE_CHARS->[0]->[$victim] || ' ') . CP_PIECE_CHARS->[0]->[$mover];
		if ($mover == CP_PAWN) {
			foreach my $promote (CP_KNIGHT .. CP_QUEEN) {
				$move_values[$index | $promote]
					= $value + $piece_values[$promote] - CP_PAWN_VALUE;
				my $pc = CP_PIECE_CHARS->[0]->[$promote];
				my $pvalue = $value + $piece_values[$promote] - CP_PAWN_VALUE;
			}
		}
	}
}

1;
