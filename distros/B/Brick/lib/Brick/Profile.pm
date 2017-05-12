package Brick::Profile;
use strict;
use warnings;

use vars qw($VERSION);

use Carp qw(carp);

use Brick;

$VERSION = '0.227';

=encoding utf8

=head1 NAME

Brick::Profile - the validation profile for Brick

=head1 SYNOPSIS



=head1 DESCRIPTION

This class turns a profile description into a ready-to-use profile object
that has created all of the code it needs to validate input. In Brick
parlance, it creates the bucket and the bricks that need to go into the
bucket based on the validation description.

=head2 Validation profile

The validation profile is an array of arrays. Each item in the array specifies
three things: a label for that item, the name of the method to run to
validate the item, and optional arguments to pass to the the method.

For instance, here's a simple validation description to check if a user
is registered with the system. This profile has one item:

	@profile = (
		[ username => is_registered => { field => form_name } ],
		);

The label for the item is C<username>. When Brick reports the results
of the validation, the label C<username> will be attached to the
result for this part of the validation.

The method that validates this item is C<is_registered>. When you
create the profile, Brick will look for that method in either it's
included methods in Brick::Bucket classes or the ones you load with
C<Brick::add_validator_packages>. This method is called a "brick"
because it's one piece of the entire validation.

Additionally, Brick will pass the optional arguments, in this case C<{
field => form_name }>, to C<is_registered>. A brick merely creates
a closure that will run later, so the optional arguments are for
the initialization of that closure. The validation doesn't happen
until you C<apply> it.

=head2 Class methods

=over 4

=item new( BRICK, ARRAY_OF_ARRAYS )

Create a new profile object tied to the Brick object.

=cut

sub new
	{
	my( $class, $brick, $array_ref ) = @_;

	unless( $brick->isa( $class->brick_class ) )
		{
		carp "First argument to \$class->new() must be a brick object. " .
			"Got [$brick]\n";
		return;
		}

	my $self = bless {}, $class;

	my $lint_errors = $class->lint( $array_ref );

	if( ! defined $lint_errors or $lint_errors )
		{
		carp "Profile did not validate!";
		return;
		}

	my( $bucket, $refs ) = $brick->create_bucket( $array_ref );

	$self->set_bucket( $bucket );
	$self->set_coderefs( $refs );
	$self->set_array( $array_ref );

	return $self;
	}

=item brick_class()

Return the class name to use to access class methods (such as
bucket_class) in the Brick namespace. If you want to provide
an alternate Brick class for your profile, override this method.

=cut

sub brick_class { require Brick; 'Brick' }

=back

=head2 Instance methods

=over

=item lint( PROFILE_ARRAYREF );

Examine the profile and complain about irregularities in format. This
only checks the format; it does not try to determine if the profile
works or makes sense. It returns a hash whose key is the index of the
profile element and whose value is an anonymous hash to indicate what
had the error:

	format  -   the element is an arrayref
	name    -   the name is a scalar
	method  -   is a code ref or can be found in the package
					$brick->bucket_class returns
	args    -   the last element is a hash reference

If the profile is not an array reference, C<lint> immediately returns
undef or the empty list. In scalar context, C<lint> returns 0 for
format success and the number of errors (so true) for format failures.
If there is a format error (e.g. an element is not an array ref), it
immediately returns the number of errors up to that point.

	my $lint = $brick->profile_class->lint( \@profile );

	print do {
		if( not defined $lint ) { "Profile must be an array ref\n" }
		elsif( $lint )          { "Did not validate, had $lint problems" }
		else                    { "Woo hoo! Everything's good!" }
		};

In list context, it returns a hash (a list of one element). The result
will look something like this hash, which has keys for the elements
that lint thinks are bad, and the values are anonymous hashes with
keys for the parts that failed:

	%lint = (
		1 => {
			method => "Could not find method foo in package",
			},
		4 => {
			args => "Arguments should be a hash ref, but it was a scalar",
			}
		);

If you are using C<AUTOLOAD> to generate some of the methods at
runtime (i.e. after C<lint> has a chance to check for it), use a
C<can> method to let C<lint> know that it will be available later.

TO DO:

Errors for duplicate names?

=cut

sub lint
	{
	my( $class, $array ) = @_;

	return unless(
		eval { $array->isa( ref [] ) } or
		UNIVERSAL::isa( $array, ref [] )
		);

	my $lint = {};

	foreach my $index ( 0 .. $#$array )
		{
		my $h = $lint->{$index} = {};

		unless( eval { $array->[$index]->isa( ref [] ) } or
			UNIVERSAL::isa(  $array->[$index], ref [] )
			)
			{
			$h->{format} = "Not an array reference!";
			last;
			}

		my( $name, $method, $args ) = @{ $array->[$index] };

		$h->{name} = "Profile name is not a simple scalar!" if ref $name;

		$h->{args} = "Couldn't find method [$method]" unless
			eval { $method->isa( ref sub {} ) } or
			UNIVERSAL::isa( $method, sub {} )    or
			eval { $class->brick_class->bucket_class->can( $method ) };

		$h->{args} = "Args is not a hash reference" unless
			eval { $args->isa( ref {} ) } or
			UNIVERSAL::isa( $args, ref {} );

		# args needs what?

		delete $lint->{$index} if 0 == keys %{$lint->{$index}};
		}

	wantarray ? %$lint : ( scalar keys %$lint );
	}

=item explain()

Turn the profile into a textual description without applying it to any
data. This does not add the profile to instance and it does not add
the constraints to the bucket.

If everything goes right, this returns a single string that represents
the profile.

If the profile does not pass the C<lint> test, this returns undef or the
empty list.

If you want to do something with a datastructure, you probably want to
write a different method very similar to this instead of trying to parse
the output.

Future notes: maybe this is just really a dispatcher to things that do
it in different ways (text output, hash output).

=cut

sub explain
	{
	my( $profile ) = @_;

	my $bucket   = $profile->get_bucket;
	my $coderefs = $profile->get_coderefs;
	my $array    = $profile->get_array;

	my @entries = map {
		my $e = $bucket->get_from_bucket( $_ );
		[ map { $e->$_ } qw(get_coderef get_name) ]
		} @$coderefs;

	#print STDERR Data::Dumper->Dump( [ \@entries ], [qw(entries)] );

	my $level = 0;
	my $str   = '';
	foreach my $index ( 0 .. $#entries )
		{
		my $tuple = $entries[$index];

		my @uses = ( [ $level, $tuple->[0] ] );

		#print STDERR Data::Dumper->Dump( [ \@uses ], [qw(uses)] );

		while( my $pair = shift @uses )
			{
			my $entry = $bucket->get_from_bucket( $pair->[1] );
			#print Data::Dumper->Dump( [ $entry ], [qw(entry)] );
			next unless $entry;

			$str .=  "\t" x $pair->[0] . $entry->get_name . "\n";

			unshift @uses, map {
				[ $pair->[0] + 1, $_ ]
				} @{ $entry->get_comprises( $pair->[1] ) };
			#print Data::Dumper->Dump( [ \@uses ], [qw(uses)] );
			}

		$str.= "\n";
		}

	$str;
	}

=item get_bucket

=cut

sub get_bucket
	{
	$_[0]->{bucket}
	}

=item set_bucket

=cut

sub set_bucket
	{
	$_[0]->{bucket} = $_[1];
	}

=item get_coderefs

=cut

sub get_coderefs
	{
	$_[0]->{coderefs};
	}

=item set_coderefs

=cut

sub set_coderefs
	{
	$_[0]->{coderefs} = $_[1];
	}

=item get_array

=cut

sub get_array
	{
	$_[0]->{array};
	}

=item set_array

=cut

sub set_array
	{
	$_[0]->{array} = $_[1];
	}

=back

=head2 Using a different class

If you don't want to use this class, you can specify a different class
to use in your Brick subclass. Override the Brick::profile_class()
method to specify the name of the class that you want to use instead.
That might be a subclass or an unrelated class. Your class will need
to use the same interface even though it does things differently.

=head1 TO DO

TBA

=head1 SEE ALSO

L<Brick::Tutorial>, L<Brick::UserGuide>

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
