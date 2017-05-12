package Brick;
use strict;

use subs qw();
use vars qw($VERSION);

use Carp qw( carp croak );
use Data::Dumper;

use Brick::Profile;

$VERSION = '0.227';

=head1 NAME

Brick - Complex business rule data validation

=head1 SYNOPSIS

	use Brick;

	my $brick = Brick->new( {
		external_packages => [ qw(Foo::Validator Bar::Validator) ]
		} );

	my $profile = Brick::Profile->new( $brick,
		[ required  => sub { .... }    => $hash ],
		[ optional  => optional_fields => $hash ],

		[ inside    => in_number       => $hash ],

		[ outside   => ex_number       => $hash ],
		);

	my %input_from_app = (
		name => 'Joe Snuffy',
		...
		);

	my $results = $brick->apply( $profile, \%%input_from_app );

=head1 DESCRIPTION


=head2 Class methods

=over 4

=item Brick->new

Create a new C<Brick>. Currently this doesn't do anything other than
give you an object so you can call methods.

Future ideas? Maybe store several buckets or profiles?

=cut

sub new
	{
	my( $class, $args ) = @_;

	my $self = bless {}, $class;

	$self->init( $args );

	$self->_load_external_packages( @{ $args->{external_packages} } );

	$self;
	}

sub _load_external_packages
	{
	my( $self, @packages ) = @_;

	my $bucket_class = $self->bucket_class;

	foreach my $package ( @packages )
		{
		eval "package $bucket_class; require $package; $package->import";
		croak "Could not load $package: $@" if $@;
		}

	}

=item Brick->error( MESSAGE )

Set the error message from the last things that happened.

=item Brick->error_str

Get the error message from the last things that happened.

=cut

{
my $Error;

sub error     { $_[0]->_set_error( $_[1] ); croak $_[1]; }
sub error_str { $Error }

# do some stuff to figure out caller, etc
sub _set_error { $Error = $_[1] }
}

=back

=head2 Instance methods

=over 4

=item create_bucket( PROFILE_ARRAYREF )

=item create_pool  # DEPRECATED

This method creates a C<Brick::Bucket> instance (or an instance in
the package returned by C<$brick->bucket_class> ) based on the profile
and returns the bucket instance. Along the way it affects the args
hashref in each profile element to add the element name as the key
C<profile_name> and the actual coderef (not just the method name) as
the key C<code>. The closure generators are allowed to use those keys.
For instance, C<__make_constraint>, which is usually the top level
closure, uses it to name the closure in the bucket.

If the profile doesn't pass C<lint> test, this method croaks. You
might want to safeguard that by calling C<lint> first.

	my $bucket = do {
		if( my( $lint ) = $brick->lint( $profile ) )
			{
			$brick->create_bucket( $profile );
			}
		else
			{
			Data::Dumper->Dump( [ $lint ], [qw(lint)] );
			undef;
			}
		};

From the profile it extracts the method name to create the closure for
it based on its arguments. If the method item is already a code
reference it uses it add is, but still adds it to the bucket. This could
be handy for using closures from other classes, but I haven't
investigated the consequences of that.

In scalar context this returns a new bucket instance. If the profile might
be bad, use an eval to catch the croak:

	my $bucket = eval{ $brick->create_bucket( \@profile ) };

In list context, it returns the C<$bucket> instance and an anonymous array
reference with the stringified closures (which are also the keys in the
bucket). The elements in the anonymous array correspond to the elements in
the profile. This is handy in C<explain> which needs to find the bucket
entries for each profile elements. You probably won't need the second
argument most of the time.

	my( $bucket, $refs ) = eval { $brick->create_bucket( \@profile ) };

=cut

sub create_pool { croak "create_pool is now create_bucket!" }

sub create_bucket
	{
	my( $brick, $profile ) = @_;

	unless( 0 == $brick->profile_class->lint( $profile || [] ) ) # zero but true!
		{
		croak "Bad profile for create_bucket! Perhaps you need to check it with lint"
		};

	my $bucket = $brick->bucket_class->new;

	my @coderefs = ();
	foreach my $entry ( @$profile )
		{
		my( $name, $method, $args ) = @$entry;

		$args->{profile_name} = $name;

		$args->{code} = do {
			if( eval { $method->isa( ref {} ) } or
				ref $method eq ref sub {} )
				{
				$method;
				}
			elsif( my $code = eval{ $bucket->$method( $args ) } )
				{
				$code;
				}
			elsif( $@ ) { croak $@ }
			};

		push @coderefs, map { "$_" } $bucket->add_to_bucket( $args );
		}

	wantarray ? ( $bucket, \@coderefs ) : $bucket;
	}

=item init

Initialize the instance, or return it to a pristine state. Normally
you don't have to do this because C<new> does it for you, but if you
subclass this you might want to override it.

=cut

sub init
	{
	my( $self, $args ) = @_;

	my $bucket_class = $self->bucket_class;

	eval "require $bucket_class";

	$self->{buckets} = [];

	if( defined $args->{external_packages} && ref $args->{external_packages} eq ref [] )
		{ # defined and array ref
		$self->{external_packages} = $args->{external_packages};
		}
	elsif( defined $args->{external_packages} &&
		! ($args->{external_packages} eq ref []) )
		{ # defined but not array ref
		carp "'external_packages' value must be an anonymous array";
		$self->{external_packages} = [];
		}
	else
		{ # not defined
		$self->{external_packages} = [];
		}
	}

=item add_validator_packages( PACKAGES )

Load external validator packages into the bucket. Each of these packages
should export the functions they want to make available. C<add_validator_package>
C<require>s each package and calls its C<import> routine.

=cut

sub add_validator_packages
	{
	my( $self, @packages ) = @_;

	$self->_load_external_packages( @packages );
	}

=item clone;

Based on the current instance, create another one just like it but not
connected to it (in effect forking the instance). After the C<clone>
you can change new instance without affecting the old one. This is
handy in C<explain>, for instance, where I want a deep copy for a
moment. At least I think I want a deep copy.

That's the idea. Right now this just returns the same instance. When
not using a copy breaks, I'll fix that.

=cut

sub clone
	{
	my( $brick ) = shift;

	$brick;
	}

sub explain
	{
	croak "Who's calling Brick::explain? That's in Brick::Profile now!";
	}

=item apply(  PROFILE OBJECT, INPUT_DATA_HASHREF )

Apply the profile to the data in the input hash reference. The profile
can either be a profile object or an array ref that apply() will use to
create the profile object.

This returns a results object blessed into the class name returned by
results_class(), which is Brick::Result by default. If you don't like
that, you can override it in your own subclass.

=cut

sub apply
	{
	my( $brick, $profile, $input ) = @_;

	croak "Did not get a profile object in Brick::apply()!\n"
		unless eval { $profile->isa( $brick->profile_class ) };

	my $bucket   = $profile->get_bucket;
	my $coderefs = $profile->get_coderefs;
	my $array    = $profile->get_array;

	my @entries = map {
		my $e = $bucket->get_from_bucket( $_ );
		[ map { $e->$_ } qw(get_coderef get_name) ]
		} @$coderefs;

	my @results = ();

	foreach my $index ( 0 .. $#entries )
		{
		my $e    = $entries[$index];
		my $name = $array->[$index][0];

		my $bucket_entry = $bucket->get_from_bucket( "$e->[0]" );
		my $sub_name     = $bucket_entry->get_name;

		my $result = eval{ $e->[0]->( $input ) };
		my $eval_error = $@;

		carp "Brick: $sub_name: eval error \$\@ is not a string or hash reference"
			unless( ! ref $eval_error or ref $eval_error eq ref {} );

		if( defined $eval_error and ref $eval_error eq ref {} )
			{
			$result = 0;
			carp "Brick: $sub_name died with reference, but didn't define 'handler' key"
				unless exists $eval_error->{handler};

			carp "Brick: $sub_name died with reference, but didn't define 'message' key"
				unless exists $eval_error->{message};
			}
		elsif( defined $eval_error ) # but not a reference
			{
			$eval_error = {
				handler       => 'program_error',
				message       => $eval_error,
				program_error => 1,
				errors        => [],
				};
			}

		my $handler = $array->[$index][1];

		my $result_item = $brick->result_class->result_item_class->new(
			label    => $name,
			method   => $handler,
			result   => $result,
			messages => $eval_error,
			);

		push @results, $result_item;
		}

	return bless \@results, $brick->result_class;
	}

=item bucket_class

The namespace where the constraint building blocks are defined. By
default this is C<Brick::Bucket>. If you don't like that, override
this in a subclass. Things that need to work with the bucket class
name, such as a factory method, will use the return value of this
method.

This method also loads the right class, so if you override it,
remember to load the class too!

=cut

sub bucket_class { require Brick::Bucket; 'Brick::Bucket' }

=item result_class

The namespace that C<apply> uses for its result object. By default
this is C<Brick::Result>. If you don't like that, override this in a
subclass. Things that need to work with the result class name, such as
a factory method, will use the return value of this method.

This method also loads the right class, so if you override it,
remember to load the class too!

=cut

sub result_class { require Brick::Result; 'Brick::Result' }

=item profile_class

The namespace for the profile object. By default this is
C<Brick::Profile>. If you don't like that, override this in a
subclass. Things that need to work with the result class name, such as
a factory method, will use the return value of this method.

This method also loads the right class, so if you override it,
remember to load the class too!

=cut

sub profile_class { require Brick::Profile; 'Brick::Profile' }

=back

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
