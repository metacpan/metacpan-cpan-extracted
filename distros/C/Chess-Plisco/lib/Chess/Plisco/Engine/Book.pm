#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Make Dist::Zilla happy.
# ABSTRACT: Opening book for Chess-Plisco engine.

package Chess::Plisco::Engine::Book;
$Chess::Plisco::Engine::Book::VERSION = 'v1.0.0';
use strict;

use Chess::Opening::Book::Polyglot;

sub new {
	my ($class, $engine) = @_;

	bless {}, $class;
}

sub setFile {
	my ($self, $filename, $callback) = @_;

	my $book = eval { Chess::Opening::Book::Polyglot->new($filename) };
	if ($@) {
		$callback->("Error opening book file: $@");
	} else {
		$callback->("Using book file '$filename'");
	}

	$self->{__book} = $book;

	return $self;
}


sub pickMove {
	my ($self, $pos) = @_;

	return if !$self->{__book};

	my $fen = $pos->toFEN;
	my $entry = $self->{__book}->lookupFEN($pos);
	return if !$entry; # Out of book.

	# Moves here are moves in algebraic (UCI notation).
	my $moves = $entry->moves;
	my @moves = keys %$moves or return;
	my $total = 0;
	my %weights;

	foreach my $move (@moves) {
		my $node = $moves->{$move};
		my $weight = $node->weight;
		$total += $weight;
		$weights{$move} = $weight;
	}

	my $r = int rand $total;
	my $cumulative;
	foreach my $move (@moves) {
		$cumulative += $weights{$move};

		return $move if $r < $cumulative;
	}

	# Out of book.
}

1;
