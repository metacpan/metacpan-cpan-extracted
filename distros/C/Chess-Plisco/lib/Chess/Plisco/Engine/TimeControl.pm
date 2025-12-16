#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Make Dist::Zilla happy.
# ABSTRACT: Analyze chess games in PGN format

package Chess::Plisco::Engine::TimeControl;
$Chess::Plisco::Engine::TimeControl::VERSION = 'v1.0.0';
use strict;

use Time::HiRes qw(gettimeofday tv_interval);

# Macros from Chess::Plisco::Macro are already expanded here!
use Chess::Plisco::Engine::TimeControl::MovesToGo;

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
	$tree->{nodes_to_tc} = 5000;

	# The parameter "ponder" is ignored and we compute the time allocation
	# as usual but the search tree will ignore it while pondering. If the
	# opponent plays the expected move (ponder hit), the start time of the
	# tree will be reset to the current time and it goes from ponder mode into
	# normal mode and can then check the time as usual.
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

	my $mtg;
	if ($params->{movestogo} && $params->{movestogo} < $mtg) {
		$mtg = $params->{movestogo};
	} else {
		$mtg = $self->movesToGo;
	}

	my $time_left = $params->{mytime} + $mtg * $params->{myinc};

	# FIXME! Depending on the volatility of the position, there should be
	# a time cushion that can be used if the evaluation changes a lot between      
	# iterations.
	$tree->{allocated_time} = int (0.5 + $time_left / $mtg);
}

sub movesToGo {
	my ($self) = @_;

	my $position = $self->{__tree}->{position};
	my $score = abs($position->evaluate);

	my $mtg = Chess::Plisco::Engine::TimeControl::MovesToGo::MOVES_TO_GO->[$score]
		// 10;

	return $mtg;
}

sub onPonderhit {
	my ($self) = @_;

	my $tree = $self->{__tree};
	return if !delete $tree->{ponder};

	my $won_time = 1000 * tv_interval($tree->{start_time});

	# At the moment we don't know how to efficiently use the time won. Once,
	# we do a new assessment after earch search iteration, we can simply
	# redo that now. But for the time being, we can only guess and use
	# one fourth of the won time for the current position.
	if ($tree->{allocated_time}) {
		# Apply a little bit of the extra time to this search because it was
		# a little bit slower, because while pondering, we do more the time
		# controls more frequently. On the other hand, a ponderhit rather
		# indicates that the current position is not worth searching very
		# deeply.
		$tree->{allocated_time} += $won_time >> 3;
		$tree->{ponderhit} = 1; # Avoid warnings about using too much time.
	}
}

1;
