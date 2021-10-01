#! /bin/false

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

package Chess::Plisco::EPD;
$Chess::Plisco::EPD::VERSION = '0.3';
use strict;
use integer;

use Scalar::Util qw(reftype);
use Locale::TextDomain qw('Chess-Plisco');

use Chess::Plisco::EPD::Record;

sub new {
	my ($class, $arg, $filename) = @_;

	my $reftype = (reftype $arg) || '';
	my @lines;
	if ('SCALAR' eq $reftype) {
		@lines = split /\n/, $$arg;
		$filename = __"[in-memory string]";
	} elsif ('ARRAY' eq $reftype) {
		@lines = @$arg;
		$filename = __"[in-memory array]";
	} elsif ('GLOB' eq $reftype) {
		@lines = <$arg>;
		$filename ||= __"[file-handle]";
	} else {
		open my $fh, '<', $arg
			or die __x("cannot open '{filename}' for reading: {error}!\n",
				filename => $arg,
				error => $!);
		$filename ||= $arg;
		@lines = <$fh>;
	}

	my $lineno = 0;
	my $ws = "[ \011-\015]";
	my @self;
	foreach my $line (@lines) {
		++$lineno;
		$line =~ s/^$ws+//;
		$line =~ s/ws+$//;
		next if !length $line;

		my $record = eval { Chess::Plisco::EPD::Record->new($line) };
		if ($@) {
			die "$filename:$lineno: $@";
		}
		push @self, $record;
	}

	bless \@self, $class;
}

sub __readFromFileHandle {
	my ($class, $filename, $fh) = @_;

	return <$fh>;
}

sub records {
	my ($self) = @_;

	return @$self;
}

1;
