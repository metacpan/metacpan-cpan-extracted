#! /bin/false

# Copyright (C) 2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Make Dist::Zilla happy.
# ABSTRACT: Read chess opening books in polyglot format

package Chess::Opening::Book;
$Chess::Opening::Book::VERSION = '0.6';
use common::sense;

use Locale::TextDomain 'com.cantanea.Chess-Opening';

use Chess::Opening::Book::Entry;

sub new {
	require Carp;

	Carp::croak(__"Chess::Opening::Book is an abstract base class");
}

sub lookupFEN {
	my ($self, $fen) = @_;

	my $key = $self->_getKey($fen) or return;
	my ($first, $last) = $self->_findKey($key) or return;

	my $entry = Chess::Opening::Book::Entry->new($fen);
	foreach my $i ($first .. $last) {
		$entry->addMove($self->_getEntry($i));
	}

	return $entry;
}

sub _pieces {
	# Polyglot style piece encodings.
	p => 0,
	P => 1,
	n => 2,
	N => 3,
	b => 4,
	B => 5,
	r => 6,
	R => 7,
	q => 8,
	Q => 9,
	k => 10,
	K => 11,
}

sub _parseFEN {
	my ($whatever, $fen) = @_;

	my @tokens = split /[ \t\r\n]+/, $fen;
	return if 6 != @tokens;

	my %result;
	@result{'ranks', 'on_move', 'castling', 'ep', 'hmc', 'next_move'} = @tokens;
	$result{on_move} = lc $result{on_move};
	return if $result{on_move} ne 'w' && $result{on_move} ne 'b';
	return if $result{next_move} <= 0;

	if ('-' eq $result{castling}) {
		$result{castling} = {};
	} elsif ($result{castling} !~ /^[KQkq]+$/) {
		return;
	} else {
		$result{castling} = {map { $_ => 1 } split //, $result{castling}};
	}
	if ($result{ep} ne '-') {
		if ($result{on_move} eq 'b') {
			return if $result{ep} !~ /^[a-h]3$/;
		} else {
			return if $result{ep} !~ /^[a-h]6$/;
		}
	}
	return if $result{hmc} !~ /^(?:0|[1-9][0-9]*)$/;
	return if $result{next_move} !~ /^[1-9][0-9]*$/;

	my @ranks = split /\//, delete $result{ranks};
	return if 8 != @ranks;

	my $rank = 8;
	my $file;
	$result{pieces} = [];
	my %pieces = $whatever->_pieces;
	foreach my $token (@ranks) {
		$file = ord 'a';
		foreach my $char (split //, $token) {
			if ($char ge '1' && $char le '8') {
				$file += $char;
				return if $file > ord 'i';
			} elsif (exists $pieces{$char}) {
				return if $file > ord 'h';
				push @{$result{pieces}}, {
					piece => $char,
					field => (chr $file) . $rank,
				};
				++$file;
			} else {
				return;
			}
		}
		--$rank;
	}

	return %result;
}

1;
