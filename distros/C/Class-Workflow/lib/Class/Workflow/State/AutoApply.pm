#!/usr/bin/perl

package Class::Workflow::State::AutoApply;
use Moose::Role;

use Carp qw/croak/;
use Scalar::Util qw/refaddr/;

has auto_transition => (
	does      => "Class::Workflow::Transition",
	accessor  => "auto_transition",
	predicate => "has_auto_transition",
	required  => 0,
);

around transitions => sub {
	my $next = shift;
	my ( $self, @transitions ) = @_;

	my @ret = $self->$next( @transitions );

	# if the auto transition was not in ->transitions( @set ) then delete it
	if ( @transitions and my $auto = $self->auto_transition ) {
		$self->auto_transition(undef) unless grep { $_ == $auto } @transitions;
	}

	if ( my $auto = $self->auto_transition ) {
		return $auto, @ret;
	} else {
		return @ret;
	}
};

around has_transition => sub {
	my $next = shift;
	my ( $self, $transition ) = @_;

	if ( my $auto = $self->auto_transition ) {
		if ( ref $transition ) {
			return 1 if refaddr($auto) == refaddr($transition);
		} else {
			return 1 if $auto->can("name") and $auto->name eq $transition;
		}
	}

	return $self->$next($transition);
};

around accept_instance => sub {
	my $next = shift;
	my ( $self, $orig_instance, @args ) = @_;
	my $instance = $self->$next( $orig_instance, @args );

	return $self->apply_auto_transition( $instance, @args ) || $instance;
};

sub apply_auto_transition {
	my ( $self, $instance, @args ) = @_;

	if ( my $auto_transition = $self->auto_transition ) {
		return $auto_transition->apply( $instance, @args );
	}

	return;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::State::AutoApply - Automatically apply a transition upon
arriving into a state.

=head1 SYNOPSIS

	package MyState;
	use Moose;

	with qw/Class::Workflow::State::AutoApply/;
	
	my $state = Mystate->new( auto_transition => $t );

	my $i2 = $state->accept_instance( $i, @args ); # automatically calls $t->apply( $i, @args )

=head1 DESCRIPTION

This state role is used to automatically apply a transition

=head1 PARTIAL TRANSITIONS

If an auto-application may fail validation or something of the sort you can do
something like:

	around apply_auto_transition => sub {
		my $next = shift;
		my ( $self, $instance, @args ) = @_;

		eval { $self->$next( $instance, @args ) }

		die $@ unless $@->isa("SoftError");
	}

If apply_auto_transition returns a false value then the original instance will
be returned automatically, at which point the intermediate state is the current
state.

=cut


