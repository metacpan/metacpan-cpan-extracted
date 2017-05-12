#!/usr/bin/perl

package Class::Workflow::State::AcceptHooks;
use Moose::Role;

has hooks => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default    => sub { [] },
);

sub clear_hooks {
	my $self = shift;
	$self->hooks( [] );
}

sub add_hook {
	my ( $self, $hook ) = @_;
	$self->add_hooks( $hook );
}

sub add_hooks {
	my ( $self, @hooks ) = @_;
	push @{ $self->hooks }, @hooks;
}

after accept_instance => sub {
	my ( $self, $instance, @args ) = @_;
	$_->( $instance, @args ) for $self->hooks;
};

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::State::AcceptHooks - Add hooks that are fired when the state
accepts an instance.

=head1 SYNOPSIS

	use Class::Workflow::State::AcceptHooks;

=head1 DESCRIPTION

When an instance enters a state it is sometimes convenient to call hooks, for
e.g. notification or logging purposes.

These hooks should not have any side effect that directly affects the workflow
instance in any way - for that functionality you should use transitions.

Hooks' returns values are thus ignored.

=head1 METHODS

=over 4

=item add_hook

=item add_hooks

Add hooks. These should be sub references.

=item clear_hooks

Clear the list of hooks.

=item hooks

Get the list of registered hooks.

=back

=head1 AUGMENTED METHODS

=over 4

=item accept_instance

This method has an C<after> hook that calls the hooks in the order of their definition.

=back

=cut


