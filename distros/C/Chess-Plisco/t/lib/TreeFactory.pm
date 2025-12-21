#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package TreeFactory;

use strict;

use Test::More;

use Time::HiRes qw(gettimeofday);

use Chess::Plisco::EPD;
use Chess::Plisco::Engine::Tree;
use Chess::Plisco::Engine::Position;
use Chess::Plisco::Engine::TranspositionTable;
use Chess::Plisco::Engine::TimeControl;
use Chess::Plisco::Engine::LimitsType;

sub new {
	my ($class, %args) = @_;

	my $watcher = DummyWatcher->new,
	my $position = Chess::Plisco::Engine::Position->new($args{fen})
		or die "invalid or illegal fen '$args{fen}'";
	my $moves = $args{moves} || [];
	my @signatures = ($position->signature);
	foreach my $san (@$moves) {
		my $move = $position->applyMove($san)
			or die "invalid or illegal move '$san'";
		push @signatures, $position->signature;
	}

	my $info = $args{info} || sub {};
	my $tt = $args{tt} || Chess::Plisco::Engine::TranspositionTable->new(16);
	my $tree = Chess::Plisco::Engine::Tree->new(
		position => $position->copy,
		tt => $tt,
		watcher => $watcher,
		info => $info,
		signatures => \@signatures,
	);
	if ($args{mate}) {
		$tree->{max_depth} = 2 * $args{mate} - 1;
	} elsif ($args{depth}) {
		$tree->{max_depth} = $args{depth};
	}

	my $tc = Chess::Plisco::Engine::TimeControl->new($tree);

	my $limits = Chess::Plisco::Engine::LimitsType->new;
	$limits->{time}->[0] = $args{wtime};
	$limits->{time}->[1] = $args{btime};
	$limits->{inc}->[0] = $args{winc};
	$limits->{inc}->[1] = $args{binc};
	$limits->{start_time} = [gettimeofday];
	$limits->{movestogo} = $args{movestogo};
	$limits->{depth} = $args{depth};
	$limits->{infinite} = $args{infinite};
	$limits->{ponder} = $args{ponder};
	$limits->{nodes} = $args{nodes};
	$limits->{mate} = $args{mate};

	my %params;
	$params{move_overhead} = 10;
	$params{ponder} = $args{ponder};

	my $tc = Chess::Plisco::Engine::TimeControl->new($tree);
	my $original_time_adjust = -1;
	$tc->init($limits, $position->turn, $position->halfmoves + 1, \%params, $original_time_adjust);

	bless {
		__tree => $tree,
		__position => $position,
	}, $class;
}

sub tree {
	shift->{__tree};
}

sub position {
	shift->{__position};
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
