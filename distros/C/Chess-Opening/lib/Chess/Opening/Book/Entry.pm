#! /bin/false

# Copyright (C) 2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Opening::Book::Entry;
$Chess::Opening::Book::Entry::VERSION = '0.6';
use common::sense;

use Locale::TextDomain 'com.cantanea.Chess-Opening';
use Scalar::Util qw(reftype);

use Chess::Opening::Book::Move;

sub new {
	my ($class, $fen, %args) = @_;

	my $self = bless {
		__fen => $fen,
		__moves => {},
		__count => 0,
		__length => -1,
		__significant => -1,
		__history => [],
	}, $class;

	$self->{__length} = $args{length} if exists $args{length};
	$self->{__significant} = $args{significant} if exists $args{significant};
	if (exists $args{history} && ref $args{history}
	    && 'ARRAY' eq $args{history}) {
		$self->{__history} = $args{history};
	}

	return $self;
}

sub addMove {
	my ($self, %args) = @_;

	if (!exists $args{move}) {
		require Carp;
		Carp::croak(__x("the named argument '{arg}' is required",
		                arg => 'move'));
	}
	if ($args{move} !~ /^[a-h][1-8][a-h][1-8][qrbn]?$/) {
		require Carp;
		Carp::croak(__x("invalid move '{move}'",
		                move => '$args{move}'));
	}
	$args{count} = $args{weight} if exists $args{weight};
	if (exists $args{count} && $args{count}
	    && $args{count} !~ /^[1-9][0-9]*$/) {
		require Carp;
		Carp::croak(__"count must be a positive integer");
	}

	my $move = Chess::Opening::Book::Move->new(%args);
	$self->{__moves}->{$args{move}} = $move;
	$self->{__counts} += $move->count;

	return $self;
}

sub moves { shift->{__moves} }
sub counts { shift->{__counts} }
sub weights { shift->{__counts} }

1;
