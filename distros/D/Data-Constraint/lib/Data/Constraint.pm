package Data::Constraint;
use strict;
use vars qw($VERSION);

use warnings;
no warnings;

=head1 NAME

Data::Constraint - prototypical value checking

=head1 SYNOPSIS

	use Data::Constraint;

	my $constraint = Data::Constraint->add_constraint(
		'name_of_condition',
		run         => sub { $_[1] =~ /Perl/ },
		description => "String should have 'Perl' in it";
		);

	if( $constraint->check( 'Java' ) )
		{
		...
		}

=head1 DESCRIPTION

A constraint is some sort of condition on a datum.  This module checks
one condition against one value at a time, and I call the thing that
checks that condition the "constraint".  A constraint returns true or
false, and that's it.  It should have no side effects, it should not
change program flow, and it should mind its own business. Let the
thing that calls the constraint figure out what to do with it. I want
something that says "yes" or "no" (and I discuss why this needs a
fancy module later).

For instance, the constraint may state that the value has to be a
number.  The condition may be something that ensures the value does
not have non-digits.

	$value =~ /^\d+\z/

The value may have additional constraints, such as a lower limit.

	$value > $minimum

Although I designed constraints to be a single condition, you
may want to create contraints that check more than one thing.

	$value > $minimum and $value < $maximum

In the previous examples, we could tell what was wrong with the value
if the return value was false: the value didn't satisfy it's single
condition.  If it was supposed to be all digits and wasn't, then it
had non-digits.  If it was supposed to be greater than the minimum
value, but wasn't, it was less than (or equal to) the minimal value.
With more than one condition, like the last example, I cannot tell
which one failed. I might be able to say that a value of out of range,
but I think it is nicer to know if the value should have been larger
or smaller so I can pass that on to the user.  Having said that, I
give you enough rope to do what you wish.

=head2 Why I need a fancy, high-falutin' module

This module is a sub-class of C<Class::Prototyped>.  In brief, that
means constraints are class-objects even if they don't look like they
are.  Each constraint is a self-contained class, and I can modify
a constraint by adding data and behaviour without affecting any of
the other constraints.  I can also make a list of constraints that
I store for later use (also known as "delayed" execution).

Several data may need the same conditions, so they can share the same
constraint.  Other data that need different constraints can get
their own, or modify copies of ones that exist.

I can also associate several constraints with some data, and each
one has its own constraint.  In the compelling case for this module,
I needed to generate different warnings for different failures.

=head2 Interacting with a constraint

I can get a constraint object by asking for it.

	my $constraint = Data::Constraints->get_by_name( $name );

If no constraint has that name, I get back the default constraint which
always returns true. Or should it be false?  I guess that depends on
what you are doing.

If I don't know which constraints exist, I can get all the
names. The names are just simple strings, so they have no
magic.  Maybe this should be a hash so you can immediately use
the value of the key you want.

	my @names = Data::Constraints->get_all_names;

Once I have the constraint, I give it a value to check if

	$constraint->check( $value );

I can do this all in one step.

	Data::Constraints->get_by_name( $name )->check( $value );

=head2 Predefined constraints

=over 4

=item defined

True if the value is defined.

=item ordinal

True if the value is an ordinal number, also known as a strictly
positive integer, which means it only has digit characters [0-9].

=item true

True if the value is true.  That's a lot of work to find out just
that since I could just use the value itself.  This trivial constraints
sticks with the metaphor though.  It still returns only true or
false, so the value I get back will be true if the value is true,
but it won't be the value I started with, necessarily.

=back

=head2 Adding a new constraint

Add a new constraint with the class method C<add_constraint>. The
first argument is the name you want to give the constraint.  The
rest of the arguments are optional, although I need to add a
C<run> key if I want the constraint to do anything useful: its
value should be something that returns true when the value
satisfies the condition (so a constant is probably not what
you want).  An anonymous subroutine is probably what you want.

	Data::Constraint->add_constraint(
		$name_of_constraint,
		'run' => sub {...},
		[ @optional_arguments ],
		);

Once I create the constraint, it exists forever (for now).  I get
back the constraint object:

	my $constraint = Data::Constraint->add_constraint( ... );

The object sticks around after C<$constraint> goes out of scope.
The C<$constraint> is just a reference to the object.  I can get
another reference to it through C<get_by_name()>.  See L<"Deleting
a constraint"> if you want to get rid of them.

=head2 Modifying a constraint

Um, don't do that yet unless you know what you are doing.

=head2 Deleting a constraint

	Data::Constraint->delete_by_name( $name );

	Data::Constraint->delete_all();

=head2 Doing anything you want

You wish!  This module can't help you there.

=head1 METHODS

=cut

$VERSION = '1.17';

use base qw(Class::Prototyped);

=over 4

=item check( VALUE )

Apply the constraint to the VALUE.

=item add_constraint( NAME, KEY-VALUES )

Added a constraint with name NAME. Possible keys and values:

	run            reference to subroutine to run
	description    string that decribes the constraint

Example:

	Data::Constraint->add_constraint(
		$name_of_constraint,
		'run'       => sub {...},
		description => 'This is what I do",
		);

=item get_all_names

Return a list of all the defined constraints.

=item get_by_name( CONSTRAINT_NAME )

Return the constraint with name CONSTRAINT_NAME. This is

=item delete_by_name( CONSTRAINT_NAME )

Delete the constraint with name CONSTRAINT_NAME. It's no longer available.

=item delete_all()

Delete all the constraints, even the default ones.

=item description

Return the description. The default description is the empty string. You
should supply your own description with C<add_constraint>.

=item run

Return the description. The default description is the empty string. You
should supply your own description with C<add_constraint>.

=back

=cut

__PACKAGE__->reflect->addSlots(
	check            => sub {
		$_[0]->run( $_[1] ) ? 1 : 0;
		},

	# the list of added constraints
	constraints    => {},

	add_constraint => sub {
		my $class = shift;
		my $name  = shift;

		my $constraint = $class->new(
			'name'   => $name,
			'class*' => $class,
			@_,
			);

		$class->constraints->{$name} = $constraint;
		},

	get_all_names => sub {
		return sort keys %{ $_[0]->constraints };
		},

	get_by_name => sub {
		$_[0]->constraints->{ $_[1] };
		},

	delete_by_name => sub {
		delete $_[0]->constraints->{ $_[1] };
		},

	delete_all => sub {
		$_[0]->constraints( {} );
		},

	description => sub { "" },
	run         => sub { 1  },
	);

__PACKAGE__->add_constraint(
	'defined',
	'run'         => sub { defined $_[1] },
	'description' => 'True if the value is defined',
	);

__PACKAGE__->add_constraint(
	'ordinal',
	'run'         => sub { $_[1] =~ /^\d+\z/ },
	'description' => 'True if the value is has only digits',
	);

__PACKAGE__->add_constraint(
	'test',
	'run' => sub { 1 },
	);

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/data-constraint

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2014 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

