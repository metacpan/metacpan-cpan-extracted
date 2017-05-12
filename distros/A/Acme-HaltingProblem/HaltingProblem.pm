package Acme::HaltingProblem;

use strict;
use vars qw($VERSION);

$VERSION = "1.00";

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	die "No code provided for analysis" unless $self->{Machine};
	$self->{Input} = [ ] unless ref($self->{Input}) eq 'ARRAY';
	return bless $self, $class;
}

sub analyse {
	my $self = shift;
	eval { $self->{Machine}->(@{ $self->{Input} }); };
	return 1;
}

=head1 NAME

Acme::HaltingProblem - A program to decide whether a given program halts

=head1 SYNOPSIS

	use Acme::HaltingProblem;
	my $problem = new Acme::HaltingProblem(
		Machine	=> sub { ... },
		Input	=> [ ... ],
			);
	my $solution = $problem->solve();

=head1 DESCRIPTION

The Halting Problem is one of the hardest problems in computing. The
problem, approximately stated, is thus:

	Given an arbitrary Turing Machine T and input for that turing
	machine D, decide whether the computation T(D) will terminate.

=over 4

=item new Acme::HaltingProblem(...)

Construct a new instance of the halting problem where the Machine is
given as an arbitrary subref, and the Input is a reference to a list
of arguments.

=item $problem->analyse()

Analyse the instance of the halting problem. If it halts, the method
will return 1. Otherwise, it will not return 1.

=head1 BUGS

This code does not correctly deal with the case where the machine
does not halt.

=head1 TODO

It would be nice if this module accepted instances of Acme::Turing.

=head1 SUPPORT

Mail the author at <cpan@anarres.org>

=head1 AUTHOR

	Shevek
	CPAN ID: SHEVEK
	cpan@anarres.org
	http://www.anarres.org/projects/

=head1 COPYRIGHT

Copyright (c) 2002 Shevek. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

1;
__END__;
