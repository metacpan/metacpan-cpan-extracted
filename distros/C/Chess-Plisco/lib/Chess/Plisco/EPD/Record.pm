#! /bin/false

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::EPD::Record;
$Chess::Plisco::EPD::Record::VERSION = 'v0.7.0';
use strict;
use integer;

use Locale::TextDomain qw('Chess-Plisco');

use Chess::Plisco qw(:all);

sub new {
	my ($class, $line) = @_;

	my $ws = "[ \011-\015]";
	$line =~ s/^$ws+//;
	$line =~ s/ws+$//;
	my ($pieces, $to_move, $castling, $ep_shift, $ops) = split /$ws+/, $line, 5;
	if (!defined $ep_shift) {
		die __"Incomplete EPD string.\n";
	}

	my %operations;
	while (length $ops) {
		if ($ops !~ s/^$ws*([_a-zA_Z0-9]+)//) {
			die "Invalid EPD.\n";
		}

		my $operation = $1;
		die __x("Duplicate operation '{operation}'.", operation => $operation)
			if exists $operations{$operation};
		
		my @operands;
		while (length $ops) {
			if ($ops =~ s/^$ws*"(.*?)"//) {
				push @operands, $1;
			} elsif ($ops =~ s/^$ws*([^ \t;]+)//) {
				push @operands, $1;
			} elsif ($ops =~ s/^$ws*;$ws*//) {
				last;
			} else {
				die __"Invalid EPD.\n";
			}
		}

		$operations{$operation} = [@operands];
	}

	my $position = Chess::Plisco->new("$pieces $to_move $castling $ep_shift");
	my $hmc = $operations{hmvc} || 0;
	my $fmc = $operations{fmvc} || 1;
	my $fen = "$pieces $to_move $castling $ep_shift $hmc $fmc";
	my $position = Chess::Plisco->new($fen);

	bless {
		__position => $position,
		__operations => \%operations,
	}, $class;
}

sub position {
	shift->{__position};
}

sub operations {
	shift->{__operations};
}

sub operation {
	my ($self, $opcode) = @_;

	if (wantarray) {
		return @{$self->operations->{$opcode} || []};
	} elsif (exists $self->operations->{$opcode}) {
		return $self->operations->{$opcode}->[0];
	} else {
		return;
	}
}

1;
