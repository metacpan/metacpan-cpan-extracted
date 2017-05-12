#!/usr/bin/perl

package Class::Workflow::Transition::Validate::Simple;
use Moose::Role;

with qw/
	Class::Workflow::Transition
	Class::Workflow::Transition::Validate
/;

has error_state => (
	does => "Class::Workflow::State",
	is   => "rw",
);

has no_die => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has validators => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default    => sub { [] },
);

has ignore_validator_rv => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

sub add_validators {
	my ( $self, @validators ) = @_;
	push @{ $self->validators }, @validators;
}

sub clear_validators {
	my $self = shift;
	$self->validators([]);
}

sub validate {
	my ( $self, $instance, @args ) = @_;

	my $ignore_rv = $self->ignore_validator_rv;

	my @errors;
	foreach my $validator ( $self->validators ) {
		local $@;
		my $ok = eval { $self->$validator( $instance, @args ) };

		if ( $@ ) {
			push @errors, $@;
		} elsif ( !$ignore_rv and !$ok ) {
			push @errors, "general error";
		}
	}

	s/ at .* line \d+\.\n//s for @errors;

	die join(", ", @errors) . "\n" if @errors;
	# FIXME add @errors to an exception object that stringifies

	return 1;
}

sub validation_error {
	my ( $self, $error, $instance, @args ) = @_;
	chomp $error unless ref $error;

	if ( my $state = $self->error_state ) {
		return $self->derive_and_accept_instance(
			$instance => {
				state => $state,
				error => $error
			},
			@args
		);
	} else {
		if ( $self->no_die ) {
			return $self->derive_and_accept_instance(
				$instance => {
					state => $instance->state,
					error => $error,
				},
				@args
			);
		} else {
			die $error;
		}
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::Transition::Validate::Simple - Easier validation code.

=head1 SYNOPSIS

	package MyTransition;
	use Moose;

	with qw/Class::Workflow::Transition::Validate::Simple/;

	# ...

	$t->clear_validators;
	$t->add_validators( sub { ... } );

=head1 DESCRIPTION

=head1 FIELDS

=over 4

=item ignore_validator_rv

This is useful if your validators only throw exceptions.

Defaults to false

=item error_state

This contains a state that will be moved to if a validation error occurs.

In conjunction with L<Class::Workflow::State::AutoApply> this can work like a
catch block.

The instance will have the C<error> attribute set.

=item no_die

If this is set, C<validation_error> will not die even if C<error_state> is
not set.

The instance will have the C<error> attribute set, and will be reaccepted into
it's current state, with the error.

=back

=head1 METHODS

=over 4

=item validators

This is an optional list of sub refs which will be called to validate input
before applying C<body>.

They should raise an exception or return a false value if the input is bad.

They may put validation result information inside the
L<Class::Workflow::Context> or equivalent, if one is used.

A more comprehensive solution is to override the C<validate> method yourself
and provide rich exception objects with validation error descriptors inside
them.

The validators are invoked as methods on the transition.

IF C<ignore_validator_rv> is true then only exceptions are considered input
validations.

=item add_validators @code_refs

=item clear_validators

Modify the list of validators.

=back

=head1 ROLES

This role consumes the following roles:

=over 4

=item *

L<Class::Workflow::Transition::Validate>

=back

=cut


