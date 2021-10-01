#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::Engine::InputWatcher;
$Chess::Plisco::Engine::InputWatcher::VERSION = '0.3';
use strict;

use IO::Select;
 
sub new {
	my ($class, $fh) = @_;

	$fh->autoflush(1);
	my $sel = IO::Select->new($fh);

	bless {
		__handle => $fh,
		__sel => $sel,
		__input => '',
	}, $class;
}

sub handle {
	my ($self) = @_;

	return $self->{__fh};
}

sub onInput {
	my ($self, $cb) = @_;

	$self->{__on_input} = $cb;
}

sub onEof {
	my ($self, $cb) = @_;

	$self->{__on_eof} = $cb;

	return $self;
}

sub check {
	my ($self) = @_;

	while (my @ready = $self->{__sel}->can_read(0)) {
		foreach my $fh (@ready) {
			my $offset = length $self->{__input};
			my $bytes = $fh->sysread($self->{__input}, 1, $offset);
			if (!$bytes) {
				$self->{__on_eof}->() if $self->{__on_eof};
			} elsif ($self->{__input} =~ s/^(.*?)\n//) {
				$self->{__on_input}->($1) if $self->{__on_input};
			}
		}
	}
}

1;
