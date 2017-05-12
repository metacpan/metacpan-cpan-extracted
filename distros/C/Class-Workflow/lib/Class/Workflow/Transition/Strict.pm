#!/usr/bin/perl

package Class::Workflow::Transition::Strict;
use Moose::Role;

before apply => sub {
	my ( $self, $instance, @args ) = @_;
	my $state = $instance->state;

	unless ( $state->has_transition( $self ) ) {
		die "$self is not in $instance\'s current state ($state)"
	}
};

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::Transition::Strict - Verify that the transition is in the
instance's current state before applying.

=head1 SYNOPSIS

	package MyTransition;
	use Moose;

	with qw/
		Class::Workflow::Transition
		Class::Workflow::Transition::Strict
	/;

=head1 DESCRIPTION

This mixin role provides a L<Moose/before> wrapper around the C<apply> method,
that verifies that the transition is present in the current state of the
instance.

Normally you use the state introspection methods to retrieve transition
objects from the state of the instance directly, but this role adds an extra
level of protection.

=cut


