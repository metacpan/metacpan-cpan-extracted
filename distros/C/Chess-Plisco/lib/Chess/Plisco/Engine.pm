#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine;
$Chess::Plisco::Engine::VERSION = '0.2';
use strict;
use integer;

use Chess::Position qw(:all);

use Chess::Plisco::Engine::Position;
use Chess::Plisco::Engine::TimeControl;
use Chess::Plisco::Engine::Tree;
use Chess::Plisco::Engine::InputWatcher;

sub new {
	my ($class) = @_;

	my $self = {
		__position => Chess::Plisco::Engine::Position->new,
	};
	bless $self, $class;
}

sub uci {
	my ($self, $in, $out) = @_;

	$self->{__out} = $out;
	$self->{__out}->autoflush(1);
	$self->{__watcher} = Chess::Plisco::Engine::InputWatcher->new($in);
	$self->{__watcher}->onInput(sub {
		$self->__onUciInput(@_);
	});
	$self->{__watcher}->onEof(sub {
		$self->__onEof(@_);
	});

	my $version = $Chess::Plisco::Engine::VERSION || 'development version';
	$self->__output(<<"EOF");
Welcome to Plisco $version!

This engine implements the UCI protocol (see
http://wbec-ridderkerk.nl/html/UCIProtocol.html).

Try 'help' for a list of commands!

EOF

	while (1) {
		$self->{__watcher}->check(0.01);
		last if delete $self->{__abort};
	}

	return $self;
}

sub __onEof {
	my ($self, $line) = @_;

	print STDERR "Connection to UI lost.\n";
	$self->{__tree}->{move_now} = 1 if $self->{__tree};
	$self->{__abort} = 1;

	return $self;
}

sub __onUciInput {
	my ($self, $line) = @_;

	$line = $self->__trim($line);
	return $self if !length $line;

	my ($cmd, $args) = split /[ \t]+/, $line, 2;

	my $method = '__onUciCmd' . ucfirst lc $cmd;
	$args = $self->__trim($args);
	if ($self->can($method)) {
		$self->$method($args)
	} else {
		$self->{__out}->print("info unknown command '$cmd'\n");
	}

	return $self;
}

sub __onUciCmdGo {
	my ($self, $args) = @_;

	my @args = split /[ \t]+/, $args;

	my %params;

	while (@args) {
		my $arg = lc shift @args;
		if ('searchmoves' eq $arg) {
			my @searchmoves;
			while (@args && $args[0] =~ /^[a-h][1-8][a-h][1-8][qrbn]?$/) {
				push @searchmoves, shift @args;
			}
		} elsif ('ponder' eq $arg || 'infinite' eq $arg) {
			$params{$arg} = 1;
		} elsif ('wtime' eq $arg || 'btime' eq $arg
		         || 'winc' eq $arg || 'binc' eq $arg
		         || 'movestogo' eq $arg || 'depth' eq $arg
		         || 'nodes' eq $arg || 'mate' eq $arg
		         || 'movetime' eq $arg) {
			my $val = shift @args;
			unless (defined $val && length $val) {
				$self->__info("error: argument '$arg' expects an integer > 0");
				return;
			}
			$params{$arg} = $val;
		}
	}

	my $info = sub {
		my ($msg) = @_;
		$self->__output("info $msg");
	};

	my $tree = Chess::Plisco::Engine::Tree->new($self->{__position}->copy, $info);
	my $tc = Chess::Plisco::Engine::TimeControl->new($tree, %params);

	$self->{__tree} = $tree;
	my $bestmove;
	eval {
		$bestmove = $tree->think($tree, $self->{__watcher});
		delete $self->{__tree};
	};
	if ($@) {
		$self->__output("unexpected exception: $@");
	}
	if ($bestmove) {
		my $cn = $self->{__position}->moveCoordinateNotation($bestmove);
		$self->__output("bestmove $cn");
	}

	return $self;
}

sub __onUciCmdUcinewgame {
	my ($self) = @_;

	return $self;
}

sub __onUciCmdStop {
	my ($self) = @_;

	if ($self->{__tree}) {
		die "PLISCO_ABORTED\n";
	}

	return $self;
}

sub __onUciCmdPosition {
	my ($self, $args) = @_;

	unless (defined $args && length $args) {
		$self->__info("error: usage: position FEN POSITION | startpos [MOVES...]");
		return;
	}

	my ($type, @moves) = split /[ \t]+/, $args;
	my $position;
	if ('fen' eq lc $type) {
		my $fen = shift @moves;
		unless (defined $fen && length $fen) {
			$self->__info("error: position missing after 'fen'");
			return;
		}
		while (@moves) {
			my $token = shift @moves;
			last if 'moves' eq lc $token;
			$fen .= ' ' . $token;
		}
		eval {
			$position = Chess::Plisco::Engine::Position->new($fen);
		};
		if ($@) {
			$self->__info("error: invalid FEN string: $@");
			return;
		}
	} elsif ('startpos' eq lc $type) {
		$position = Chess::Plisco::Engine::Position->new;
	} else {
		$self->__info("error: usage: position FEN POSITION | startpos moves [MOVES...]");
		return;
	}

	if ('moves' eq shift @moves) {
		foreach my $move (@moves) {
			my $status = $position->applyMove($move);
			if (!$status) {
				$self->__info("error: invalid or illegal move '$move'");
				return;
			}
		}
	}

	$self->{__position} = $position;

	return $self;
}

sub __onUciCmdHelp {
	my ($self) = @_;

	$self->__output(<<"EOF")
    The Plisco Chess Engine

    The engine understands the following commands:

        uci - switch to UCI mode (no-op)
        debug (on|off) - switch debugging on or off
        isready - ping the engine
        stop - move immediately
        help - show available commands
        quit - quit the engine immediately

    See http://wbec-ridderkerk.nl/html/UCIProtocol.html for more information!
EOF

}

sub __onUciCmdQuit {
	my ($self) = @_;

	$self->{__abort} = 1;
	if ($self->{__tree}) {
		$self->{__tree}->{aborted} = 1;
	}

	return $self;
}

sub __onUciCmdUci {
	my ($self) = @_;

	my $version = $Chess::Plisco::Engine::VERSION || 'development version';
	$self->__output("id Plisco $version");
	$self->__output("id author Guido Flohr <guido.flohr\@cantanea.com>");
	$self->__output("uciok");
}

sub __onUciCmdIsready {
	my ($self) = @_;

	$self->__output("readyok");

	return $self;
}

sub __onUciCmdDebug {
	my ($self, $onoff) = @_;

	$onoff = '' if !defined $onoff;

	if ('on' eq lc $onoff) {
		$self->{__debug} = 1;
	} elsif ('off' eq lc $onoff) {
		undef $self->{__debug};
	} else {
		$self->__info("usage debug on|off");
	}

	return $self;
}

sub __output {
	my ($self, $msg) = @_;

	chomp $msg;

	$self->{__out}->print("$msg\n");

	return $self;
}

sub __info {
	my ($self, $msg) = @_;

	return $self->__output("info $msg");
}

sub __debug {
	my ($self, $msg) = @_;

	return $self->__info("debug $msg");
}

sub __trim {
	my ($self, $what) = @_;

	$what =~ s/^[ \t]+//;
	$what =~ s/[ \t\r\n]+$//;

	return $what;
}

1;
