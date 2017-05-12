#!/usr/bin/perl

package Class::Workflow::Instance::Simple;
use Moose;

with "Class::Workflow::Instance";

has error => (
	isa => "Undef|Str|Object",
	is  => "ro",
);

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::Instance::Simple - A Workflow instance objects to work with
the other ::Simple classes.

=head1 SYNOPSIS

	use Class::Workflow::Instance::Simple;

	my $i = Class::Workflow::Instance::Simple->new;

	my $new_i = $transition->apply( $i );

=head1 DESCRIPTION

This method adds an error field to L<Class::Workflow::Instance>.

In the event that you want to make errors non-fatal, but instead encapsulate
errors in the workflow using their own states, C<error> just becomes a regular
field. L<Class::Workflow::Transition::Validate::Simple> provides a simple means
to add validation, with the optional notion of an C<error_state> for
transitions.

=head1 FIELDS

=over 4

=item error

Does what it says.

See L<Class::Workflow::Transition::Validate::Simple>.

=back

=cut


