#!/usr/bin/perl

package Class::Workflow::Context;
use Moose;

has stash => (
	isa     => "HashRef",
	is      => "rw",
	default => sub { {} },
);

__PACKAGE__;

__END__

=pod

=head1 NAME

Class::Workflow::Context - The context in which a transition is being applied
(optional).

=head1 SYNOPSIS

	use Class::Workflow::Context; # or a subclass or something

	my $c = Class::Workflow::Context->new( ... );

	my $new_instance = $transition->apply( $instance, $c );

=head1 DESCRIPTION

If you need to pass arbitrary arguments to the workflow, a context object will
usually help.

This specific context object provides C<stash>, a writable hash which is
essentially free-for-all.

L<Class::Workflow::Context> doesn't provide much and should generally be
subclassed. It is designed to resemble the L<Catalyst> context object.

Usage of a context object is completely optional, and L<Class::Workflow>'s
other core objects (L<Class::Workflow::State>, L<Class::Workflow::Transition>,
and L<Class::Workflow::Instance> really don't care about context objects at
all).

=head1 STYLE GUIDE

When writing a workflow that governs a web application, for example,
transitions will generally expect explicit parameters, having to do with their
specific responsibility, and more "global" parameters, like on behalf of which
user is this transition being applied.

A context object is a way to provide a standard set of facilities that every
transition can expect.

	sub apply {
		my ( $self, $instance, $c, %args ) = @_;

		my $arg = $args{arg_i_care_about};

		my $user = $c->user;

		...
	}

Conceptually C<$c> is akin to the environment the workflow is being used in,
wheras C<%args> are the actual parameters.

Note that this is only one of many possible conventions you can use in your
workflow system.

The context should probably not be mutated by the workflow itself. That's what
the workflow instance is for.

=head1 CONTEXT ROLES

You are encouraged to create roles for additional paremeters in the context,
and compose them together into the final workflow class instead of relying on
C<stash>.

This provides a more structured approach, and lets you use C<lazy_build> in the
attributes cleanly.

You could also apply runtime roles to the workflow class for a more dynamic and
flexible solution.

=head1 FIELDS

=over 4

=item stash

Just a simple hash reference.

=back

=cut


