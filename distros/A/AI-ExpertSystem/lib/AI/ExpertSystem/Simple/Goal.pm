package AI::ExpertSystem::Simple::Goal;

use strict;
use warnings;

our $VERSION = '1.0';

sub new {
	my ($class, $name, $message) = @_;

	# Check the input

	die "Goal->new() takes 2 arguments" if scalar(@_) != 3;
	die "Goal->new() argument 1 (NAME) is undefined" if ! defined($name);
	die "Goal->new() argument 2 (MESSAGE) is undefined" if ! defined($message);

	# All OK, create the object

	my $self = {};

	$self->{_name} = $name;
	$self->{_message} = $message;

	return bless $self, $class;
}

sub is_goal {
	my ($self, $name) = @_;

	# Check the input

	die "Goal->is_goal() takes 1 argument" if scalar(@_) != 2;
	die "Goal->is_goal() argument 1 (NAME) is undefined" if ! defined($name);

	# All OK, do the stuff

	return $self->{_name} eq $name;
}

sub name {
	my ($self) = @_;

	# Check the input

	die "Goal->name() takes no arguments" if scalar(@_) != 1;

	# All OK, do the stuff

	return $self->{_name};
}

sub answer {
	my ($self, $value) = @_;

	# Check the input

	die "Goal->answer() takes 1 argument" if scalar(@_) != 2;
	die "Goal->answer() argument 1 (VALUE) is undefined" if ! defined($value);

	# All OK, do the stuff

	my @text = ();

	foreach my $word (split('\s', $self->{_message})) {
		if($word eq $self->{_name}) {
			push(@text, $value);
		} else {
			push(@text, $word);
		}
	}

	return join(' ', @text);
}

1;

=head1 NAME

AI::ExpertSystem::Simple::Goal - Utility class for a simple expert system

=head1 VERSION

This document refers to verion 1.00 of AI::ExpertSystem::Simple::Goal, released April 25, 2003

=head1 SYNOPSIS

This class handles the goal in the expert system and returns the answer when the goal is matched.

=head1 DESCRIPTION

=head2 Overview

This is a utility class for AI::ExpertSystem::Simple

=head2 Constructors and initialisation

=over 4

=item new( NAME, MESSAGE )

The constructor takes two arguments. The first, NAME, is the name of the attribute that when set will
trigger the end of the consoltation. The second argument, MESSAGE, is the text that will be interpolated
as the answer for the consoltation.

=back

=head2 Public methods

=over 4

=item is_goal( NAME )

This method compares the given NAME with that of the attribute name given when the object was constructed and
returns true if they are the same or false if not.

=item name( )

This method return the value of the NAME argument that was set when the object was constructed.

=item answer( VALUE )

This method take VALUE to be the value of the goal attribute and will use it to interpolate and return the MESSAGE that was given 
when the object was constructed.

=back

=head2 Private methods

None

=head1 ENVIRONMENT

None

=head1 DIAGNOSTICS

=over 4

=item Goal->new() takes 2 arguments

When the constructor is initialised it requires two arguments. This message is given if more or less arguments were supplied.

=item Goal->new() argument 1 (NAME) is undefined

The correct number of arguments were supplied to the constructor, however the first argument, NAME, was undefined.

=item Goal->new() argument 2 (MESSAGE) is undefined

The correct number of arguments were supplied to the constructor, however the second argument, MESSAGE, was undefined.

=item Goal->is_goal() takes 1 argument

When the method is called it requires one argument. This message is given if more or less arguments were supplied.

=item Goal->is_goal() argument 1 (NAME) is undefined

The correct number of arguments were supplied with the method call, however the first argument, NAME, was undefined.

=item Goal->name() takes no arguments

When the method is called it takes no arguments. This message is given if some were supplied.

=item Goal->answer() takes 1 argument

When the method is called it requires one argument. This message is given if more or less arguments were supplied.

=item Goal->answer() argument 1 (VALUE) is undefined

The correct number of arguments were supplied with the method call, however the first argument, VALUE, was undefined.

=back

=head1 BUGS

None to date

=head1 FILES

See Goal.t in the test directory

=head1 SEE ALSO

AI::ExpertSystem::Simple - The base class for the expert system shell

AI::ExpertSystem::Simple::Knowledge - A utility class

AI::ExpertSystem::Simple::Rules - A utility class

=head1 AUTHORS

Peter Hickman (peterhi@ntlworld.com)

=head1 COPYRIGHT

Copyright (c) 2003, Peter Hickman. All rights reserved.

This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.
