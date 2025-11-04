#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package EPDSolver;

use strict;

use Test::More;

use Chess::Plisco::EPD;
use Chess::Plisco::Engine::Tree;
use Chess::Plisco::Engine::Position;
use Chess::Plisco::Engine::TranspositionTable;
use Chess::Plisco::Engine::TimeControl;

sub new {
	my ($class, $epdfile, $limit, %params) = @_;

	%params = (depth => 3) unless %params;

	my $epd = Chess::Plisco::EPD->new($epdfile);

	my $num_tests;
	if ($limit > 0) {
		my $num_records = scalar $epd->records;

		$num_tests = $limit > $num_records ? $num_records : $limit;
	} else {
		$num_tests = scalar $epd->records;
	}
	plan tests => $num_tests;

	my $self = bless {
		__epd => $epd,
		__filename => $epdfile,
		__watcher => DummyWatcher->new,
		__params => \%params,
		__num_tests => $num_tests,
	}, $class;
}

sub epd {
	shift->{__epd};
}

sub __solve {
	my ($self, $record, $lineno) = @_;

	my @bm = $record->operation('bm');
	my @am = $record->operation('am');
	my $id = $record->operation('id');
	my $location = "$self->{__filename}:$lineno ($id)";

	if (!(@bm || @am)) {
		die "$location: neither bm no am found";
	}

	my $position = Chess::Plisco::Engine::Position->new($record->position->toFEN);

	foreach my $san (@bm) {
		my $move = $position->parseMove($san)
			or die "$location: illegal or invalid bm '$san'.";
		$san = $position->moveCoordinateNotation($move);
	}
	foreach my $san (@am) {
		my $move = $position->parseMove($san)
			or die "$location: illegal or invalid am '$san'.";
		$san = $position->moveCoordinateNotation($move);
	}

	my $dm = $record->operation('dm');
	my %params = %{$self->{__params}};
	if ($dm) {
		$params{mate} = $dm;
	}

	my $tree = Chess::Plisco::Engine::Tree->new(
		$position,
		Chess::Plisco::Engine::TranspositionTable->new(16),
		$self->{__watcher},
		sub {},
		[$position->signature],
	);
	my $tc = Chess::Plisco::Engine::TimeControl->new($tree, %params);
	my $move = $position->moveCoordinateNotation($tree->think);
	if (@bm) {
		my $found;
		foreach my $bm (@bm) {
			if ($bm eq $move) {
				$found = 1;
				last;
			}
		}
		my $moves = '[' . (join ', ', @bm) . ']';
		ok $found, "$location: best move, $move in $moves";
	} elsif (@am) {
		my $found;
		foreach my $bm (@bm) {
			if ($bm eq $move) {
				$found = 1;
				last;
			}
		}
		my $moves = '[' . (join ', ', @am) . ']';
		ok !$found, "$location: avoid move, $move not in $moves";
	}
}

sub solve {
	my ($self) = @_;

	my @records = $self->{__epd}->records;

	my $lineno = 0;
	foreach my $record (@records) {
		last if $lineno >= $self->{__num_tests};
		$self->__solve($record, ++$lineno);
	}
}

package DummyWatcher;

use strict;

sub new {
	my ($class) = @_;

	my $self = '';

	bless \$self, $class;
}

sub check {}

1;
