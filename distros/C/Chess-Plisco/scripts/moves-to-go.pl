#! /usr/bin/env perl

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Read a PGN archive and read all games with players with a minimal rating.
# For every position in the game, get the evaluation and write it out as
# a CSV. That CSV file can then be used to interpolate the number of moves
# to go as a function of the absolute value of the evaluation.  The assumption
# is that the higher the evaluation, the lesser the number of moves to go.

# Use like this:
#
#     zstd -d -c ~/Downloads/lichess_db_standard_rated_2025-09.pgn.zst | \
#.        perl -Ilib scripts/moves-to-go.pl >stats.csv
use strict;
use v5.10;

use Chess::Plisco::Engine::Position;
use Chess::PGN::Parse;
use Statistics::Basic qw(median);

use constant MIN_ELO => 2000;
use constant MAX_POSITIONS => 1_000_000;

sub store_value;
sub get_evaluation;

# Unfortunately, Chess::CGN::Parse cannot read from standard input but we want
# to stream so that we can read really large collections. We therefore cheat
# a little and work around the public API of the module.

my $pgn = Chess::PGN::Parse->new(undef, '');
$pgn->{fh} = \*STDIN; # Ouch! ;)

my $startpos = Chess::Plisco::Engine::Position->new;
my $startval = $startpos->evaluate; # Always the same.

my @moves_to_go;
my $num_positions = 0;

while ($pgn->read_game) {
	# Ignore draws.
	next if (($pgn->result ne '1-0') && ($pgn->result ne '0-1'));

	my $white_elo = $pgn->tags->{WhiteElo};
	next if MIN_ELO > $white_elo;
	my $black_elo = $pgn->tags->{BlackElo};
	next if MIN_ELO > $black_elo;

	$pgn->parse_game;
	my $sans = $pgn->moves;

	my $pos = Chess::Plisco::Engine::Position->new;
	my $plies_to_go = @$sans;
	my $moves_to_go = (1 + $plies_to_go) >> 1;
	store_value \@moves_to_go, $startval, $moves_to_go;
	last if ++$num_positions >= MAX_POSITIONS;

	foreach my $san (@$sans) {
		my $move = eval { $pos->parseMove($san) };
		if (!$move) {
			warn "cannot parse '$san': $@ ($pos)\n";
			next;
		}
		$pos->doMove($move);

		my $value = abs $pos->evaluate;
		$moves_to_go = (1 + $plies_to_go) >> 1;
		store_value \@moves_to_go, $value, $moves_to_go;
		++$num_positions;
		last if $num_positions >= MAX_POSITIONS;

		--$plies_to_go;
	}
	#warn "done $num_positions/@{[MAX_POSITIONS]}\n";
}

if ($num_positions < MAX_POSITIONS) {
	warn "Warning! Found only $num_positions usable positions. Sample is too small!\n";
}
say "Evaluation,MovesToGoMedian";

foreach my $value (0 .. $#moves_to_go) {
	my $values = $moves_to_go[$value] or next;
	my $median = median @$values;

	say "$value,$median"
}

sub store_value {
	my ($values, $value, $moves_to_go) = @_;

	$values->[$value] ||= [];
	push @{$values->[$value]}, $moves_to_go;

	return 1;
}

sub get_evaluation {
	my ($pos) = @_;

	my $score = $pos->evaluate($pos);

	return (cp_pos_to_move($pos)) ? -$score : $score;
}