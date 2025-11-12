#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Tablebase::SearchTree;
$Chess::Plisco::Tablebase::SearchTree::VERSION = 'v0.7.0';
use strict;
use integer;

use Chess::Plisco qw(:all);
# Macros from Chess::Plisco::Macro are already expanded here!

use constant INF => 32767;

sub new {
	my ($class, $tb, %options) = @_;

	bless {
		__tb => $tb,
		__game_over => 0,
		__pv => [[]],
		__max_depth => 0,
		__nodes => 0,
	}, $class;
}

sub search {
	my ($self, $pos, $wdl) = @_;

	$self->{__game_over} = 0;
	$self->{__max_depth} = 0;
	$self->{__nodes} = 0;
	$self->{__wdl} = $wdl;

	while (1) {
		my @line;
		my $score = $self->negamax(1, $pos, $self->{__max_depth}, $wdl - 1, $wdl + 1, \@line);
		if ($self->{__game_over}) {
			return @line;
		}
		++$self->{__max_depth};
	}
}

sub negamax {
	my ($self, $ply, $pos, $depth, $alpha, $beta, $pline) = @_;

	++$self->{__nodes};

	my @line;

	if ($depth <= 0) {
		my $probe_value = $self->{__tb}->probeWdl($pos);
		$self->{__game_over} = $self->{__tb}->gameOver;

		return $probe_value;
	}

	foreach my $move ($pos->legalMoves) {
		my $san = $pos->SAN($move);
		my $undo = $pos->doMove($move);
		my $value = -$self->negamax($ply + 1, $pos, $depth - 1, -$beta, -$alpha, \@line);
		$pos->undoMove($undo);

		if ($value > $alpha
		    || ($self->{__game_over} && $value >= $alpha)) {
			$alpha = $value;
			@$pline = ($san, @line);

			my $colour = $pos->toMove ? 'black' : 'white';

			if ($self->{__game_over}) {
				# For black, the sign of the value and of the WDL probe must
				# differ to be a hit. We don't check for exact values because
				# we have to handle cursed wins and blessed losses.
				if ($self->{__game_over} & CP_GAME_BLACK_WINS) {
					return $alpha if $alpha * $self->{__wdl} < 0;
				} elsif ($self->{__game_over} & CP_GAME_WHITE_WINS) {
					return $alpha if $alpha * $self->{__wdl} > 0;
				} else {
					return $alpha if $alpha == 0;
				}
			}
		}

		# This must come after changing the principal variation because the
		# optimal move will also cause a beta-cutoff if another move with the
		# same outcome has already been checked.
		if ($value >= $beta) {
			return $beta;
		}
	}

	return $alpha;
}

1;
