#!/usr/bin/perl

package Class::Workflow::State::TransitionHash;
use Moose::Role;

use Carp qw/croak/;

with qw/
	Class::Workflow::State
	Class::Workflow::State::TransitionSet
/;

has transition_hash => (
	isa => "HashRef",
	is  => "rw",
	default => sub { {} },
);

after "BUILDALL" => sub {
	my $self = shift;
	$self->_reindex_hash;
};

sub _reindex_hash {
	my $self = shift;
	my @transitions = $self->transitions;

	for ( @transitions ) {
		blessed($_)
			or croak (($_||'') . " is not an object");

		$_->can("name")
			or croak "All transitions registered with a hash based state must know their own name";
	}

	$self->transition_hash({ map { $_->name => $_ } @transitions });
}

after transitions => sub {
	my ( $self, @transitions ) = @_;

	if ( @transitions ) {
		$self->_reindex_hash;
	}
};

after clear_transitions => sub {
	my $self = shift;
	$self->transition_hash({});
};

after qw/remove_transitions add_transitions/ => sub {
	my $self = shift;
	$self->_reindex_hash;
};

around has_transition => sub {
	my $next = shift;
	my ( $self, $transition ) = @_;
	if ( blessed( $transition ) ) {
		return $self->$next( $transition );
	} else {
		return exists $self->transition_hash->{$transition};
	}
};

around has_transitions => sub {
	my $next = shift;
	my ( $self, @transitions ) = @_;

	foreach my $t ( @transitions ) {
		return unless $self->has_transition( $t );
	}

	return 1;
};

sub get_transition {
	my ( $self, $transition ) = @_;
	return ( blessed($transition) ? $transition : $self->transition_hash->{$transition} );
}

sub get_transitions {
	my ( $self, @transitions ) = @_;

	if ( @transitions ) {
		return map { $self->get_transition( $_ ) } @transitions;
	} else {
		return $self->transitions;
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::State::TransitionHash - Implement transition metadata with a
hash.

=head1 SYNOPSIS

	package MyState;
	use Moose;

	with qw/Class::Workflow::State::TransitionHash/;

=head1 DESCRIPTION

This is a concrete role that implements C<transitions>, C<has_transition> and
C<has_transitions> as required by L<Class::Workflow::State>, and adds
C<add_transitions>, C<remove_transitions>, C<clear_transitions> ,
C<get_transitions>, and C<get_transition> as well.

Transition storage is implemented internally with L<Set::Object>.

This is an additional layer over L<Class::Workflow::State::TransitionSet> that
requires all transitions to respond to the C<name> method, but as a bonus
allows you to refer to your transitions by name or by value.

=head1 METHODS

See L<Class::Workflow::State::TransitionSet> and L<Class::Workflow::State>.

=over 4

=item get_transition $name

=item get_transitions @names

These methods allow you to pass in either a name or an object, and always get
back an object (unless the transition by that name does not exist, in which
case you get an undefined value).

=back

=cut


