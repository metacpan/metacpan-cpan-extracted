#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine;
$Chess::Plisco::Engine::VERSION = 'v1.0.1';
use strict;
use integer;

use POSIX qw(:sys_wait_h);
use Locale::TextDomain qw(Chess-Plisco);
use Time::HiRes qw(gettimeofday tv_interval);

use Chess::Plisco qw(:all);

use Chess::Plisco::Engine::Position;
use Chess::Plisco::Engine::TimeControl;
use Chess::Plisco::Engine::Tree;
use Chess::Plisco::Engine::InputWatcher;
use Chess::Plisco::Engine::TranspositionTable;
use Chess::Plisco::Engine::Book;
use Chess::Plisco::Engine::LimitsType;

# These figures are taken from 
use constant MIN_HASH_SIZE => 1;
use constant DEFAULT_HASH_SIZE => 16;
use constant MAX_HASH_SIZE => 33554432;

use constant UCI_OPTIONS => [
	{
		name => 'Hash',
		type => 'spin',
		default => DEFAULT_HASH_SIZE,
		min => MIN_HASH_SIZE,
		max => MAX_HASH_SIZE,
		callback => '__resizeTranspositionTable',
	},
	{
		name => 'Clear Hash',
		type => 'button',
		callback => '__clearTranspositionTable',
	},
	{
		name => 'Batch',
		type => 'check',
		default => 'false',
		callback => '__changeBatchMode',
	},
	{
		name => 'OwnBook',
		type => 'check',
		default => 'false',
	},
	{
		name => 'BookFile',
		type => 'string',
		callback => '__setBookFile',
	},
	{
		name => 'BookDepth',
		type => 'spin',
		min => 1,
		max => 1024,
		default => 20,
	},
	{
		name => 'Ponder',
		type => 'check',
		default => 'false',
	},
	{
		name => 'Move Overhead',
		type => 'spin',
		min => 0,
		max => 5000,
		default => 10,
	},
];

my $uci_options = UCI_OPTIONS;
my %uci_options = map { $_->{name} => $_ } @$uci_options;

sub new {
	my ($class) = @_;

	my $position = Chess::Plisco::Engine::Position->new;
	my $self = {
		__position => $position,
		__signatures => [$position->signature],
		__options => {},
		__book => Chess::Plisco::Engine::Book->new,
		__setup => 0,
		__fen => undef,
		__turn => CP_WHITE,
		__started => undef,
		__moves => [],
		__continued => 0,
		__move_overheads => [],
		__last_params => {},
		__original_time_adjust => -1,
	};

	my $options = UCI_OPTIONS;
	foreach my $option (@$options) {
		$self->{__options}->{$option->{name}} = $option->{default};
	}

	my $tt_size = $self->{__options}->{Hash};
	$self->{__tt} = Chess::Plisco::Engine::TranspositionTable->new($tt_size);

	bless $self, $class;

	$self->__calibrateNPS;

	return $self;
}

sub __calibrateNPS {
	my ($self) = @_;

	no integer;

	my $position = Chess::Plisco::Engine::Position->new;

	my $watcher = Chess::Plisco::Engine::InputWatcher->new(\*STDIN);
	$watcher->setBatchMode(1);

	my %options = (
		position => $position,
		tt => $self->{__tt},
		watcher => $watcher,
		info => sub {},
		signatures => [],
	);
	my $tree = Chess::Plisco::Engine::Tree->new(%options);
	$tree->{max_depth} = 3;
	$tree->{start_time} = [gettimeofday];

	$tree->think;

	my $elapsed = 1000 * tv_interval($tree->{start_time});
	$elapsed ||= 1;
	$self->{__nps} = $tree->{nodes} / $elapsed;

	$tree->{tt}->clear;
}

sub uci {
	my ($self, $in, $out) = @_;

	if ($^O =~ /win32/i) {
		$in = $self->__msDosSocket($in);
	}

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

Plisco is a chess engine written in Perl that implements the UCI protocol (see
http://wbec-ridderkerk.nl/html/UCIProtocol.html).

Try 'help' for a list of commands!

EOF

	while (1) {
		$self->{__watcher}->check;
		if (delete $self->{__abort}) {
			$self->DESTROY; # Make sure to clean-up for MS-DOS.
			last;
		}
	}

	return $self;
}

sub DESTROY {
	my ($self) = @_;

	if ($self->{__child_pid}) {
		# Seems to be useless for MS-DOS but ...
		kill 'QUIT', $self->{__child_pid};
	}
	if ($self->{__socket}) {
		unlink $self->{__socket};
	}

	# No point to call waitpid() because the "child process" is actually
	# a thread in MS-DOS.
}

sub __msDosSocket {
	my ($self, $real_in) = @_;

	require IO::Socket::UNIX;
	require File::Temp;

	my $path = $self->{__socket} = File::Temp::tmpnam();

	my $sock = IO::Socket::UNIX->new(
		Type => IO::Socket::UNIX::SOCK_STREAM(),
		Local => $path,
		Listen => 1,
	) or die __x("Cannot create socket write-end '{path}': {error}!\n",
		path => $path, error => $!);

	my $pid = fork;
	if (!defined $pid) {
		die __x("Cannot fork: {error}!\n", error => $!);
	}

	if ($pid) {
		# Parent.
		$sock->close;
		$self->{__child_pid} = $pid;
		my $new_in = IO::Socket::UNIX->new(
			Type => IO::Socket::UNIX::SOCK_STREAM(),
			Peer => $path,
		) or die __x("Cannot create socket read-end '{path}': {error}!\n",
				path => $path, error => $!);
		return $new_in;
	} else {
		my $fh = $sock->accept
			or die __x("Error accepting connection on '{path}': {error}!\n",
				path => $path, error => $!);
		while (1) {
			my $line = $real_in->getline;
			exit if !defined $line;
			$fh->print($line);
			$line = $self->__trim($line);
			# There seems to be no other way to get rid of the input reading
			# thread under MS-DOS.
			exit if 'quit' eq $line;
		}
	}
}

sub __onEof {
	my ($self, $line) = @_;

	$self->DESTROY;

	exit;
}

sub __onUciInput {
	my ($self, $line) = @_;

	$line = $self->__trim($line);
	return $self if !length $line;

	my ($cmd, $args) = split /[ \t]+/, $line, 2;

	my $method = '__onUciCmd' . ucfirst lc $cmd;
	$args = $self->__trim($args);
	if ($self->can($method)) {
		my $success = $self->$method($args);
		# Was this go command cancelled because of an already running search?
		# In this case, we have remembered the arguments, and can start a new
		# search now.
		#
		# This will happen instantly. If a "go" command is sent during a
		# running search, this will only be noticed during the time control
		# check of the search tree. The "go" handler does not start a new
		# search but simply cancels the current search. Because this happens
		# during the time control check, the current search will terminate
		# instantly, and we will end up here. Now, the current search will
		# basically be replaced by a new one without recursion.
		if ($success && 'go' eq lc $cmd && $self->{__go_queue} && !$self->{__tree}) {
			$args = delete $self->{__go_queue};
			$self->__onUciCmdGo($args);
		}
	} else {
		$self->{__out}->print("info unknown command '$cmd'\n");
	}

	return $self;
}

sub __onUciCmdFen {
	my ($self) = @_;

	$self->{__out}->print($self->{__position}->toFEN . "\n");

	return $self;
}

sub __onUciCmdPgn {
	my ($self) = @_;

	my @now = localtime;
	my $date = sprintf '%04d.%02d.%02d', $now[5] + 1900, $now[4] + 1, $now[3];

	my $pgn = <<"EOF";
[Event "Computer Chess Game"]
[Site "Computer Chess"]
[Date "$date"]
[Round "?"]
EOF

	my $version = $Chess::Plisco::Engine::VERSION || 'development version';
	if ($self->{__turn} == CP_WHITE) {
		$pgn .= << "EOF";
[White "Chess::Plisco $version"]
[Black "Unknown opponent"]
EOF
	} else {
		$pgn .= << "EOF";
[White "Unknown opponent"]
[Black "Chess::Plisco $version"]
EOF
	}

	my $state = $self->{__position}->gameOver;
	my $result;
	if ($state & CP_GAME_OVER) {
		if ($state & CP_GAME_WHITE_WINS) {
			$result = '1-0';
		} else {
			$result = '0-1';
		}
	} else {
		$result = '*';
	}

	$pgn .= qq{[Result "$result"]\n};

	if ($self->{__setup}) {
		$pgn .= <<"EOF";
[SetUp "1"]
[FEN "$self->{__fen}"]
EOF
	}

	$pgn .= "\n";

	my $fen = $self->{__setup} ? $self->{__fen} : Chess::Plisco->new->toFEN;
	my $pos = Chess::Plisco->new($fen);

	my @move_tokens;
	my $moveno;
	if ($pos->toMove == CP_WHITE) {
		$moveno = $pos->[CP_POS_HALFMOVES] >> 1;
	} else {
		$moveno = 1 + ($pos->[CP_POS_HALFMOVES] >> 1);
		push @move_tokens, "$moveno...";
	}

	foreach my $cn (@{$self->{__moves}}) {
		if ($pos->toMove == CP_WHITE) {
			++$moveno;
			push @move_tokens, "$moveno.";
		}

		my $move = $pos->parseMove($cn);
		push @move_tokens, $pos->SAN($move);
		$pos->doMove($move);
	}
	push @move_tokens, $result;

	my $moves = join ' ', @move_tokens;
	my $last_space = 0;
	my $line_pos = 0;
	my @chars = split //, $moves;
	foreach my $char (@chars) {
		++$line_pos;

		if ($char eq ' ') {
			if ($line_pos > 78) {
				$chars[$last_space] = "\n";
				$line_pos = 0;
			}
		}
	}
	chomp $moves;

	$pgn .= "$moves\n";

	$self->{__out}->print($pgn);
}

sub __onUciCmdBoard {
	my ($self) = @_;

	my $board = $self->{__position}->board;
	$self->{__out}->print($board);

	return;
}

sub __onUciCmdEvaluate {
	my ($self) = @_;

	my $score = $self->{__position}->evaluate;

	my ($cp_pos_game_phase, $cp_pos_opening_score, $cp_pos_endgame_score) = (
		Chess::Plisco::Engine::Position::CP_POS_GAME_PHASE,
		Chess::Plisco::Engine::Position::CP_POS_OPENING_SCORE,
		Chess::Plisco::Engine::Position::CP_POS_ENDGAME_SCORE,
	);

	my $phase = $self->{__position}->[$cp_pos_game_phase];
	my $op_score = $self->{__position}->[$cp_pos_opening_score];
	my $eg_score = $self->{__position}->[$cp_pos_endgame_score];

	$self->{__out}->print("$score cp (phase: $phase, opening: $op_score, endgame: $eg_score)\n");

	return $self;
}

sub __onUciCmdSee {
	my ($self, $args) = @_;

	my $san = $self->__trim($args);
	if (!length $san) {
		$self->{__out}->print("usage: see MOVE\n");
		return $self;
	}
	my $position = $self->{__position};
	my $move = $position->parseMove($san);
	if (!$move) {
		$self->{__out}->print("error: invalid or illegal move '$san'\n");
		return $self;
	}

	my $score = $position->SEE($move);
	$self->{__out}->print("$score cp\n");

	return $self;
}

sub __cancelSearch {
	my ($self) = @_;

	return if !$self->{__tree};

	$self->{__watcher}->requestStop;
	$self->{__tree}->{cancelled} = 1;

	return $self;
}

sub __onUciCmdGo {
	my ($self, $args) = @_;

	$self->{__start_time} = [gettimeofday];

	if ($self->__cancelSearch) {
		# Remember the arguments to this go command and re-try as soon as the
		# currently still running search terminates.
		$self->{__go_queue} = $args;
		return;
	}

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
		         || 'movetime' eq $arg
		         || 'perft' eq $arg) {
			my $val = shift @args;
			$val ||= 0;
			$val = +$val;
			if ($val < 0) {
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

	if ($params{perft}) {
		$self->{__position}->perftWithOutput($params{perft}, $self->{__out});
		return $self;
	}

	if ($self->{__options}->{'Batch'} eq 'true') {
		$self->{__watcher}->setBatchMode(1);
	} else {
		$self->{__watcher}->setBatchMode(0);
	}

	my %options = (
		position => $self->{__position}->copy,
		tt => $self->{__tt},
		watcher => $self->{__watcher},
		info => $info,
		signatures => $self->{__signatures},
	);
	if ($self->{__options}->{OwnBook} eq 'true') {
		$options{book} = $self->{__book};
		$options{book_depth} = $self->{__options}->{BookDepth};
	}

	my $tree = Chess::Plisco::Engine::Tree->new(%options);
	$tree->{debug} = 1 if $self->{__debug};
	$tree->{ponder} = 1 if $params{ponder};
	$tree->{start_time} = $self->{__start_time};
	if ($params{depth}) {
		$tree->{max_depth} = $params{depth};
	} elsif ($params{mate}) {
		$tree->{max_depth} = 2 * $params{mate} - 1;
	} elsif ($params{movetime}) {
		$tree->{maximum} = $tree->{optimum} = $params{movetime};
		$tree->{fixed_time} = 1;
	} elsif ($params{infinite}) {
		$tree->{max_depth} = Plisco::Engine::Tree->MAX_PLY;
	} elsif ($params{node}) {
		$tree->{max_nodes} = $params{node};
	} else {
		$tree->{use_time_management} = 1;
	}

	if ($self->{__continued}) {
		$self->{__continued} = $self->__measureMoveOverhead(%params)
	}
	$self->{__last_params} = {%params};

	my $tc = $self->{__tc} = Chess::Plisco::Engine::TimeControl->new($tree);

	my $limits = Chess::Plisco::Engine::LimitsType->new;
	# $limits->{moves} = FIXME!
	$limits->{time}->[0] = $params{wtime};
	$limits->{time}->[1] = $params{btime};
	$limits->{inc}->[0] = $params{winc};
	$limits->{inc}->[1] = $params{binc};
	$limits->{start_time} = $self->{__start_time};
	$limits->{movestogo} = $params{movestogo};
	$limits->{depth} = $params{depth};
	#$limits-{mate} = FIXME!
	$limits->{infinite} = $params{infinite};
	$limits->{ponder} = $params{ponder};
	$limits->{nodes} = $params{nodes};

	$params{move_overhead} = $self->{__options}->{'Move Overhead'};

	$tc->init(
		$limits, $tree->{position}->turn,
		$tree->{position}->[CP_POS_HALFMOVES] + 1,
		\%params, \$self->{__original_time_adjust},
	);

	# This is the logic from checkTime() of the tree.
	{
		no integer;
		my $max_nodes = $self->{__nps} >> 2;
		my $dyn_nodes = ($tree->{maximum} * $self->{__nps}) >> 13;
		$tree->{nodes_to_tc} = ($max_nodes < $dyn_nodes) ? $max_nodes : $dyn_nodes;
		$tree->{nodes_to_tc} = 50 if $tree->{nodes_to_tc} < 50;
		$tree->{nodes_to_tc} = 5000 if $tree->{nodes_to_tc} > 500;
	}

	$self->{__tree} = $tree;

	my ($bestmove, $ponder);
	eval {
		($bestmove, $ponder) = $tree->think;
	};
	if ($@) {
		$self->__output("unexpected exception: $@");
	}
	{
		no integer;
		$self->{__last_search_time} = int(1000 * tv_interval($self->{__start_time}));
	}
	my $elapsed = $self->{__last_search_time} || 1;
	$self->{__nps} = (1000 * $tree->{nodes}) / $elapsed;

	delete $self->{__tree};
	delete $self->{__tc};

	if ($bestmove) {
		my $cn = $self->{__position}->moveCoordinateNotation($bestmove);
		if (defined $ponder) {
			my $pcn = $self->{__position}->copy->moveCoordinateNotation($ponder);
			$self->__output("bestmove $cn ponder $pcn");
		} else {
			$self->__output("bestmove $cn");
		}
		push @{$self->{__moves}}, $cn;
	}

	$self->{__watcher}->setBatchMode(0);


	return $self;
}

sub __measureMoveOverhead {
	my ($self, %params) = @_;

	return if !defined $self->{__last_search_time};

	my $my_time = $self->{__position}->turn == CP_WHITE ? 'wtime' : 'btime';
	my $my_inc = $self->{__position}->turn == CP_WHITE ? 'winc' : 'binc';

	my $last_params = $self->{__last_params};
	return if !($params{$my_time} && $last_params->{$my_time});
	return if $params{$my_inc} != $last_params->{$my_inc};

	my $expected_time = $last_params->{$my_time} + $params{$my_inc} - $self->{__last_search_time};
	my $overhead = $expected_time - $params{$my_time};
	if ($overhead >= 0) {
		push @{$self->{__move_overheads}}, $overhead;
		push @{$self->{__move_overheads}}, $overhead if @{$self->{__move_overheads}} < 2;
		shift @{$self->{__move_overheads}} if @{$self->{__move_overheads}} > 3;
		my @values = sort { $a <=> $b } @{$self->{__move_overheads}};
		$self->{__options}->{'Move Overhead'} = $values[1];
	}

	return $self;
}

sub __onUciCmdPonderhit {
	my ($self) = @_;

	return if !$self->{__tc};

	delete $self->{__tree}->{ponder};

	return $self;
}

sub __onUciCmdUcinewgame {
	my ($self) = @_;

	$self->__cancelSearch;

	$self->{__tt}->clear;

	return $self;
}

sub __onUciCmdSetoption {
	my ($self, $args) = @_;

	if ($args !~ /^name[ \t]+(.*?)(?:value[ \t]+(.*))?$/) {
		$self->__output("info Error: usage setoption name NAME[ value VALUE]");
		return $self;
	}

	my ($name, $value) = map { $self->__trim($_) } ($1, $2);
	$name = 'Move Overhead' if $name eq 'MoveOverhead';
	if (!exists $uci_options{$name}) {
		$self->__output("info Error: unsupported option '$name'");
		return $self;
	}

	my $option = $uci_options{$name};

	if (exists $option->{min}) {
		my $min = $option->{min};
		if (($value || 0) < $min) {
			$self->__output("info Error: minimum value for option"
					. " '$name' is $min");
			return $self;
		}
	}

	if (exists $option->{max}) {
		my $max = $option->{max};
		if (($value || 0) > $max) {
			$self->__output("info Error: maximum value for option"
					." '$name' is $max");
			return $self;
		}
	}

	if ('check' eq $option->{type}) {
		if ($value ne 'true' && $value ne 'false') {
			$self->__output("info Error: only 'true' and 'false' are allowed"
					. " for option '$name'");
			return $self;
		}
	}

	$self->{__options}->{$name} = $value;

	if (exists $option->{callback}) {
		my $method = $option->{callback};
		$self->$method($value);
	}

	return $self;
}

sub __resizeTranspositionTable {
	my ($self, $size) = @_;

	$self->{__tt}->resize($size);
}

sub __clearTranspositionTable {
	my ($self, $size) = @_;

	$self->{__tt}->clear;
}

sub __changeBatchMode {
	my ($self, $value) = @_;

	if ('true' eq $value) {
		$self->__output("info all commands are ignored during search in"
				. " batch mode!")
	}
}

sub __setBookFile {
	my ($self, $value) = @_;

	if ($self->{__options}->{OwnBook} ne 'true') {
		$self->__info("Warning: book file will not be used, when OwnBook is set to 'false'!");
	}

	my $callback = sub { $self->__info(@_) };
	$self->{__book}->setFile($value, $callback);

	return $self;
}

sub __onUciCmdStop {
	my ($self) = @_;

	if ($self->{__tree}) {
		$self->__cancelSearch;

		# Apparently, all GUIs send a "stop" to cancel a (failed) ponder. And
		# They also expect a "bestmove" reply. But the tree suppresses that
		# "bestmove" reply, when the "cancelled" flag is set.  We therefore
		# unset the flag here.
		delete $self->{__tree}->{cancelled};
	}

	return $self;
}

sub __movelistContinuous {
	my ($self, $last_moves) = @_;

	return if @{$self->{__moves}} - @$last_moves != 1;

	for (my $i = 0; $i < @$last_moves; ++$i) {
		return if $self->{__moves}->[$i] ne $last_moves->[$i];
	}

	return $self;
}

sub __onUciCmdPosition {
	my ($self, $args) = @_;

	$self->__cancelSearch;

	unless (defined $args && length $args) {
		$self->__info("error: usage: position FEN POSITION | startpos [MOVES...]");
		return;
	}

	my ($type, @moves) = split /[ \t]+/, $args;
	my $position;
	$self->{__started} = time;

	my $last_setup = $self->{__setup};
	my $last_fen = $self->{__fen};
	my @last_moves = @{$self->{__moves}};

	if ('fen' eq lc $type) {
		my $fen = shift @moves;
		unless (defined $fen && length $fen) {
			$self->__info("error: position missing after 'fen'");
			return;
		}

		$self->{__moves} = [@moves];

		while (@moves) {
			if ('moves' eq $moves[0]) {
				last;
			}
			$fen .= ' ' . shift @moves;
		}
		eval {
			$position = Chess::Plisco::Engine::Position->new($fen);
		};
		if ($@) {
			$self->__info("error: invalid FEN string: $@");
			return;
		}
		$self->{__setup} = 1;
		$self->{__fen} = $fen;
		$self->{__turn} = $position->turn;
	} elsif ('startpos' eq lc $type) {
		$self->{__setup} = 0;
		$self->{__turn} = CP_WHITE;
		$position = Chess::Plisco::Engine::Position->new;
	} else {
		$self->__info("error: usage: position FEN POSITION | startpos moves [MOVES...]");
		return;
	}

	$self->{__moves} = [];
	my @signatures = ($position->signature);
	if ('moves' eq shift @moves) {
		$self->{__moves} = [@moves];
		for (my $i = 0; $i < @moves; ++$i) {
			my $move = $moves[$i];
			eval { $position->applyMove($move) };
			if ($@) {
				$@ =~ s/(.+) at .*/$1/s;
				$moves[$i] = ">>>$move<<<";
				my $moves = join ' ', @moves;
				$self->__info("Error with given moves: $moves: $@");
				return;
			}
			push @signatures, $position->signature;
		}
	}

	# Check whether this continues an ongoing game.
	$self->{__continued} = $self->{__fen} eq $last_fen
		&& $self->{__setup} == $last_setup
		&& $self->__movelistContinuous(\@last_moves);

	$self->{__position} = $position;
	$self->{__signatures} = \@signatures;

	return $self;
}

sub __onUciCmdHelp {
	my ($self) = @_;

	$self->__output(<<"EOF");
    The Plisco Chess Engine

    The engine understands the following commands:

        uci - switch to UCI mode (no-op)
        debug (on|off) - switch debugging on or off
        go [depth, wtime, btime, ... see protocol!]
        go perft DEPTH - do performance test (blocks engine, hit CTRL-C ...)
        setoption name NAME[ value VALUE] - set option NAME to VALUE
        isready - ping the engine
        stop - move immediately
        fen - print the current position as FEN
        board - print a compact representation of the board
        evaluate - print the static score of the current position
        see MOVE - do a static exchange evaluation for MOVE
        help - show available commands
        quit - quit the engine immediately

    See http://wbec-ridderkerk.nl/html/UCIProtocol.html for more information!

    In batch mode, the engine is unresponsive during searches.
EOF

	return;
}

sub __onUciCmdQuit {
	my ($self) = @_;

	exit;
}

sub __onUciCmdUci {
	my ($self) = @_;

	my $version = $Chess::Plisco::Engine::VERSION || 'development version';
	$self->__output("id name Plisco $version");
	$self->__output("id author Guido Flohr <guido.flohr\@cantanea.com>");

	my $options = UCI_OPTIONS;
	foreach my $option (@{$options}) {
		my $output = "option name $option->{name} type $option->{type}";
		$output .= " default $option->{default}";
		$output .= " min $option->{min}" if exists $option->{min};
		$output .= " max $option->{max}" if exists $option->{max};
		$self->__output($output);
	}

	$self->__output("uciok");

	return;
}

sub __onUciCmdIsready {
	my ($self) = @_;

	$self->__output("readyok");

	return;
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

	return;
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
