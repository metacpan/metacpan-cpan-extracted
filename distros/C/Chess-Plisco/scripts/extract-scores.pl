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
#.        perl -Ilib scripts/extract-evaluations.pl >evalutions.txt
use strict;
use v5.10;

use Chess::Plisco;
use Chess::PGN::Parse;

use constant MAX_POSITIONS => 10_000_000;
#use constant MAX_POSITIONS => 10;

sub extract_scores;

# Unfortunately, Chess::CGN::Parse cannot read from standard input but we want
# to stream so that we can read really large collections. We therefore cheat
# a little and work around the public API of the module.

my $pgn = Chess::PGN::Parse->new(undef, '');
$pgn->{fh} = \*STDIN; # Ouch! ;)

my $num_positions = 0;

my %seen;

GAME: while ($pgn->read_game) {
	$pgn->parse_game({ save_comments => 'yes' });
	my $comments = $pgn->comments;
	my @scores = extract_scores $comments or next;
	my $sans = $pgn->moves;

	my $pos = Chess::Plisco->new;
	my $moveno = 0;
	my $fen = $pos->toFEN;
	for (my $i = 0; $i < @$sans; ++$i) {
		my $move = eval { $pos->parseMove($sans->[$i]) };
		if (!$move) {
			warn "cannot parse '$sans->[$i]': $@ ($pos)\n";
			next GAME;
		}
		my $cn = $pos->moveCoordinateNotation($move);
		$pos->doMove($move);

		my $new_fen = $pos->toFEN;
		if ($seen{$new_fen}++) {
			$fen = $new_fen;
			next;
		}

		print "$fen $cn $scores[$i]\n";

		++$num_positions;
		$fen = $new_fen;

		last GAME if $num_positions > MAX_POSITIONS;
	}
}

if ($num_positions < MAX_POSITIONS) {
	warn "Warning! Found only $num_positions usable positions. Sample is too small!\n";
}

sub extract_scores {
	my ($comments) = @_;

	my @scores;
	foreach my $moveno (keys %$comments) {
		my $comment = $comments->{$moveno};
		return if $comment !~ /\[\%eval ([0-9]+\.[0-9]+|#[0-9]+)\]/;
		my $score = $1;
		return if $moveno !~ /^([0-9]+)([wb])$/;
		my $ply = ($1 - 1) * 2;
		++$ply if $2 eq 'b';
		$scores[$ply] = $score;
	}

	return @scores;
}
