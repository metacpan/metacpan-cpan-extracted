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

use Time::HiRes qw(gettimeofday tv_interval);

use Chess::Plisco::Engine::TimeControl::MovesToGo;

my $log10 = log 10;

sub new {
	my ($class, $tree) = @_;

	my $self = {
		start_time => 0,
		optimum => 0,
		maximum => 0,
		tree => $tree,
	};

	bless $self, $class;
}

my $min = sub {
	my ($A, $B) = @_;

	return $A < $B ? $A : $B;
};

my $max = sub {
	my ($A, $B) = @_;

	return $A > $B ? $A : $B;
};

# Called at the beginning of the search.
sub init {
	my ($self, $limits, $us, $ply, $params, $original_time_adjust) = @_;

	$self->{start_time} = $limits->{start_time};

	my $my_time = $limits->{time}->[$us];

	return if !$my_time;

	my $move_overhead = $params->{move_overhead};
	my ($opt_scale, $max_scale);

	my $scaled_time = $my_time;

	# FIXME! This can be replaced by our empirically found numbers.
	my $centi_mtg = $limits->{movestogo} ? $min->($limits->{movestogo} * 100, 5000) : 5051;

	if ($scaled_time < 1000) {
		$centi_mtg = $scaled_time * 5.051;
	}

	my $time_left = $max->(1,
		$my_time
		+ ($limits->{inc}->[$us] * ($centi_mtg - 100) - $move_overhead * (200 + $centi_mtg)) / 100
	);

	if ($limits->{movestogo} == 0) {
		if ($$original_time_adjust < 0) {
			 $$original_time_adjust = 0.3128 * log($time_left) / $log10 - 0.4354;
		}

		my $log_time_in_sec = log($scaled_time / 1000) / $log10;
		my $opt_constant = $min->(0.0032116 + 0.000321123 * $log_time_in_sec, 0.00508017);
		my $max_constant = $max->(3.3977 + 3.03950 * $log_time_in_sec, 2.94761);

		$opt_scale = $min->(0.0121431 + ($ply + 2.94693) ** 0.461073 * $opt_constant,
							0.213035 * $my_time / $time_left)
					* $$original_time_adjust;

		$max_scale = $min->(6.67704, $max_constant + $ply / 11.9847);
	} else {
		$opt_scale =
			$min->((0.88 + $ply / 116.4) / ($centi_mtg / 100.0), 0.88 * $my_time / $time_left);
		$max_scale = 1.3 + 0.11 * ($centi_mtg / 100.0);
	}

	$self->{tree}->{optimum} = ($opt_scale * $time_left);
	$self->{tree}->{maximum} =
		$min->(0.825179 * $my_time - $move_overhead, $max_scale * $self->{tree}->{optimum}) - 10;

	if ($params->{ponder}) {
		$self->{tree}->{optimum} += $self->{optimum} >> 2;
	}
}

sub elapsed {
	my ($self) = @_;

	return 1000 * tv_interval($self->{start_time});
}

sub movesToGo {
	my ($self) = @_;

	my $position = $self->{__tree}->{position};
	my $score = abs($position->evaluate);

	my $mtg = Chess::Plisco::Engine::TimeControl::MovesToGo::MOVES_TO_GO->[$score]
		// 10;

	return $mtg;
}

1;
