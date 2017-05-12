#!/usr/bin/perl

package Class::Workflow::Transition::Simple;
use Moose;

use overload '""' => "stringify", fallback => 1;

# FIXME with Class::Workflow::Transition should not be necessary
with qw/
	Class::Workflow::Transition
	Class::Workflow::Transition::Deterministic
	Class::Workflow::Transition::Strict
	Class::Workflow::Transition::Validate::Simple
/;

has name => (
	isa => "Str",
	is  => "rw",
);

sub stringify {
	my $self = shift;
	if ( defined( my $name = $self->name ) ) {
		return $name;
	}
	return overload::StrVal($_[0]);
}

has misc => (
	isa => "HashRef",
	is  => "rw",
	default    => sub { {} },
	auto_deref => 1,
);

has body => (
	isa => "CodeRef",
	is  => "rw",
	default => sub { sub { return () } },
);

has set_fields => (
	isa => "HashRef",
	is  => "rw",
	default => sub { {} },
);

# if set_fields is set it overrides body_sets_fields
has body_sets_fields => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

sub apply_body {
	my ( $self, $instance, @args ) = @_;
	my $body = $self->body;

	# if we have a predefined set of fields
	unless ( $self->body_sets_fields ) {
		return (
			$self->set_fields,
			$self->$body( $instance, @args ),
		);
	} else {
		# otherwise let the body control everything
		return $self->$body( $instance, @args );
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::Transition::Simple - A useful class (or base class) for
writing transitions.

=head1 SYNOPSIS

	use Class::Workflow::Transition::Simple;

	my $t = Class::Workflow::Transition::Simple->new(
		name           => "feed",
		to_state       => $not_hungry, # Class::Workflow::Transition::State
		body_sets_fields => 1,
		body           => sub {
			my ( $self, $instance, @args ) = @_;

			my $remain = $global_food_warehouse->reduce_quantity;

			return (
				remaining_food => $remain,
			);
		},
	);

=head1 DESCRIPTION

=head1 FIELDS

=over 4

=item name

This is just a string. It can be used to identify the transition in a parent
object like C<Class::Workflow> if any.

=item to_state

This is the state the transition will transfer to. This comes from
C<Class::Workflow::Transition::Deterministic>.

=item body

This is an optional sub (it defaults to C<<sub { }>>) which will be called
during apply, after all validation has passed.

The body is invoked as a method on the transition.

See C<body_sets_fields> for the semantics of the return value.

=item body_sets_fields

When true, then the body is expected to return a hash of fields to override in
the instance. See L<Class::Workflow::Transition::Deterministic> for details.

This field is present to avoid writing code like this:

	return ( {}, @return_values );

When you don't want to set fields in the instance.

Defaults to false (just write return @return_value, set to true to set fields).

See also C<set_fields>.

=item set_fields

This field is a hash ref that will be used as the list of fields to set on the
instance when C<body_sets_fields> is false.

If your transition does not need to dynamically set fields you should probably
use this.

Defaults to C<{}>.

=item validate

=item validators

=item clear_validators

=item add_validators

These methods come from L<Class::Workflow::Transition::Validate::Simple>.

=back

=head1 ROLES

This class consumes the following roles:

=over 4

=item *

L<Class::Workflow::Transition::Deterministic>

=item *

L<Class::Workflow::Transition::Strict>

=item *

L<Class::Workflow::Transition::Validate::Simple>

=back

=cut


