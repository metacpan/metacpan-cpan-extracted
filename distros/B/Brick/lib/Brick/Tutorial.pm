package Brick::Tutorial

=pod

=encoding utf8

=head1 NAME

Brick::Tutorial - How to use Brick

=head1 SYNOPSIS

=head1 DESCRIPTION

Brick is a way to organize business rules to validate data. It's easy
to validate values by themselves, but the validation of relationships
is much trickier.

=head2 Making a brick

The name "Brick" comes from the terminology for the validation
routines, each of which is a brick. Think of the building block toys
the come from Denmark and rhyme with "Say Go". Every time I create a
brick, I'll add it to the "bucket", which keeps track of all the
bricks.

Each brick represents one part of a validation, and it should be as
targeted as possible. A brick is just a anonymous subroutine that
follows an interface.

The brick returns it result in one of three ways.

=over 4

=item Returns true

If the brick returns a true value, it means that the data passed its
condition.

=item Returns false

If the brick returns a false value (but didn't die), that means that
the data did not pass the condition, but it's not a failure. This is
for "selectors", which will let us figure out how to prune validation
trees later.

=item C<die>s with a reference

If a brick C<die>s with a reference, it's like an exception. The brick
uses an anonymous hash as the argument to C<die>. That hash contains the
name of the brick, a message about why the brick failed, and perhaps a
description of the brick.

=item C<dies>s with a string

If a brick C<die>s with a string, there's a programming problem. This
isn't part of the interface, so if this happens, I've messed up
somehow.

=back

Every brick has access to all of the input data. Since I'm concerned
about complex relationships, I don't want to limit the effect of any
particular piece. With maximum flexibility, I have maximum power.

	# every brick gets all the input
	$brick->( \%input );

To create a brick, I need an subroutine to do the validation. In this
case, I want to ensure that the input hash has a key named 'cat'. If
it does I return true, and C<die> with a hash reference otherwise.
I'll talk about that C<die> later.

	my $sub = sub {
		my $input = shift;

		return 1 if exists $input->{cat};

		die {
			handler      => 'Cat key check',
			failed_field => 'cat'
			message      => "The input didn't have a field named 'cat'",
			};
		}

The brick doesn't do me much good until I add it to the bucket,
though. My call to C<add_to_bucket> returns the anonymous subroutine,
but also keeps track of it with a name and a description, as well as
the details about which line of code it comes from and many other
details.

	$brick = $bucket->add_to_bucket( {
		name        => 'cat key checker',
		description => "The input didn't have a field named 'cat'",
		code        => $sub
		} );

The bucket has two major functions: it keeps track of the
relationships between bricks so I can "explain" a business rule
(discussed later) and so I can easily debug what I've done. Since I'm
going to be making a lot of closures, I want to know where they came
from in the code. I'd go crazy without being able to use the bucket to
help me keep track of things. More on that coming up.

I'm going to make a lot of bricks, and some of them will be almost the
same. Instead of checking for the 'cat' key, I want to do the same
thing but for the key 'dog'. I need a brick factory. The factory gets
a C<$setup> hash as an argument. I put the anonymous subroutine inline
with the my call to C<add_to_bucket>. Everywhere that I had the
literal 'cat' before I now have a variable, C<$setup->{field}>, which
came from the input to C<_input_key_exists>.

	my $cat_brick = $bucket->_input_key_exists( { field => 'cat' } );

	my $dog_brick = $bucket->_input_key_exists( { field => 'dog' } );

Somewhere I defined the C<_input_key_exists> method so it shows
up in the Bucket class:

	package Brick::Bucket;

	sub _input_key_exists
		{
		my( $bucket, $setup ) = @_;

		$bucket->add_to_bucket( {
			name        => "$setup->{field} key checker",
			description => "The input didn't have a field named '$setup->{field}'",
			code        => sub {
				my $input = shift;

				return 1 if exists $input->{ $setup->{field} };

				die {
					handler => 'Cat key check',
					message => "The input didn't have a field named '$setup->{field}'",
					};
				},
			} );

		}

Every time I call C<_input_key_exists> I get a new brick, because it's
always a new closure (closing over C<$setup>). The factory
automatically adds the brick to the bucket.

=head2 Composing bricks

I'll build a business rule from several bricks. When I want to test a
business rule, I run all of the bricks and look at their return values.
Instead of keeping track of a bunch of bricks, though, I'll compose
them into larger structures so I only have to remember one thing. A
composer simply creates a new, bigger brick based on the ones I give it. The
bucket will keep track of the relationships for me.

I create another factory that puts the bricks together. Inside
C<_cat_and_dog_exists>, I create the bricks for 'cat' and 'dog', and
use them as arguments to C<__compose_satisfy_all>, which creates a new
brick that only returns true when both C<$cat_brick> and C<$dog_brick>
return true.

	sub _cat_and_dog_exists
		{
		my( $bucket, $setup );

		my $cat_brick = $bucket->_input_key_exists(
			{ %$setup, field => 'cat' } );

		my $dog_brick = $bucket->_input_key_exists(
			{  %$setup, field => 'dog' } );


		$bucket->__compose_satisfy_all( $cat_brick, $dog_brick );
		}

A composer can decide when it should return true, though. In the
previous example both bricks had to return true, but if I only need at
least one of them to be true, I can use a different composer, perhaps
C<__compose_satisfy_any>, in which case only one of the bricks needs
to pass:

	sub _either_cat_and_dog_exists
		{
		my( $bucket, $setup );

		my $cat_brick = $bucket->_input_key_exists(
			{ %$setup, field => 'cat' } );

		my $dog_brick = $bucket->_input_key_exists(
			{  %$setup, field => 'dog' } );


		$bucket->__compose_satisfy_any( $cat_brick, $dog_brick );
		}

Brick comes with several composers in C<Brick::Composers>, but you can
also create your own if those don't work for you. The composer is
really just another factory to create bricks.

=head2 Selectors

Selectors are a special sort of brick that doesn't C<die>. When it
fails, it just returns C<0> (not just false, but specifically 0). I
can use these with composers to decide if I want to continue with the
rest of the bricks in that composition.

The composer C<__compose_pass_or_stop> can use a selector to stop
processing. It won't C<die>, so it doesn't fail. It doesn't keep
going, either, so it effectively prunes the validation to exclude
those bricks that don't apply to the situation.

The composer C<__compose_pass_or_skip> usually composes bricks made
with C<__compose_pass_or_stop>. Once one thing stops processing, it
moves onto the next brick.

See the example in C<Brick::Selector>.

=head2 Filters

Filters are a special sort of brick that always returns true. I use
them to affect the input data before I start to validate it.

=head1 Making constraints

A constraint is a business rule. It's made up of bricks, but it also
has some extra glue to connect the input data to the validation
routines. The constraints are the end of the line for composition.
They are the bits that actually run the bricks and pass the input data
to them.

Constraints should be public subroutines (so no leading underscores)
whose name reflects what it does.

	sub check_cat_and_dog
		{
		my( $bucket, $setup );

		my $brick = $bucket->_either_cat_and_dog_exists( $setup );

		my $constraint = $brick->__make_constraint( $brick, $setup );
		}

I don't need to call the constraint subroutines myself. Brick will
automatically do that when it constructs a profile.

=head1 Making profiles

A profile is a collection of constraints to apply to input data. The
constraints essentially give an assortment of bricks a name and
represent a business rule. The profile represents all of the business
rules put together.

In data, the profile is a list of anonymous arrays. Each of the
anonymous arrays specify three things:

=over 4

=item A label

The label can be anything. It reminds you which profile element you're
working with. It doesn't have to be unique, but it should be.

=item A constraint name

The constraint name refers to the method to use for that business
rule. This has to be the name of an existing method (or a code
reference returned by can()).

=item An anonymous setup hash

The last element is a hash of setup information for the bricks. This
is the C<$setup> variable seen in the examples.

=back

Here's a simple profile.

	my @Profile = (
		#  label          #method name       #setup
		[ cat_and_dog  => check_cat_and_dog  => {}  ]
		);

To apply the profile, I pass it along with the input hash to C<apply>:

	use Brick;

	my $Brick = Brick->new;

	my $profile = $Brick->profile_class->new( \@Profile );

	$Brick->apply( $profile, \%input );

Before I apply a profile, I might want to use C<lint> to check it for
errors. It's a class method since it hasn't created an object yet:

	$Brick->profile_class->lint( \@Profile );

I can dump the profile in a handy text format with C<explain> to see
if it does what I want:

	$profile->explain;


=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/brick

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2007-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
