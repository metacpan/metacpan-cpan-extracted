#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::Tree;
$Chess::Plisco::Engine::Tree::VERSION = 'v1.0.1';
use strict;
use integer;

use Locale::TextDomain ('Chess-Plisco');

use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!
use Chess::Plisco::Engine::Position qw(CP_POS_REVERSIBLE_CLOCK);

use Time::HiRes qw(tv_interval);

use constant DEBUG => $ENV{DEBUG_PLISCO_TREE};

use constant CP_POS_SIGNATURE => Chess::Plisco::Engine::Position::CP_POS_SIGNATURE();
use constant CP_POS_REVERSIBLE_CLOCK => Chess::Plisco::Engine::Position::CP_POS_REVERSIBLE_CLOCK();

use constant MATE => -15000;
use constant INF => 16383;
use constant MAX_PLY => 512;
use constant DRAW => 0;

use Chess::Plisco::Engine::TranspositionTable;

# These values get stored in the upper 32 bits of a moves so that they are
# searched first.
use constant MOVE_ORDERING_PV => 1 << 62;
use constant MOVE_ORDERING_TT => 1 << 61;

use constant ASPIRATION_WINDOW => 25;
use constant SAFETY_MARGIN => 50;

# For all combinations of promotion piece and captured piece, calculate a
# value suitable for sorting.  We choose the raw material balance minus the
# piece that moves.  That way, captures that the queen makes are less
# "attractive" than captures that the rook makes.
my @move_values = (0) x 369;


# MVV-LVA values. Looked up via the captured and moving piece ($move & 0x3f).
my @mvv_lva;

# Usually only queen promotions and sometimes promotions to a knight are
# interesting. This mask is used to filter them out.
use constant GOOD_PROMO_MASK => (1 << (CP_QUEEN)) | (1 << (CP_KNIGHT));

sub new {
	my ($class, %options) = @_;

	my $position = $options{position};
	my $signatures = $options{signatures};

	# Make sure that the reversible clock does not look beyond the known
	# positions.  This will simplify the detection of a draw by repetition.
	if ($position->[CP_POS_REVERSIBLE_CLOCK] >= @$signatures) {
		$position->[CP_POS_REVERSIBLE_CLOCK] = @$signatures - 1;
	}

	no integer;

	my @killers = map { [] } 0 .. MAX_PLY - 1;
	my $self = {
		position => $position,
		signatures => $signatures,
		history_length => -1 + scalar @$signatures,
		tt => $options{tt},
		watcher => $options{watcher},
		info => $options{info} || sub {},
		book => $options{book},
		book_depth => $options{book_depth},
		killers => \@killers,
		cutoff_moves => [[], []], # History heuristic, one slot for each side.
		average_score => -INF,
		previous_average_score => INF,
		iter_scores => [],
		previous_time_reduction => 0.85,
		move_efforts => {},
		total_best_move_changes => 0,
	};

	bless $self, $class;
}

sub checkTime {
	my ($self) = @_;

	no integer;

	# Remember whether we are currently pondering. If a "ponderhit" was
	# returned, the engine object will reset the ponder flag and also reset
	# the start time to now.  If that happens, we should skip this
	# recalibration of the nodes to the next time control because the ETA will
	# be zero or close to 0.
	my $was_ponder = $self->{ponder};

	# It is important to check for input before checking the time control. If
	# another "go" command has been received, the engine object will request
	# us to stop immediately.  When this search terminates, the engine will
	# immediately resume with the next search.
	$self->{watcher}->check($self);
	if ($self->{stop_requested}) {
		die "PLISCO_ABORTED\n";
	}

	my $elapsed = 1000 * tv_interval($self->{start_time});

	# Taken from Stockfish: Start printing the current move after 0.5 s.
	# Otherwise the output is getting messy in the beginning.  Stockfish is
	# using 3 s but we are slower.
	if ($elapsed > 500) {
		$self->{print_current_move} = 1;
	}

	my $nodes = $self->{nodes};

	# FIXME! It is probably better to look at the current nps, not the
	# overall nps.
	my $nps = $elapsed ? (1000 * $nodes / $elapsed) : 10000;

	my $max_nodes_to_tc = $nps >> 2;

	if ($self->{ponder}) {
		# We have to be quick enough to stop.  On the other hand, pondering
		# is not effective, if we invoke the time control function too often.
		$self->{nodes_to_tc} = $nodes + $nps >> 4;
	} elsif ($self->{max_depth}) {
		$self->{nodes_to_tc} = $nodes + $max_nodes_to_tc;
	} elsif ($self->{max_nodes}) {
		if ($nodes + $max_nodes_to_tc < $self->{max_nodes}) {
			$self->{nodes_to_tc} = $nodes + $max_nodes_to_tc;
		} else {
			$self->{nodes_to_tc} = $self->{max_nodes};
		}
	} else {
		use integer;

		my $allocated = $self->{maximum};
		my $eta = $allocated - $elapsed;
		if ($eta < SAFETY_MARGIN) {
			die "PLISCO_ABORTED\n";
		}

		# How many nodes should we check until the next time control?
		# We want to roughly do at least 4 time checks per second to keep the
		# application responsive.
		my $max_nodes = $nps >> 2;

		# Re-calibrate the number of nodes to the next time control.
		#
		# But do not do this when the uci engine object has just received
		# a "ponderhit" command. It has then reset our start time to the
		# current time and has removed the ponder flag. That is why we have
		# remembered it at the start of this routine.
		#
		# If we have less than about one second left, we gradually reduce
		# the batch size so that we do not overuse the allocated time.
		#
		# We can expect to process $eta * $nps / 1000 nodes in the remaining
		# time. In order to play safe, should the performance suddenly drop,
		# we divide that number by 8. A division by 1000 is roughly a
		# right shift of 10, a division by 4 a right-shift by 2. We can
		# therefore just right-shift the product by 13.
		if (!($was_ponder && !$self->{ponder})) {
			my $dyn_nodes = ($eta * $nps) >> 13;

			my $nodes_to_go = ($max_nodes < $dyn_nodes) ? $max_nodes : $dyn_nodes;
			$self->{nodes_to_tc} = $nodes + $nodes_to_go;
		}
	}
}

sub debug {
	my ($self, $msg) = @_;

	chomp $msg;
	print STDERR "DEBUG $msg\n";

	return 1;
}

sub indent {
	my ($self, $ply, $msg) = @_;

	chomp $msg;
	my $indent = '..' x ($ply - 1);
	$self->debug("[$ply/$self->{depth}] $indent$msg");
}

sub printPV {
	my ($self, $pline) = @_;

	no integer;
	my $position = $self->{start};
	my $score = $self->{score};
	my $mate_in;
	if ($score >= -(MATE + MAX_PLY)) {
		$mate_in = (1 - (MATE + $score)) >> 1;
	} elsif ($score <= (MATE + MAX_PLY)) {
		use integer;
		$mate_in = (MATE - $score) >> 1;
	}

	my $nodes = $self->{nodes};
	my $elapsed = tv_interval($self->{start_time});
	my $nps = $elapsed ? (int(0.5 + $nodes / $elapsed)) : 0;
	my $scorestr = $mate_in ? "mate $mate_in" : "cp $score";
	my $pv = join ' ', $position->movesCoordinateNotation(@$pline);
	my $time = int(0.5 + (1000 * $elapsed));
	$self->{info}->("depth $self->{depth} seldepth $self->{seldepth}"
			. " score $scorestr nodes $nodes nps $nps time $time pv $pv");
	if ($self->{__debug}) {
		$self->{info}->("tt_hits $self->{tt_hits}") if $self->{__debug};
	}
}

sub quiesce; # Make it invokable without a method call.


sub alphabeta {
	my ($self, $ply, $depth, $alpha, $beta, $pline) = @_;

	if ($self->{nodes} >= $self->{nodes_to_tc}) {
		$self->checkTime;
	}

	my $position = $self->{position};

	if (DEBUG) {
		my $hex_signature = sprintf '%016x', $position->signature;
		my $line = join ' ', @{$self->{line}};
		my $fen = $position->toFEN;
		$self->indent($ply, "alphabeta: alpha = $alpha, beta = $beta, line: $line,"
			. " depth: $depth, sig: $hex_signature $fen");
	}

	if ($position->[CP_POS_HALFMOVE_CLOCK] >= 100) {
		if (DEBUG) {
			$self->indent($ply, "draw detected");
		}
		return DRAW;
	}

	# Check draw by repetition.  FIXME! Try to find near repetitions with
	# cuckoo tables.
	#
	# We know that the reversible clock is never pointing beyond the known
	# positions/signatures because that gets adjusted in the constructor.
	my $signatures = $self->{signatures};
	my $signature = $position->[CP_POS_SIGNATURE];
	if ($ply > 1) {
		my $rc = $position->[CP_POS_REVERSIBLE_CLOCK];
		my $history_length = $self->{history_length};
		my $signature_slot = $history_length + $ply;
		my $max_back = $signature_slot - $rc - 1;
		for (my $n = $signature_slot - 5; $n >= $max_back; $n -= 2) {
			if ($signatures->[$n] == $signature) {
				if (DEBUG) {
					$self->indent($ply, "3-fold repetition");
				}
				return DRAW;
			}
		}
	}

	my $tt = $self->{tt};
	my $tt_move;
	if (DEBUG) {
		my $hex_sig = sprintf '%016x', $signature;
		$self->indent($ply, "TT probe $hex_sig \@depth $depth, alpha = $alpha, beta = $beta");
	}
	my $tt_value = $tt->probe($signature, $ply, $depth, $alpha, $beta, \$tt_move);

	if (DEBUG) {
		if ($tt_move) {
			my $cn = $position->moveCoordinateNotation($tt_move);
			$self->indent($ply, "best move: $cn");
		}
	}
	if (defined $tt_value) {
		++$self->{tt_hits};
		if ($tt_move && $ply == 1) {
			@$pline = ($tt_move);
			$self->{score} = $tt_value;
		}

		if (DEBUG) {
			my $hex_sig = sprintf '%016x', $signature;
			my $cn = $position->moveCoordinateNotation($tt_move);
			$self->indent($ply, "TT hit for $hex_sig, value $tt_value, best move $cn");
		}
		return $tt_value;
	}

	if ($depth <= 0) {
		return quiesce($self, $ply, $alpha, $beta);
	}

	my @moves = $position->pseudoLegalMoves;

	# Sort moves. FIXME!!!! Bad captures must be searched *after* the
	# quiet moves.
	my $pv_move;
	$pv_move = $pline->[$ply - 1] if @$pline >= $ply;
	my (@pv, @tt, @promotions, @checks, @good_captures, @k1, @k2, @k3, @quiet, @bad_captures);
	my $killers = $self->{killers}->[$ply];
	my $k1 = $killers->[0];
	my $k2 = $killers->[1];
	my $k3 = $ply > 1 ? $self->{killers}->[$ply - 2]->[0] : 0;
	if ($depth >= 5) {
		# Full sorting.
		my %good_captures;
		foreach my $move (@moves) {
			if (((($move) & 0x1fffc0) == (($pv_move) & 0x1fffc0))) {
				push @pv, $move;
			} elsif (((($move) & 0x1fffc0) == (($tt_move) & 0x1fffc0))) {
				push @tt, $move;
			} elsif (my $promote = ((($move) >> 6) & 0x7)) {
				if ((GOOD_PROMO_MASK >> $promote) & 1) {
					push @promotions, $move;
				} else {
					push @quiet, $move;
				}
			} elsif ($position->moveGivesCheck($move)) {
				push @checks, $move;
			} elsif (((($move) >> 3) & 0x7)) {
				my $see = $position->SEE($move);
				if ($see >= 0) {
					$good_captures{$move} = $position->SEE($move);
				} else {
					push @bad_captures, $move;
				}
			} elsif ($move == $k1) {
				$k1[0] = $move;
			} elsif ($move == $k2) {
				$k2[0] = $move;
			} elsif ($move == $k3) {
				$k3[0] = $move;
			} else {
				push @quiet, $move;
			}
		}
		@good_captures = sort { $good_captures{$b} <=> $good_captures{$a} } keys %good_captures;
		@bad_captures = sort { $mvv_lva[$b] <=> $mvv_lva[$a] } @bad_captures;
	} elsif ($depth >= 4) {
		# Light sorting.
		my %good_captures;
		foreach my $move (@moves) {
			if (((($move) & 0x1fffc0) == (($pv_move) & 0x1fffc0))) {
				push @pv, $move;
			} elsif (((($move) & 0x1fffc0) == (($tt_move) & 0x1fffc0))) {
				push @tt, $move;
			} elsif (my $promote = ((($move) >> 6) & 0x7)) {
				if ((GOOD_PROMO_MASK >> $promote) & 1) {
					push @promotions, $move;
				} else {
					push @quiet, $move;
				}
			} elsif (((($move) >> 3) & 0x7)) {
				my $see = $position->SEE($move);
				if ($see >= 0) {
					$good_captures{$move} = $position->SEE($move);
				} else {
					push @bad_captures, $move;
				}
			} elsif ($move == $k1) {
				$k1[0] = $move;
			} elsif ($move == $k2) {
				$k2[0] = $move;
			} elsif ($move == $k3) {
				$k3[0] = $move;
			} else {
				push @quiet, $move;
			}
		}
		@good_captures = sort { $good_captures{$b} <=> $good_captures{$a} } keys %good_captures;
		@bad_captures = sort { $mvv_lva[$b] <=> $mvv_lva[$a] } @bad_captures;
	} else {
		# Minimal sorting.
		foreach my $move (@moves) {
			if (((($move) & 0x1fffc0) == (($pv_move) & 0x1fffc0))) {
				push @pv, $move;
			} elsif (((($move) & 0x1fffc0) == (($tt_move) & 0x1fffc0))) {
				push @tt, $move;
			} elsif (my $promote = ((($move) >> 6) & 0x7)) {
				if ((GOOD_PROMO_MASK >> $promote) & 1) {
					push @promotions, $move;
				} else {
					push @quiet, $move;
				}
			} elsif (((($move) >> 3) & 0x7)) {
				push @good_captures, $move;
			} elsif ($move == $k1) {
				$k1[0] = $move;
			} elsif ($move == $k2) {
				$k2[0] = $move;
			} elsif ($move == $k3) {
				$k3[0] = $move;
			} else {
				push @quiet, $move;
			}
		}
		@good_captures = sort { $mvv_lva[$b & 0x3f] <=> $mvv_lva[$a & 0x3f] } @good_captures;
	}

	# Apply history bonus and malus to all quiet moves. We store the bonuses
	# in the upper 32 bits so that we can do a simple integer sort.
	my $cutoff_moves = $self->{cutoff_moves}->[$position->[CP_POS_TO_MOVE]];
	foreach my $move (@quiet) {
		$move |= (($cutoff_moves->[($move & 0x1ffe00) >> 9]) << 32);
	}
	@quiet = sort { $b <=> $a } @quiet;

	@moves = (@pv, @tt, @promotions, @checks, @good_captures, @k1, @k2, @k3, @quiet, @bad_captures);

	my $legal = 0;
	my $moveno = 0;
	my $pv_found;
	my $is_null_window = $beta - $alpha == 1;
	my $tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_ALPHA();
	my $best_move = 0;
	my $print_current_move = $ply == 1 && $self->{print_current_move};
	my $signature_slot = $self->{history_length} + $ply;
	my @check_info = $position->inCheck;
	my @backup = @$position;
	my $best_value = -INF;
	foreach my $move (@moves) {
		next if !$position->checkPseudoLegalMove($move, @check_info);
		my @line;
		$position->move($move, 1);
		$signatures->[$signature_slot] = $position->[CP_POS_SIGNATURE];
		my $nodes_before = $self->{nodes}++;
		$self->printCurrentMove($depth, $move, $legal) if $print_current_move;
		my $score;
		if (DEBUG) {
			my $cn = $position->moveCoordinateNotation($move);
			$self->indent($ply, "move $cn: start search");
			push @{$self->{line}}, $cn;
		}
		if ($pv_found) {
			if (DEBUG) {
				$self->indent($ply, "null window search");
			}
			$score = -alphabeta($self, $ply + 1, $depth - 1, -$alpha - 1, -$alpha, \@line);
			if (($score > $alpha) && ($score < $beta)) {
				if (DEBUG) {
					$self->indent($ply, "value $score outside null window, re-search");
				}
				undef @line;
				$score = -alphabeta($self, $ply + 1, $depth - 1, -$beta, -$alpha, \@line);
			}
		} else {
			if (DEBUG) {
				$self->indent($ply, "recurse normal search");
			}
			$score = -alphabeta($self, $ply + 1, $depth - 1, -$beta, -$alpha, \@line);
		}
		++$legal;
		++$moveno;
		if (DEBUG) {
			my $cn = $position->moveCoordinateNotation($move);
			$self->indent($ply, "move $cn: value $score");
		}
		@$position = @backup;
		if (DEBUG) {
			pop @{$self->{line}};
		}
		if ($ply == 1) {
			$self->{average_score} =
				$self->{average_score} != -INF ? ($score + $self->{average_score}) >> 1 : 3.75 * $score;
			$self->{move_efforts}->{$move} += $self->{nodes} - $nodes_before;
			++$self->{total_best_move_changes} if $score > $best_value && $score > $alpha && $legal > 1;
		}
		if ($score > $best_value) {
			$best_value = $score;
			$best_move = $move;
			$tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT();

			if ($score > $alpha) {
				$alpha = $score;
				$pv_found = 1;
				@$pline = ($move, @line);

				if (DEBUG) {
					$self->indent($ply, "raise alpha to $alpha");
				}
				if ($ply == 1) {
					$self->{score} = $score;
					$self->printPV($pline);
				}
			}
		}
		if ($score >= $beta) {
			if (DEBUG) {
				my $hex_sig = sprintf '%016x', $signature;
				my $cn = $position->moveCoordinateNotation($move);
				$self->indent($ply, "$cn fail high ($score >= $beta), store $score(BETA) \@depth $depth for $hex_sig");
			}
			$tt->store($signature, $depth,
				Chess::Plisco::Engine::TranspositionTable::TT_SCORE_BETA(),
				$score, $move);


			# Quiet move or bad capture failing high?
			my $first_quiet = 1 + (scalar @moves) - (scalar @quiet) - (scalar @bad_captures);
			if ($moveno >= $first_quiet && !((($move) >> 3) & 0x7)) {
				if (DEBUG) {
					my $cn = $position->moveCoordinateNotation($move);
					$self->indent($ply, "$cn is quiet and becomes new killer move");
				}

				# We also allow bad captures to be a killer move.
				my $killers = $self->{killers}->[$ply];
				($killers->[0], $killers->[1]) = ($move, $killers->[0]);

				# The history bonus should only be given to real quiet
				# moves, not bad captures. Later, when we also give
				# maluses, we still want to give the malus to all
				# previously searched quiet moves.

				# This is the from and to square as one single integer.
				my $from_to = ($move & 0x1ffe00) >> 9;

				$cutoff_moves->[$from_to] += $depth * $depth;
				if (DEBUG) {
					my $bonus = $depth * $depth;
					my $cn = $position->moveCoordinateNotation($move);
					$self->indent($ply, "$cn is quiet and gets history bonus $bonus");
				}
			}

			return $best_value;
		}
	}

	my $hash_value = $best_value;
	if (!$legal) {
		# Mate or stalemate.
		if (!$position->inCheck) {
			$hash_value = $best_value = DRAW;
		} else {
			$hash_value = MATE;
			$best_value = MATE + $ply;
		}
		$tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT();

		if (DEBUG) {
			$self->indent($ply, "mate/stalemate, score: $best_value");
		}
	}

	if (DEBUG) {
		my $hex_sig = sprintf '%016x', $signature;
		if ($is_null_window && $tt_type == Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT()) {
			$self->indent($ply, "returning best value $best_value without tt store for $hex_sig");
		} else {
			my $type;
			if ($tt_type == TT_SCORE_ALPHA) {
				$type = 'ALPHA';
			} else {
				$type = 'EXACT';
			}
			$self->indent($ply, "returning best value $best_value, store ($type) \@depth $depth for $hex_sig");
		}
	}

	$tt->store($signature, $depth, $tt_type, $hash_value, $best_move)
		if !($is_null_window && $tt_type == Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT());

	return $best_value;
}

sub quiesce {
	my ($self, $ply, $alpha, $beta) = @_;

	if ($self->{nodes} >= $self->{nodes_to_tc}) {
		$self->checkTime;
	}

	$self->{seldepth} = ((($ply) > ($self->{seldepth})) ? ($ply) : ($self->{seldepth}));

	my $position = $self->{position};

	if (DEBUG) {
		my $hex_signature = sprintf '%016x', $position->signature;
		my $line = join ' ', @{$self->{line}};
		$self->indent($ply, "quiescence: alpha = $alpha, beta = $beta, line: $line,"
			. " sig: $hex_signature $position");
	}

	# Expand the search, when in check.
	if ($position->inCheck) {
		if (DEBUG) {
			$self->indent($ply, "quiescence check extension");
		}
		return alphabeta($self, $ply, 1, $alpha, $beta, []);
	}

	my $tt = $self->{tt};
	my $signature = $position->[CP_POS_SIGNATURE];
	my $tt_move;
	if (DEBUG) {
		my $hex_sig = sprintf '%016x', $signature;
		$self->indent($ply, "quiescence TT probe $hex_sig \@depth 0, alpha = $alpha, beta = $beta");
	}
	my $tt_value = $tt->probe($signature, $ply, 0, $alpha, $beta, \$tt_move);
	if (DEBUG) {
		if ($tt_move) {
			my $cn = $position->moveCoordinateNotation($tt_move);
			$self->indent($ply, "best move: $cn");
		}
	}

	if (defined $tt_value) {
		if (DEBUG) {
			my $hex_sig = sprintf '%016x', $signature;
			$self->indent($ply, "quiescence TT hit for $hex_sig, value $tt_value");
		}
		++$self->{tt_hits};
		return $tt_value;
	}

	my $is_null_window = $beta - $alpha == 1;

	my $best_value = $position->evaluate;
	if (DEBUG) {
		$self->indent($ply, "static evaluation: $best_value");
	}
	if ($best_value >= $beta) {
		if (DEBUG) {
			my $hex_sig = sprintf '%016x', $signature;
			if ($is_null_window) {
				$self->indent($ply, "quiescence standing pat ($best_value >= $beta) without tt store for $hex_sig");
			} else {
				$self->indent($ply, "quiescence standing pat ($best_value >= $beta), store $best_value(EXACT) \@depth 0 for $hex_sig");
			}
		}
		# FIXME! Is that correct?
		$tt->store($signature, 0,
			Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT(),
			$best_value, 0
		) if !$is_null_window ;

		return $best_value;
	}

	my $tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_ALPHA();
	if ($best_value > $alpha) {
		$alpha = $best_value;
		# FIXME! Correct?
		$tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT();
	}

	my @moves = $position->pseudoLegalAttacks;
	my (@tt, @promotions, @checks, %captures);
	foreach my $move (@moves) {
		if (((($move) & 0x1fffc0) == (($tt_move) & 0x1fffc0))) {
			push @tt, $move;
		} elsif ((GOOD_PROMO_MASK >> (((($move) >> 6) & 0x7))) & 1) {
			# Skip underpromotions in quiescence.
			push @promotions, $move;
		} elsif ($position->moveGivesCheck($move)) { # FIXME! Too expensive?
			push @checks, $move;
		} else {
			$captures{$move} = $position->SEE($move);
		}
	}

	my @captures = sort { $captures{$b} <=> $captures{$a} } keys %captures;
	@moves = (@tt, @promotions, @checks, @captures);

	my $signatures = $self->{signatures};
	my $signature_slot = $self->{history_length} + $ply;
	my @check_info = $position->inCheck;
	my @backup = @$position;

	my $legal = 0;
	my $tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_ALPHA();
	my $best_move = 0;
	foreach my $move (@moves) {
		next if !$position->checkPseudoLegalMove($move, @check_info);
		$position->move($move, 1);
		$signatures->[$signature_slot] = $position->[CP_POS_SIGNATURE];
		if (DEBUG) {
			my $cn = $position->moveCoordinateNotation($move);
			push @{$self->{line}}, $cn;
			$self->indent($ply, "move $cn: start quiescence search");
		}
		++$self->{nodes};
		++$legal;
		if (DEBUG) {
			$self->indent($ply, "recurse quiescence search");
		}
		my $score = -quiesce($self, $ply + 1, -$beta, -$alpha);
		if (DEBUG) {
			my $cn = $position->moveCoordinateNotation($move);
			$self->indent($ply, "move $cn: value: $score");
			pop @{$self->{line}};
		}
		@$position = @backup;
		if ($score >= $beta) {
			if (DEBUG) {
				my $hex_sig = sprintf '%016x', $signature;
				my $cn = $position->moveCoordinateNotation($move);
				$self->indent($ply, "$cn quiescence fail high ($score >= $beta), store $score(BETA) \@depth 0 for $hex_sig");
			}
			$tt->store($signature, 0,
				Chess::Plisco::Engine::TranspositionTable::TT_SCORE_BETA(),
				$score, $move);

			return $score;
		}
		if ($score > $best_value) {
			$best_value = $score;
			$best_move = $move;
		}
		if ($score > $alpha) {
			if (DEBUG) {
				$self->indent($ply, "raise quiescence alpha to $alpha");
			}
			$alpha = $score;
			$tt_type = Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT();
		}
	}

	if (DEBUG) {
		my $hex_sig = sprintf '%016x', $signature;
		my $type;
		if ($tt_type == TT_SCORE_ALPHA) {
			$type = 'ALPHA';
		} else {
			$type = 'EXACT';
		}
		if ($is_null_window && $tt_type == Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT()) {
			$self->indent($ply, "quiescence returning best value $best_value without tt store for $hex_sig");
		} else {
			$self->indent($ply, "quiescence returning best value $best_value, store ($type) \@depth 0 for $hex_sig");
		}
	}

	$tt->store($signature, 0, $tt_type, $best_value, $best_move)
		if !($is_null_window && $tt_type == Chess::Plisco::Engine::TranspositionTable::TT_SCORE_EXACT());

	return $best_value;
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
	my $alpha = -INF;
	my $beta = +INF;

	my $last_best_move;
	my $last_best_move_depth = 0;

	if (DEBUG) {
		my $fen = $position->toFEN;
		$self->debug("Searching $fen");
	}
	eval {
		while (++$depth <= $max_depth) {
			no integer;

			# Age out instability.
			$self->{total_best_move_changes} /= 2;

			my @lower_windows = (-50, -100, -INF);
			my @upper_windows = (50, 100, +INF);

			$self->{depth} = $depth;
			if (DEBUG) {
				$self->debug("Deepening to depth $depth");
				$self->{line} = [];
			}
			$score = $self->alphabeta(1, $depth, $alpha, $beta, \@line);
			if (DEBUG) {
				$self->debug("Score at depth $depth: $score");
			}
			if (($score >= -MATE - $depth) || ($score <= MATE + $depth)) {
				last;
			}

			if (($score <= $alpha) || ($score >= $beta)) {
				if (DEBUG) {
					$self->debug("Must re-search with infinite window.");
				}
				$alpha = $score - ASPIRATION_WINDOW;
				$beta = $score + ASPIRATION_WINDOW;
				redo;
			}

			if ($self->{use_time_management}) {
				my $iter_idx = ($depth - 1) & 3;

				no integer;

				# The constants are taken from Stockfish and they use their own units
				# which seem to be 3.5-4.0 centipawns.
				my $best_value = 3.75 * $score;

				my $falling_eval = (11.85 + 2.24 * ($self->{previous_average_score} - $best_value)
					+ 0.93 * ($self->{iter_scores}->[$iter_idx] - $best_value)) / 100.0;
				$falling_eval = ($falling_eval) < (0.57) ? (0.57) : ($falling_eval) > (1.70) ? (1.70) : ($falling_eval);
				if ($line[0] != $last_best_move) {
					$last_best_move_depth = $depth;
				}

				# Idea: Try to move the center based on the average completed
				# search depth. But the average search depth should probably
				# be aged out.
				# my $depth_scale = $self->{avg_completed_depth} / 40.0; # SF baseline
				# my $center = $last_best_move_depth + 12.15 * $depth_scale;
				my $k = 0.51; # FIXME! Lower that to 0.25?
				my $center = $last_best_move_depth + 12.15; # Divide by 4.25?

				my $time_reduction = 0.66 + 0.85 / (0.98 + exp(-$k * ($depth - $center)));
				my $reduction = (1.43 + $self->{previous_time_reduction}) / (2.28 * $time_reduction);
				my $best_move_instability = 1.02 + 2.14 * $self->{total_best_move_changes};
				my $nodes_effort = $self->{move_efforts}->{$line[0]} * 100000 / (((1) > ($self->{nodes})) ? (1) : ($self->{nodes}));

				# The original value is 93340. But we will not reach that
				# with only safe prunings.
				my $high_best_move_effort = $nodes_effort >= 30000 ? 0.76 : 1.0;

				my $total_time = $self->{optimum} * $falling_eval * $reduction
					* $best_move_instability * $high_best_move_effort;

				my $elapsed = 1000 * tv_interval($self->{start_time});

				if ($elapsed > ((($total_time) < ($self->{maximum})) ? ($total_time) : ($self->{maximum}))) {
					if (!$self->{ponder}) {
						last;
					}
				} elsif (!$self->{ponder}) {
					# Stockfish sets the threshold to half of the total time.
					# We use less.
					#
					# Current best: 0.25
					# Values 0.5, 0.375, 0.3125 all failed SPRTs.
					if ($elapsed > $total_time >> 2) {
						last;
					}
				}

				$self->{previous_average_score} = $self->{average_score};
				$self->{previous_time_reduction} = $time_reduction;
				$last_best_move = $line[0];
				$self->{iter_scores}->[$iter_idx] = $best_value;
			}
		}
	};
	if ($@) {
		if ($@ ne "PLISCO_ABORTED\n") {
			$self->{info}->(__"Error: exception raised: $@");
		}
	}

	if ($self->{maximum} && !$self->{ponderhit}) {
		my $elapsed = 1000 * tv_interval($self->{start_time});
		if ($elapsed > $self->{maximum}) {
			$self->{info}->(__"Error: used $elapsed ms instead of $self->{maximum} ms.");
		}
	}

	@$pline = @line;
}


sub outputMoveEfforts {
	my ($self) = @_;

	my $sum = 0;
	my $all_nodes = $self->{nodes} || 1;
	foreach my $move (sort { $self->{move_efforts}->{$b} <=> $self->{move_efforts}->{$a} } keys %{$self->{move_efforts}}) {
		my $san = $self->{position}->SAN($move);
		my $nodes = $self->{move_efforts}->{$move};
		$sum += $nodes;
		my $effort = int(0.5 + (100000 * $nodes / $all_nodes));
		$self->{info}->("Move effort $san: $effort ($nodes nodes)");
	}

	$self->{info}->("Move effort sum: $sum");
}

sub printCurrentMove {
	my ($self, $depth, $move, $moveno) = @_;

	no integer;

	my $position = $self->{position};
	my $cn = $position->moveCoordinateNotation($move);
	my $elapsed = int(1000 * tv_interval($self->{start_time}));

	$moveno += 1;
	$self->{info}->("depth $depth currmove $cn currmovenumber $moveno"
		. " time $elapsed");
}

sub think {
	my ($self) = @_;

	my $position = $self->{position};
	$self->{start} = $position->copy;
	my @legal = $position->legalMoves;
	if (!@legal) {
		$self->{info}->(__"Error: no legal moves");
		return;
	} elsif (1 == @legal) {
		my $move = $legal[0];
		$self->printCurrentMove(1, $move, 1);
		$self->printPV([$move]);
		return $move;
	}

	if ($self->{book} && $self->{history_length} < $self->{book_depth}) {
		my $notation = $self->{book}->pickMove($position);
		if ($notation) {
			my $move = eval { $position->parseMove($notation) };
			return $move if $move;
		}
	}

	my @line;

	$self->{thinking} = 1;
	$self->{tt_hits} = 0;

	if ($self->{debug}) {
		$self->{info}->("allocated time: $self->{optimum} .. $self->{maximum}");
	}

	$self->rootSearch(\@line);

	delete $self->{thinking};

	# Avoid printing the PV or the best move if the search was cancelled.
	# Otherwise, the GUI may be confused.  This can actually not happen
	# when everybody follows the convention that a "stop" is sent to
	# cancel a ponder but we reset the flag in the "stop" handler and are
	# good for both cases.
	return if $self->{cancelled};

	if (@line) {
		$self->printPV(\@line);
	} else {
		# Search has returned no move.
		$self->{info}->("Error: pick a random move because of search failure.");
		$line[0] = $legal[int rand @legal];
	}

	my $ponder_move = $self->getPonderMove(@line);

	if (defined $ponder_move) {
		return $line[0], $line[1];
	} else {
		return $line[0];
	}
}

sub getPonderMove {
	my ($self, @line) = @_;

	return if !@line;

	return $line[1] if @line > 1;

	my $pos = $self->{position}->copy;

	# Play our move.
	$pos->move($line[0]);

	# And now try to find an entry in the transposition table.
	my $signature = $pos->[CP_POS_SIGNATURE];
	my $tt = $self->{tt};
	my $tt_move;
	if (DEBUG) {
		$self->debug("probing transposition table for ponder move");
	}
	# We're not interested in the value.
	$tt->probe($signature, 1, MAX_PLY + 1, 0, 0, \$tt_move);

	if (DEBUG) {
		if ($tt_move) {
			my $cn = $pos->moveCoordinateNotation($tt_move);
			$self->debug("best move: $cn");
		}
	}

	return $tt_move if $tt_move;
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

my @mvv_lva_values = (
	0, CP_PAWN_VALUE, CP_KNIGHT_VALUE, CP_BISHOP_VALUE,
	CP_ROOK_VALUE, CP_QUEEN_VALUE, 2 * CP_QUEEN_VALUE,
);
foreach my $victim (CP_PAWN .. CP_QUEEN) {
	foreach my $attacker (CP_PAWN .. CP_KING) {
		$mvv_lva[($victim << 3) | $attacker] =
			100 * $mvv_lva_values[$victim] - $mvv_lva_values[$attacker];
		my $idx = ($victim << 3) | $attacker;
	}
}

1;
