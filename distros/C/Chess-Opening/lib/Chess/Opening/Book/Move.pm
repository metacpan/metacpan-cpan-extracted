#! /bin/false

# Copyright (C) 2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Opening::Book::Move;
$Chess::Opening::Book::Move::VERSION = '0.3';
use common::sense;

use Locale::TextDomain 'com.cantanea.Chess-Opening';

sub new {
	my ($class, %args) = @_;

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
	if (exists $args{count} && $args{count}
	    && $args{count} !~ /^[1-9][0-9]*$/) {
		require Carp;
		Carp::croak(__"count must be a positive integer");
	}
	$args{count} ||= 1;
	$args{learn} = '0' if !exists $args{learn};

	bless {
		__move => $args{move},
		__count => $args{count},
		__learn => $args{learn},
	}, $class;
}

sub weight { shift->{__count} }
sub count { shift->{__count} }
sub move { shift->{__move} }
sub learn { shift->{__learn} }

1;
