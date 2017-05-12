package AI::ExpertSystem::Simple::Rule;

use strict;
use warnings;

our $VERSION = '1.2';

sub new {
	my ($class, $name) = @_;

	die "Rule->new() takes 1 argument" if(scalar(@_) != 2);
	die "Rule->new() argument 1 (NAME) is undefined" if(!defined($name));

	my $self = {};

	$self->{_name} = $name;
	$self->{_conditions} = ();
	$self->{_tested} = ();
	$self->{_counter} = 0;
	$self->{_actions} = ();
	$self->{_state} = 'active';

	return bless $self, $class;
}

sub reset {
	my ($self) = @_;

	# Check the input

	die "Rule->reset() takes no arguments" if scalar(@_) != 1;

	$self->{_state} = 'active';
	$self->{_counter} = 0;

	foreach my $name (keys %{$self->{_tested}}) {
		$self->{_tested}->{$name} = 0;
		$self->{_counter}++;
	}
}

sub add_condition {
	my ($self, $name, $value) = @_;

	die "Rule->add_condition() takes 2 arguments" if(scalar(@_) != 3);
	die "Rule->add_condition() argument 1 (NAME) is undefined" if(!defined($name));
	die "Rule->add_condition() argument 2 (VALUE) is undefined" if(!defined($value));

	if(defined($self->{_conditions}->{$name})) {
		die "Rule->add_condition() has already been set";
	}

	$self->{_conditions}->{$name} = $value;
	$self->{_tested}->{$name} = 0;
	$self->{_counter}++;
}

sub add_action {
	my ($self, $name, $value) = @_;

	die "Rule->add_action() takes 2 arguments" if(scalar(@_) != 3);
	die "Rule->add_action() argument 1 (NAME) is undefined" if(!defined($name));
	die "Rule->add_action() argument 2 (VALUE) is undefined" if(!defined($value));

	if(defined($self->{_actions}->{$name})) {
		die "Rule->add_action() has already been set";
	}

	$self->{_actions}->{$name} = $value;
}

sub name {
	my ($self) = @_;

	die "Rule->name() takes no arguments" if(scalar(@_) != 1);

	return $self->{_name};
}

sub state {
	my ($self) = @_;

	die "Rule->state() takes no arguments" if(scalar(@_) != 1);

	return $self->{_state};
}

sub given {
	my ($self, $name, $value) = @_;

	die "Rule->given() takes 2 arguments" if(scalar(@_) != 3);
	die "Rule->given() argument 1 (NAME) is undefined" if(!defined($name));
	die "Rule->given() argument 2 (VALUE) is undefined" if(!defined($value));

	if(defined($self->{_conditions}->{$name})) {
		if($self->{_tested}->{$name} == 1) {
			# Already done this one
		} elsif($self->{_conditions}->{$name} eq $value) {
			$self->{_tested}->{$name} = 1;
			$self->{_counter}--;
			if($self->{_counter} == 0) {
				$self->{_state} = 'completed';
			}
		} else {
			$self->{_state} = 'invalid';
		}
	}

	return $self->{_state};
}

sub actions {
	my ($self) = @_;

	die "Rule->actions() takes no arguments" if(scalar(@_) != 1);

	return %{$self->{_actions}};
}

sub conditions {
	my ($self) = @_;

	die "Rule->conditions() takes no arguments" if(scalar(@_) != 1);

	return %{$self->{_conditions}};
}

sub unresolved {
	my ($self) = @_;

	die "Rule->unresolved() takes no arguments" if(scalar(@_) != 1);

	my @list = ();

	foreach my $name (keys(%{$self->{_tested}})) {
		if($self->{_tested}->{$name} == 0) {
			push(@list, $name);
		}
	}

	return @list;
}

1;

=head1 NAME

AI::ExpertSystem::Simple::Rule - A utility class for a simple expert system

=head1 VERSION

This document refers to verion 1.2 of AI::ExpertSystem::Simple::Rule, released June 10, 2003

=head1 SYNOPSIS

This is a utility class for AI::ExpertSystem::Simple

=head1 DESCRIPTION

=head2 Overview

This class handles the rules

=head2 Constructors and initialisation

=over 4

=item new( NAME )

The constructor takes one argument, the NAME of the rule. The consition and actions are added later.

=back

=head2 Public methods

=over 4

=item reset( )

Resets the state of the rule back to active and all the condition attributes to untested.

=item add_condition( NAME, VALUE )

This adds a condition attribute name / value pair.

=item add_action( NAME, VALUE )

This adds an action attribute name / value pair.

=item name( )

Returns the name of the rule.

=item state( )

Returns the current state of the rule.

=item given( NAME, VALUE )

The NAME / VALUE attribute pair is checked against the rule's conditions to see if a condition is met and the state of the rule 
is changed in light of the result.

=item actions( )

Returns a list of the actions set in the rule.

=item conditions( )

Returns a list of the conditions matched in the rule.

=item unresolved( )

Returns a list of all the unresolved condition of the rule.

=back

=head2 Private methods

None

=head1 ENVIRONMENT

None

=head1 DIAGNOSTICS

=over 4

=item Rule->new() takes 1 argument

When the constructor is initialised it requires one argument. This message is given if more or less arguments were supplied.

=item Rule->new() argument 1 (NAME) is undefined

The corrct number of arguments were supplied to the constructor, however the first argument, NAME, was undefined.

=item Rule->reset() takes no arguments

When the method is called it requires no arguments. This message is given if more or less arguments were supplied.

=item Rule->add_condition() takes 2 arguments

When the method is called it requires two arguments. This message is given if more or less arguments were supplied.

=item Rule->add_condition() argument 1 (NAME) is undefined

The corrct number of arguments were supplied with the method call, however the first argument, NAME, was undefined.

=item Rule->add_condition() argument 2 (VALUE) is undefined

The corrct number of arguments were supplied with the method call, however the second argument, VALUE, was undefined.

=item Rule->add_condition() has already been set

This method has already been called and the value set. It cannot be called twice.

=item Rule->add_action() takes 2 arguments

When the method is called it requires two arguments. This message is given if more or less arguments were supplied.

=item Rule->add_action() argument 1 (NAME) is undefined

The corrct number of arguments were supplied with the method call, however the first argument, NAME, was undefined.

=item Rule->add_action() argument 2 (VALUE) is undefined

The corrct number of arguments were supplied with the method call, however the second argument, VALUE, was undefined.

=item Rule->add_action() has already been set

This method has already been called and the value set. It cannot be called twice.

=item Rule->name() takes no arguments

When the method is called it requires no arguments. This message is given if more or less arguments were supplied.

=item Rule->state() takes no arguments

When the method is called it requires no arguments. This message is given if more or less arguments were supplied.

=item Rule->given() takes 2 arguments

When the method is called it requires two arguments. This message is given if more or less arguments were supplied.

=item Rule->given() argument 1 (NAME) is undefined

The corrct number of arguments were supplied with the method call, however the first argument, NAME, was undefined.

=item Rule->given() argument 2 (VALUE) is undefined

The corrct number of arguments were supplied with the method call, however the second argument, VALUE, was undefined.

=item Rule->actions() takes no arguments

When the method is called it requires no arguments. This message is given if more or less arguments were supplied.

=item Rule->conditions() takes no arguments

When the method is called it requires no arguments. This message is given if more or less arguments were supplied.

=item Rule->unresolved() takes no arguments

When the method is called it requires no arguments. This message is given if more or less arguments were supplied.

=back

=head1 BUGS

None

=head1 FILES

See Rules.t in the test directory

=head1 SEE ALSO

AI::ExpertSystem::Simple - The base class for the expert system

AI::ExpertSystem::Simple::Goal - A utility class

AI::ExpertSystem::Simple::knowledge - A utility class

=head1 AUTHORS

Peter Hickman (peterhi@ntlworld.com)

=head1 COPYRIGHT

Copyright (c) 2003, Peter Hickman. All rights reserved.

This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.
