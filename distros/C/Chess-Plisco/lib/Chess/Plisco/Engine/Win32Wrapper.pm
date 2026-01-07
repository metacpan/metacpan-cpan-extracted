#! /bin/false

# Copyright (C) 2021-2026 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Make Dist::Zilla happy.
# ABSTRACT: Analyze chess games in PGN format

package Chess::Plisco::Engine::TimeControl;
$Chess::Plisco::Engine::TimeControl::VERSION = 'v1.0.2';
use strict;

use Time::HiRes qw(gettimeofday);

sub new {
	my ($class, $tree, %params) = @_;

	my $black_to_move = $tree->{position}->toMove;

	my $self = {
		__tree => $tree,
	};
	bless $self, $class;

	if ($black_to_move) {
		$params{mytime} = delete $params{btime};
		$params{myinc} = delete $params{binc};
		$params{hertime} = delete $params{wtime};
		$params{herinc} = delete $params{winc};
	} else {
		$params{mytime} = delete $params{wtime};
		$params{myinc} = delete $params{winc};
		$params{hertime} = delete $params{btime};
		$params{herinc} = delete $params{binc};
	}

	if ($params{mate}) {
		$params{depth} = 2 * $params{mate} - 1;
	}

	if ($params{depth}) {
		$tree->{max_depth} = $params{depth};
	} else {
		# Think for 5 seconds by default.
		$tree->{allocated_time} = 5000;
		delete $tree->{max_depth};
	}

	# Initial value for calibration.
	$tree->{nodes_to_tc} = 1000;

	if ($params{movetime}) {
		$tree->{allocated_time} = $params{movetime};
		$tree->{fixed_time} = 1;
	} elsif ($params{infinite}) {
		$tree->{max_depth} = Plisco::Engine::Tree->MAX_PLY;
	} elsif ($params{nodes}) {
		$tree->{max_nodes} = $params{nodes};
	} elsif ($params{mytime}) {
		$self->allocateTime($tree, \%params);
	}

	if ($params{searchmoves}) {
		$tree->{searchmoves} = $params{searchmoves};
	}

	$tree->{start_time} = [gettimeofday];

	bless $self, $class;
}

sub allocateTime {
	my ($self, $tree, $params) = @_;

	# First get a rough estimate of the moves to go.
	my $mtg = $self->movesToGo;

	if ($params->{movestogo} && $params->{movestogo} < $mtg) {
		$mtg = $params->{movestogo};
	}

	my $time_left = $params->{mytime} + $params->{movestogo} * $params->{myinc};

	# FIXME! This should not be fixed_time but have a better name.
	# FIXME! Depending on the volatility of the position, there should be
	# a time cushion that can be used if the evaluation changes a lot between      
	# iterations.
	$tree->{allocated_time} = int (0.5 + $time_left / $mtg);
}

sub movesToGo {
	my ($self) = @_;

	# FIXME! These parameters should be configurable and their defaults
	# should be tuned!
	my $min_moves_remaining = 20;
	my $max_moves_remaining = 60;
	my $moves_range = $max_moves_remaining - $min_moves_remaining;

	# We make two very simple assumptions.  The popcount of the weaker
	# party decreases in the course of the game from 16 to 1.  That
	# allows us a linear interpolation for the number of moves to go.
	# On the other hand, the material imbalance may change from 0
	# to 9 queens (81 for our purposes).  But an imbalance of 10
	# (one queen plus a pawn) should guaranty a trivial win for the side
	# to move and we can limit the material imbalance to that.
	#
	# And then we simply give each a result a weight with the two results
	# summing up to 1.0.
	my $popcount_weight = 0.75;
	my $material_weight = (1 - $popcount_weight);

	my $pos = $self->{__tree}->{position};
	my $wpopcount = $pos->bitboardPopcount($pos->whitePieces);
	my $bpopcount = $pos->bitboardPopcount($pos->blackPieces);
	my $material = $pos->material;

	my $popcount = $wpopcount < $bpopcount ? $wpopcount : $bpopcount;

	# Popcount slope and constant offset.
	my $mpc = my $moves_range / (16 - 1);
	my $cpc = $min_moves_remaining - $mpc;

	# Material imbalance slope and constant offset.
	my $mmc = -$moves_range / 10 - 0;
	my $cmc = $max_moves_remaining;

	# FIXME! Since this is only done once per ply, a full evaluation of
	# the position should be done instead of just looking at the material
	# balance.
    my $mtg = $popcount_weight * ($mpc * $popcount + $cpc)
			 + $material_weight * ($mmc * $material + $cmc);

	return $mtg;
}

1;
