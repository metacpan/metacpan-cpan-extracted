#!/usr/bin/perl

package Class::Workflow::State::Simple;
use Moose;

use overload '""' => "stringify", fallback => 1;

# FIXME with Class::Workflow::State should be implied
with qw/
	Class::Workflow::State
	Class::Workflow::State::TransitionHash
	Class::Workflow::State::AcceptHooks
	Class::Workflow::State::AutoApply
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

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::State::Simple - A useful class (or base class) for writing
states.

=head1 SYNOPSIS

	use Class::Workflow::State::Simple;

	my $state = Class::Workflow::State::Simple->new(
		name => "foo",
		transitions => [ $tn ], # objects
	);

=head1 DESCRIPTION

=head1 FIELDS

=over 4

=item name

A string that can be used to identify the state to a factory object like
L<Class::Workflow>.

=item auto_transition

see L<Class::Workflow::State::AutoApply>.

=back

=head1 ROLES

This class consumes the following roles:

=over 4

=item *

L<Class::Workflow::State::TransitionSet>

=item *

L<Class::Workflow::State::AcceptHooks>

=back

=cut


