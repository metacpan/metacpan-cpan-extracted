#! /bin/false

# Copyright (C) 2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Opening::ECO::Entry;
$Chess::Opening::ECO::Entry::VERSION = '0.5';
use common::sense;

use Locale::TextDomain 'com.cantanea.Chess-Opening';

use base 'Chess::Opening::Book::Entry';

sub new {
	my ($class, $fen, %args) = @_;

	my $self = $class->SUPER::new($fen);
	$self->{__parent} = $args{parent} if exists $args{parent};
	$self->{__eco} = $args{eco} if exists $args{eco};
	$self->{__variation} = $args{variation} if exists $args{variation};

	return $self;
}

sub eco {
	my ($self) = @_;

	return substr $self->xeco, 0, 3;
}

sub xeco {
	shift->{__eco};
}

sub variation {
	__(shift->{__variation});
}

1;
