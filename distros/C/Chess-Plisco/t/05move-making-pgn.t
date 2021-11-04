#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;
use File::Basename qw(dirname);
use File::Spec;

use Chess::Plisco qw(:all);

sub report_failure;
sub significant_for_repetition;

eval { require Chess::PGN::Parse };
if ($@) {
	plan skip_all => 'You have to install Chess::PGN::Parse to run these tests.';
	exit 0;
}

my $dir = dirname __FILE__;
my $pgn_file = File::Spec->catfile($dir, 'Flohr.pgn');

ok -e $pgn_file, 'Flohr.pgn exists';

ok open my $fh, '<', $pgn_file;

my $num_tests = 0;
foreach my $line (<$fh>) {
	++$num_tests if $line =~ /^\[^Event/;
}

my $pgn = Chess::PGN::Parse->new($pgn_file);
ok $pgn, 'Flohr.pgn loaded';

my $seconds_per_test = $ENV{CP_SECONDS_PER_TEST} || 10;

my $started = time;
my $done_tests = 0;
my %signatures;
GAME: while ($pgn->read_game) {
	my $pos = Chess::Plisco->new;

	$pgn->parse_game;

	my @undo_infos;
	my @fen = ($pos->toFEN);
	my @signatures = ($pos->signature);
	my @positions = ($pos->copy);

	$signatures{$pos->signature}->{significant_for_repetition $pos->toFEN} = 1;

	my $sans = $pgn->moves;

	foreach my $san (@$sans) {
		my $halfmove = 1 + @undo_infos;
		my $move = $pos->parseMove($san);
		if (!$move) {
			report_failure $pgn, $pos,
				"\ncannot parse move '$san'\n", $halfmove;
			last;
		}

		my $undo_info = $pos->doMove($move);
		if (!$undo_info) {
			report_failure $pgn, $pos,
				"\ncannot apply move '$san'\n", $halfmove;
			last;
		} else {
			ok $undo_info, "do move $san for position $pos";
		}
		push @undo_infos, $undo_info;
		my $fen = $pos->toFEN;
		push @fen, $pos->toFEN;

		my $signature = $pos->signature;
		push @signatures, $pos->signature;
		
		$signatures{$signature}->{significant_for_repetition $fen} = 1;

		my $copy_from_fen = Chess::Plisco->new($fen[-1]);
		if ($pos->signature != $copy_from_fen->signature) {
			my $sig_from_pos = $copy_from_fen->signature;
			my $sig_from_move = $pos->signature;
			report_failure $pgn, $pos,
				"\nsignatures differ after move '$san':"
				. " $sig_from_pos(from position)"
				. " != $sig_from_move(from move)\n", $halfmove;
		}
	
		push @positions, $pos->copy;
	}

	pop @fen;
	pop @signatures;
	pop @positions;

	while (@undo_infos) {
		my $undo_info = pop @undo_infos;
		$pos->undoMove($undo_info);
		my $wanted_fen = pop @fen;
		my $got_fen = $pos->toFEN;
		my $halfmove = 1 + @undo_infos;
		if ($wanted_fen ne $got_fen) {
			report_failure $pgn, $pos,
				"\nwanted FEN: '$wanted_fen'\n   got FEN: '$got_fen'\n", $halfmove;
		} else {
			ok 1;
		}
		my $wanted_signature = pop @signatures;
		my $got_signature = $pos->signature;
		if ($wanted_signature ne $got_signature) {
			report_failure $pgn, $pos,
				"\nwanted signature: '$wanted_signature'\n   got signature: '$got_signature'\n", $halfmove;
		} else {
			ok 1;
		}
		my $wanted_position = pop @positions;
		if (!$pos->equals($wanted_position)) {
			report_failure $pgn, $pos,
				"\nwanted position: '$wanted_position'\n   got position: '$pos'\n", $halfmove;
		} else {
			ok 1;
		}
		--$halfmove;
	}

	if (time - $started > $seconds_per_test) {
		last;
	}
}

my @collisions;
foreach my $signature (keys %signatures) {
	my $positions = $signatures{$signature};
	++$collisions[-1 + keys %$positions];
}

is((scalar @collisions), 1, "no Zobrist key collisions in test set");

done_testing;

sub report_failure {
	my ($pgn, $pos, $reason, $halfmove) = @_;

	my $tags = $pgn->tags;

	my $location = '';
	if (defined $halfmove) {
		my $moves = $pgn->moves;
		my $move = $moves->[$halfmove - 1];
		my $moveno = 1 + $halfmove >> 1;
		my $fill = $halfmove & 1 ? '' : '...';
		$location = "\n$moveno. $fill$move"
	}
	chomp $reason;

	my $fen = $pos->toFEN;

	diag <<EOF;
Test failed at '$pgn_file':
	[White "$tags->{White}"]
	[Black "$tags->{Black}"]
	[Event "$tags->{Event}"]
	[Date "$tags->{Date}"]$location
FEN: $fen
Reason: $reason
EOF

	diag $pos->dumpInfo;
	diag $pos->dumpAll;

	ok 0, 'see above';
	ok $pos->consistent;

	exit 1;
}

sub significant_for_repetition {
	my ($fen) = @_;

	$fen =~ s/[0-9]+ [0-9]+$//;

	return $fen;
}
