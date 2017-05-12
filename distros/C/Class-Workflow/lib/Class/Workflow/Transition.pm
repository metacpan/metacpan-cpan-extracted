#!/usr/bin/perl

package Class::Workflow::Transition;
use Moose::Role;

use Carp qw/croak/;

requires "apply";

sub derive_and_accept_instance {
	my ( $self, $proto_instance, $attrs, @args ) = @_;

	croak "You must specify the next state of the instance"
		unless $attrs->{state};

	my $state = $attrs->{state};

	my $instance = $proto_instance->derive(
		transition => $self,
		%$attrs,
	);

	return $state->accept_instance( $instance, @args );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::Transition - A function over an instance.

=head1 SYNOPSIS

	package MyTransition;
	use Moose;
	with 'Class::Workflow::Transition';

=head1 DESCRIPTION

This is the base role for transition implementations.

B<every> transition object must comply to it's interface, and furthermore must
also use the C<derive_and_accept_instance> method to return a derived instance
at the end of the operation.

=head1 METHODS

=over 4

=item derive_and_accept_instance $instance, \%attrs, @args

This method calls C<< $instance->derive >> with the attrs, and then calls the
instance C<accept_instance> on the new instance's state.

C<%attrs> B<must> contain the key C<state>, which should do the role
L<Class::Workflow::State>.

@args are passed (along with the derived instance) to
L<Class::Workflow::State/accept_instance>.

=back

=head1 REQUIRED METHODS

=over 4

=item apply $insatnce, @args

This method accepts a L<Class::Workflow::Instance> as it's first argument, and
is expected to call
C<< $self->derive_and_accept_instance( $instance, \%attrs, @args ) >>, with
C<%attrs> containing the state that the instance is being transferred to (it
doesn't have to be different than the current state).

=back

=cut


