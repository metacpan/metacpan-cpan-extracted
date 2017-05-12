package AI::ExpertSystem::Simple::Knowledge;

use strict;
use warnings;

our $VERSION = '1.2';

sub new {
	my ($class, $name) = @_;

    die "Knowledge->new() takes 1 argument" if scalar(@_) != 2;
    die "Knowledge->new() argument 1, (NAME) is undefined" if ! defined($name);

	my $self = {};

	$self->{_name} = $name;
	$self->{_value} = undef;
	$self->{_setter} = undef;
	$self->{_question} = undef;
	$self->{_responses} = ();

	return bless $self, $class;
}

sub reset {
	my ($self) = @_;

	die "Knowledge->reset() takes no arguments" if scalar(@_) != 1;

	$self->{_value} = undef;
	$self->{_setter} = undef;
}

sub set_value {
	my ($self, $value, $setter) = @_;

    die "Knowledge->set_value() takes 2 argument" if scalar(@_) != 3;
    die "Knowledge->set_value() argument 1, (VALUE) is undefined" if ! defined($value);
    die "Knowledge->set_value() argument 2, (SETTER) is undefined" if ! defined($setter);

	if(defined($self->{_value})) {
		die "Knowledge->set_value() has already been set";
	}

	$self->{_value} = $value;
	$self->{_setter} = $setter;
}

sub get_value {
	my ($self) = @_;

        die "Knowledge->get_value() takes no arguments" if scalar(@_) != 1;

	return $self->{_value};
}

sub get_setter {
	my ($self) = @_;

	die "Knowledge->get_setter() takes no arguments" if scalar(@_) != 1;

	return $self->{_setter};
}

sub is_value_set {
	my($self) = @_;

        die "Knowledge->is_value_set() takes no arguments" if scalar(@_) != 1;

	return defined($self->{_value});
}

sub set_question {
	my ($self, $question, @responses) = @_;

	if(defined($self->{_question})) {
		die "Knowledge->set_question() has already been set";
	}

        die "Knowledge->set_question() takes 2 arguments" if scalar(@_) < 3;
        die "Knowledge->set_question() argument 1, (QUESTION) is undefined" if ! defined($question);
#		This test just doesnt work for a list
#		die "Knowledge->set_question() argument 2, (RESPONSES) is undefined" if scalar(@responses) == 0;

	$self->{_question} = $question;
	push(@{$self->{_responses}}, @responses);
}

sub get_question {
	my ($self) = @_;

        die "Knowledge->get_question() takes no arguments" if scalar(@_) != 1;

	if(!defined($self->{_question})) {
		die "Knowledge->set_question() has not been set";
	}

	return ($self->{_question}, @{$self->{_responses}});
}

sub has_question {
	my ($self) = @_;

        die "Knowledge->has_question() takes no arguments" if scalar(@_) != 1;

	return (defined($self->{_question}) and !defined($self->{_value}));
}

sub name {
	my ($self) = @_;

        die "Knowledge->name() takes no arguments" if scalar(@_) != 1;

	return $self->{_name};
}

1;

=head1 NAME

AI::ExpertSystem::Simple::Knowledge - Utility class for a simple expert system

=head1 VERSION

This document refers to verion 1.2 of AI::ExpertSystem::Simple::Knowledge, released June 10, 2003

=head1 SYNOPSIS

This class handles the attributes and their values within the expert system along with the optional question that
can be asked of the user to set the value of the attribute. The valid responses to the optional question are also held.

=head1 DESCRIPTION

=head2 Overview

This is a utility class for AI::ExpertSystem::Simple

=head2 Constructors and initialisation

=over 4

=item new( NAME )

The constructor sets up the basic attribute name / value pairing. In the base case an attribute has a name with no value.

Optional questions and the valid responses can be set later and the value of the attribute is set during the consultation.

=back

=head2 Public methods

=over 4

=item reset( )

Resets the state of knowledge back to what it was when the object was created

=item set_value( VALUE, SETTER )

During the consultation process the VALUE for an attribute can be set by either asking the user a question or by deduction. The value is then recorded along with the rule that set the value (or blank it if was a question).

=item get_value( )

Returns the current value of the attribute.

=item get_setter( )

Returns the current setter of the attribute.

=item is_value_set( )

Returns true if the value of the attribute is set or false if not.

=item set_question( QUESTION, RESPONSES )

Allows a question to ask of the user to set the value of the attribute. QUESTION is the text that will be displayed to the user and RESPONSES is a list of valid responses that the user may select from.

=item get_question( )

Returns the QUESTION and list of valid RESPONSES for the attribute.

=item has_question( )

Returns true if the attribute has a question to ask the user if the VALUE of the attribute has not already been set.

=item name( )

This method returns the value of the NAME argument that was set when the object was constructed.

=back

=head2 Private methods

None

=head1 ENVIRONMENT

None

=head1 DIAGNOSTICS

=over 4

=item Knowledge->new() takes 1 argument

When the constructor is initialised it requires one argument. This message is given if more of less arguments are given.

=item Knowledge->new() argument 1, (NAME) is undefined

The correct number of arguments were supplied to the constructor, however the first argument, NAME, was undefined.

=item Knowledge->reset() takes no arguments

When the method is called it requires no arguments. This message is given if some where supplied.

=item Knowledge->set_value() takes 2 argument

When the method is called it requires two arguments. This message is given if more of less arguments are given.

=item Knowledge->set_value() argument 1, (VALUE) is undefined

The correct number of arguments were supplied to the method call, however the first argument, VALUE, was undefined.

=item Knowledge->set_value() argument 2, (SETTER) is undefined

The correct number of arguments were supplied to the method call, however the second argument, SETTER, was undefined.

=item Knowledge->set_value() has already been set

This method has already been called and the value set. It cannot be called twice.

=item Knowledge->get_value() takes no arguments

When the method is called it requires no arguments. This message is given if some where supplied.

=item Knowledge->get_setter() takes no arguments

When the method is called it requires no arguments. This message is given if some where supplied.

=item Knowledge->is_value_set() takes no arguments

When the method is called it requires no arguments. This message is given if some where supplied.

=item Knowledge->set_question() takes 2 arguments

When the method is called it requires two arguments. This message is given if more of less arguments are given.

=item Knowledge->set_question() argument 1, (QUESTION) is undefined

The correct number of arguments were supplied to the method call, however the first argument, QUESTION, was undefined.

=item Knowledge->set_question() has already been set

This method has already been called and the value set. It cannot be called twice.

=item Knowledge->get_question() takes no arguments

When the method is called it requires no arguments. This message is given if some where supplied.

=item Knowledge->get_question() has not been set

The value has not been set by Knowledge->set_question() and, therefore, cannot be retrieved.

=item Knowledge->has_question() takes no arguments

When the method is called it requires no arguments. This message is given if some where supplied.

=item Knowledge->name() takes no arguments

When the method is called it requires no arguments. This message is given if some where supplied.

=back

=head1 BUGS

None

=head1 FILES

See Knowledge.t in the test directory

=head1 SEE ALSO

AI::ExpertSystem::Simple - The base class for the expert system shell

AI::ExpertSystem::Simple::Goal - A utility class

AI::ExpertSystem::Simple::Rules - A utility class

=head1 AUTHORS

Peter Hickman (peterhi@ntlworld.com)

=head1 COPYRIGHT

Copyright (c) 2003, Peter Hickman. All rights reserved.

This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.
