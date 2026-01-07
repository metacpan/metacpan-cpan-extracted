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

package Chess::Plisco::Engine::LimitsType;
$Chess::Plisco::Engine::LimitsType::VERSION = 'v1.0.2';
use strict;

sub new {
	my ($class) = @_;

	my $self = {
		searchmoves => [],
		time => [0, 0],
		inc => [0, 0],
		movetime => 0,
		start_time => [0, 0],
		movestogo => 0,
		depth => 0,
		mate => 0,
		infinite => 0,
		nodes => 0,
		ponder => 0,
	};

	bless $self, $class;
}

sub useTimeManagement {
	my ($self) = @_;

	return $self->{time}->[0] || $self->{time}->{1};
}

1;
