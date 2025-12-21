#! /usr/bin/env perl

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;
use integer;

use Test::More;

use Chess::Plisco::Engine;

sub parse_info;
sub parse_bestmove;

my $engine = Chess::Plisco::Engine->new;

ok $engine, 'engine initialised';

# Get engine output.
my $engine_output = '';
open my $fh, '>', \$engine_output;
$engine->{__out} = $fh;

# And fake a watcher;
$engine->{__watcher} = MyWatcher->new;

# Flow 1:
#
# > position startpos
# > go wtime 2000 btime 2000 winc 100 binc 100
# < info time 105
# < bestmove g1f3 ponder d7d5
# > position startpos moves g1f3 d7d5
# > go wtime 1985 btime 1900 winc 100 binc 100
#
# The engine is now expected to measure a move overhead of 10. It has used 
# 105 ms. Without move overhead, the next time left would 2000 - 105 + 100
# = 1995 but it got only 1985 because of the move overhead.
#
# Flow2:
#
# With pondering, things get more complicated.
# > position startpos
# > go wtime 2000 btime 2000 winc 100 binc 100
# < info time 105
# > go ponder wtime 2097 btime 2000 winc 100 binc 100
# > ponderhit
#
# The GUI has sent calculated a move overhead of 3. 

$engine->__onUciInput('position startpos');
ok !$engine->{__continued}, 'engine sees new game';

$engine->__onUciInput('go wtime 2000 btime 2000 winc 100 binc 100');

my @lines = split /\n/, $engine_output;
$engine_output = '';
ok @lines >= 2, 'engine has output';

my %result = parse_bestmove $lines[-1];
ok %result, 'engine completed search';
ok $result{bestmove}, 'engine found best move';
ok $result{ponder}, 'engine found ponder move';

my %info = parse_info $lines[-2];
ok %info, 'engine sent info line';
ok $info{time}, 'engine sent time';

$engine->__onUciInput("position startpos moves $result{bestmove} $result{ponder}");
my $time_left = 2000 + 100 - $info{time} - 27;
$engine->__onUciInput("go wtime $time_left btime 1900 winc 100 binc 100");
ok $engine->{__continued}, 'engine detected continuation';

ok @{$engine->{__move_overheads}}, 'engine measured move overhead';
ok $engine->{__move_overheads}->[0] >= 27, 'engine measured move overhead correctly';

done_testing;

sub parse_bestmove {
	my ($line) = @_;

	my $move_re = '[a-h][1-8][a-h][1-8][qrbn]?';
	if ($line =~ /^bestmove ($move_re) ponder ($move_re)$/) {
		return bestmove => $1, ponder => $2;
	}
}

sub parse_info {
	my ($line) = @_;

	my @tokens = split ' ', $line;
	return if 'info' ne shift @tokens;

	my %info;
	while (@tokens) {
		my $type = shift @tokens;
		return if !@tokens;

		if ($type eq 'pv') {
			$info{pv} = join ' ', @tokens;
			undef @tokens;
		} elsif ($type eq 'score') {
			# Ignore!
			next;
		} else {
			my $value = shift @tokens;
			$info{$type} = $value;
		}
	}
	return %info;
}

package MyWatcher;

sub new {
	bless {}, shift;
}

sub setBatchMode {}

sub check {}
