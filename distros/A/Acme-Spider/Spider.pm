package Acme::Spider;
$Acme::Spider::VERSION = '0.02';

=head1 NAME

Acme::Spider - frighten some other modules

=head1 SYNOPSIS

  use Acme::Spider;

=head1 DESCRIPTION

Damian Conway is afraid of spiders, and all his code is afraid of this spider.

=head1 TODO

As the spider evolves, it will become better at recognising Damian's modules.
It's a pity evolution doesn't happen without some help.

=cut

use strict;
use warnings;
use Carp;

my $re = do {
	my @data = <DATA>;
	chomp @data;
	my $data = join '|', @data;
	qr/^(?:$data)/;
};

sub victim {
	my ($file) = @_;
	return scalar $file =~ $re;
}

sub bite {
	my ($self, $file) = @_;
	# we need to expand this test to include other Damian modules.
	if (victim($file)) {
		carp "$file doesn't like spiders";
		return 0;
	}
	return undef;
}

BEGIN { unshift @INC, \&bite }

=head1 AUTHORS

Marty Pauley E<lt>marty@kasei.comE<gt>
Karen Pauley E<lt>karen@kasei.comE<gt>

=head1 COPYRIGHT

  Copyright (C) 2006 Marty and Karen

  This program is free software; you can redistribute it and/or modify it under
  the terms of either the GNU General Public License; either version 2 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut

1;

__DATA__
Acme/Bleach
Acme/Don/t
Attribute/Handlers
Attribute/Handlers/Prospective
Attribute/Types
Class/Contract
Class/Delegation
Class/Multimethods
Class/Std
Class/Std/Utils
Config/Std
Contextual/Return
Coy
Debug/Phases
Filter/Simple
Getopt/Clade
Getopt/Declare
Getopt/Euclid
Hook/LexWrap
Inline/Files
IO/Busy
IO/InSitu
IO/Interactive
IO/Prompt
Leading/Zeros
Lingua/EN/Inflect
Lingua/Romana/Perligata
List/Maker
Log/StdLog
Module/Starter/PBP
NEXT
Parse/RecDescent
Perl6/Builtins
Perl6/Currying
Perl6/Export
Perl6/Export/Attrs
Perl6/Form
Perl6/Gather
Perl6/Placeholders
Perl6/Rules
Perl6/Say
Perl6/Slurp
Perl6/Variables
Quantum/Superpositions
Regexp/Common
Regexp/MatchContext
Smart/Comments
Sub/Installer
Switch
Text/Autoformat
Text/Balanced
Text/Reform
Tie/SecureHash
Toolkit
