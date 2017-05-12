#!/usr/bin/perl

package Class::Workflow::State;
use Moose::Role;

requires "transitions"; # enumerate the transitions

requires "has_transition";
requires "has_transitions";

sub accept_instance {
	my ( $self, $instance, @args ) = @_;
	return $instance;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::State - An instance's position in the workflow.

=head1 SYNOPSIS

	package MyState;
	use Moose;

	with 'Class::Workflow::State';

=head1 DESCRIPTION

This is an abstract role for state implementations. In order ot work properly all states

=head1 METHODS

=over 4

=item accept_instance

Since this method is probably not going to be used an empty version is
supplied. You may override it, but be sure to return the instance (either the
one you got, or if you applied cascaded transitions, the one that you made).

Look in L<Class::Workflow::State::AcceptHooks> for an example of how this can
be used.

=back

=head1 REQUIRED METHODS

=over 4

=item has_transition

=item has_transitions

Whether or not the state contains the transition B<object> (or objects). You
can add more behaviors but it should B<always> work for transition objects.

=item transitions

This method should return the list of all transition objects. You may add more
methods that return the transitions in another organization, but make sure that
this method called with no arguments will always return the transitions. When
this method is called with arguments it should set the transition list to the
new list, or die if the operation is not supported.

=back

=cut


