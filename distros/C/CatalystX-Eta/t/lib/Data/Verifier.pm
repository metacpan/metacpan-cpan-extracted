package Data::Verifier;
{
    $Data::Verifier::VERSION = '0.56';
}
use Moose;

# ABSTRACT: Profile based data verification with Moose type constraints.

use Data::Verifier::Field;
use Data::Verifier::Filters;
use Data::Verifier::Results;
use Moose::Util::TypeConstraints;
use Scalar::Util qw(blessed);

#use Try::Tiny;

has 'derived' => (
    is        => 'ro',
    isa       => 'HashRef[HashRef]',
    predicate => 'has_derived'
);

has 'filters' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str|CodeRef]',
    default => sub { [] }
);

has 'profile' => (
    is       => 'ro',
    isa      => 'HashRef[HashRef]',
    required => 1
);

sub coercion {
    my %params = @_;
    Moose::Meta::TypeCoercion->new(
        type_coercion_map => [
            $params{'from'} => $params{'via'}
        ]
    );
}

sub verify {
    my ( $self, $params, $members ) = @_;

    my $results = Data::Verifier::Results->new;
    my $profile = $self->profile;

    my $blessed_params = blessed($params);

    my @post_checks = ();
    foreach my $key ( keys( %{$profile} ) ) {
        my $skip_string_checks = 0;

        # Get the profile part that is pertinent to this field
        my $fprof = $profile->{$key};

        # Deal with the fact that what we're given may be an object.
        my $val = do {
            if ($blessed_params) {
                $params->can($key) ? $params->$key() : undef;
            }
            else {
                $params->{$key};
            }
        };

        # Creat the "field" that we'll put into the result.
        my $field = Data::Verifier::Field->new;

        # Save the original value.
        if ( ref($val) eq 'ARRAY' ) {
            my @values = @{$val};    # Make a copy of the array
            $field->original_value( \@values );
        }
        else {
            $field->original_value($val);
        }

        # Early type check to catch parameterized ArrayRefs.
        if ( $fprof->{type} ) {
            my $cons = Moose::Util::TypeConstraints::find_or_parse_type_constraint( $fprof->{type} );

            die "Unknown type constraint '$fprof->{type}'" unless defined($cons);

            # If this type is a paramterized arrayref, then we'll handle each
            # param as if it was an independet value and run it through the
            # whole profile.
            if ( $cons->is_a_type_of('ArrayRef') && $cons->can('type_parameter') ) {

                # Get the type parameter for this arrayref
                my $tc = $cons->type_parameter;

                # Copy the profile.
                my %prof_copy = %{$fprof};
                $prof_copy{type} = $tc->name;
                my $dv = Data::Verifier->new(

                    # Use the global filters
                    filters => $self->filters,

                    # And JUST this field
                    profile => { $key => \%prof_copy }
                );

                # Make sure we are dealing with an array
                my @possibles;
                if ( ref($val) eq 'ARRAY' ) {
                    @possibles = @{$val};
                }
                else {
                    @possibles = ($val);
                }

                # So we can keep up with passed values.
                my @passed;
                my @pass_post_filter;

                # Verify each one
                foreach my $poss (@possibles) {
                    my $res = $dv->verify( { $key => $poss }, 1 );
                    if ( $res->success ) {

                        # We need to keep up with passed values as well as
                        # post filter values, copying them out of the result
                        # for use in our field.
                        push( @passed,           $res->get_value($key) );
                        push( @pass_post_filter, $res->get_post_filter_value($key) );
                    }
                    else {
                        # Mark the whole field as failed.  We'll use this
                        # later.
                        $field->valid(0);
                    }
                }

                # Set the value and post_filter_value for the field, then
                # set the field in the result.  We're done, since we sorta
                # recursed to check all the params for this field.
                $val = \@passed;
                $field->value( \@passed );
                $field->post_filter_value( \@pass_post_filter );
                $results->set_field( $key, $field );

                # Skip all the "string" checks, since we've already done all the
                # real work.
                $skip_string_checks = 1;
            }
            next unless $field->valid;    # stop processing if invalid
        }

        unless ($skip_string_checks) {

            # Pass through global filters
            if ( $self->filters ) {
                $val = $self->_filter_value( $self->filters, $val );
            }

            # And now per-field ones
            if ( $fprof->{filters} ) {
                $val = $self->_filter_value( $fprof->{filters}, $val );
            }

            # Empty strings are undefined
            if ( defined($val) && $val eq '' ) {
                $val = undef;
            }

            if ( ref($val) eq 'ARRAY' ) {
                my @values = @{$val};
                $field->post_filter_value( \@values );
            }
            else {
                $field->post_filter_value($val);
            }

            if ( $fprof->{required} && !defined($val) ) {

                # Set required fields to undef, as they are missing
                $results->set_field( $key, undef );
            }
            else {
                $results->set_field( $key, $field );
            }

            # No sense in continuing if the value isn't defined.
            next unless defined($val);

            # Check min length
            if ( $fprof->{min_length} && length($val) < $fprof->{min_length} ) {
                $field->reason('min_length');
                $field->valid(0);
                next;    # stop processing!
            }

            # Check max length
            if ( $fprof->{max_length} && length($val) > $fprof->{max_length} ) {
                $field->reason('max_length');
                $field->valid(0);
                next;    # stop processing!
            }
        }

        # Validate it
        if ( $fprof->{type} ) {
            my $cons = Moose::Util::TypeConstraints::find_or_parse_type_constraint( $fprof->{type} );

            die "Unknown type constraint '$fprof->{type}'" unless defined($cons);

            # Look for a global coercion
            if ( $fprof->{coerce} ) {
                $val = $cons->coerce($val);
            }

            # Try a one-off coercion.
            elsif ( my $coercion = $fprof->{coercion} ) {
                $val = $coercion->coerce($val);
            }

            unless ( $cons->check($val) ) {
                $field->reason('type_constraint');
                $field->valid(0);
                $field->clear_value;
                next;    # stop processing!
            }
        }

        # check for dependents
        my $dependent = $fprof->{dependent};
        my $dep_results;
        if ( $dependent and !$members ) {

            # Create a new verifier for use with the dependents
            my $dep_verifier = Data::Verifier->new(
                filters => $self->filters,
                profile => $dependent
            );
            $dep_results = $dep_verifier->verify($params);

            # Merge the dependent's results with the parent one
            $results->merge($dep_results);

            # If the dependent isn't valid, then this field isn't either
            unless ( $dep_results->success ) {
                $field->reason('dependent');
                $field->valid(0);
                $field->clear_value;
                next;    # stop processing!
            }
        }

        # Add this key the post check so we know to run through them
        if ( !$members && defined( $fprof->{post_check} ) && $fprof->{post_check} ) {
            push( @post_checks, $key );
        }

        # Add this key to the post check if we're on "member" mode and there
        # is a member_post_check specified
        if ( $members && defined( $fprof->{member_post_check} ) && $fprof->{member_post_check} ) {
            push( @post_checks, $key );
        }

        # Set the value
        $field->value($val);
        $field->valid(1);
    }

    # If we have any post checks, do them.
    if ( scalar(@post_checks) ) {
        foreach my $key (@post_checks) {
            my $fprof = $profile->{$key};
            my $field = $results->get_field($key);

            # Execute the post_check...

            # If we are in member mode, use the member post check, else use
            # plain ol' post check.
            my $pc = $members ? $fprof->{member_post_check} : $fprof->{post_check};
            if ( defined($pc) && $pc ) {

                eval {
                    unless ( $results->$pc() ) {

                        # If that returned false, then this field is invalid!
                        $field->clear_value;
                        $field->reason('post_check') unless $field->has_reason;
                        $field->valid(0);
                    }
                };
                if ($@) {
                    die $@ if ref $@;
                    $field->reason($@);
                    $field->clear_value;
                    $field->valid(0);
                }
            }
        }
    }

    if ( $self->has_derived ) {
        foreach my $key ( keys( %{ $self->derived } ) ) {
            my $prof = $self->derived->{$key};
            my $der  = $prof->{deriver};
            die "Derived fields must have a deriver!" unless defined($der);
            my $rv = $results->$der();

            my $req = $prof->{required};

            my $field = Data::Verifier::Field->new;

            # If the field is required and we got back undef then this
            # is a bad value!
            if ( defined($req) && $req && !defined($rv) ) {
                $field->valid(0);

                my $dfields = $prof->{fields};
                foreach my $df ( @{$dfields} ) {
                    my $f = $results->get_field($df);
                    die "Unknown field '$df' in derived field '$key'!" unless defined $f;
                    $f->valid(0);
                    $f->value(undef);
                    $f->reason('derived');
                }
            }
            else {
                # It's valid, set it to true and put the return value
                # in.
                $field->valid(1);
                $field->value($rv);
                $field->reason('derived');
            }
            $results->set_field( $key, $field );
        }
    }

    return $results;
}

sub _filter_value {
    my ( $self, $filters, $values ) = @_;

    my $created_ref = 0;
    if ( ref($filters) ne 'ARRAY' ) {
        $filters = [$filters];
    }

    # If we already have an array, just let it be. Otherwise transform the
    # value into an array. ($values may also be a HashRef[Str] here)
    unless ( ref $values eq 'ARRAY' ) {
        $created_ref = 1;
        $values      = [$values];
    }

    foreach my $f ( @{$filters} ) {

        foreach my $value ( @{$values} ) {
            if ( ref($f) ) {
                $value = $value->$f($value);
            }
            else {
                die "Unknown filter: $f" unless Data::Verifier::Filters->can($f);
                $value = Data::Verifier::Filters->$f($value);
            }
        }
    }

    # Return an arrayref if we have multiple values or a scalar if we have one
    return $created_ref ? $values->[0] : $values;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Verifier - Profile based data verification with Moose type constraints.

=head1 VERSION

version 0.56

=head1 SYNOPSIS

    use Data::Verifier;

    my $dv = Data::Verifier->new(
        filters => [ qw(trim) ],
        profile => {
            name => {
                required    => 1,
                type        => 'Str',
               filters     => [ qw(collapse) ]
            },
            age  => {
                type        => 'Int'
            },
            sign => {
                required    => 1,
                type        => 'Str'
            }
        }
    );

    # Pass in a hash of data
    my $results = $dv->verify({
        name => 'Cory', age => 'foobar'
    });

    $results->success; # no

    $results->is_invalid('name'); # no
    $results->is_invalid('age');  # yes

    $results->is_missing('name'); # no
    $results->is_missing('sign'); # yes

    $results->get_original_value('name'); # Unchanged, original value
    $results->get_value('name'); # Filtered, valid value
    $results->get_value('age');  # undefined, as it's invalid

=head1 DESCRIPTION

Data::Verifier allows you verify data (such as web forms, which was the
original idea) by leveraging the power of Moose's type constraint system.

=head1 MOTIVATION

Data::Verifier firstly intends to leverage Moose's type constraint system,
which is significantly more powerful than anything I could create for the
purposes of this module.  Secondly it aims to keep a fairly simple interface
by leveraging the aforementioned type system to keep options to a minimum.

=head1 NOTES

=head2 Multiple Values

It should be noted that if you choose to make a param a C<Str> then validation
will fail if multiple values are provided.  To allow multiple values you
must use an C<ArrayRef[Str]>.

=head2 ArrayRef based types (more on Multiple Values)

If you use an ArrayRef-based parameterized type (e.g. ArrayRef[Str]) then
Data::Verifier has the following behavior:

Each parameter supplied for the field is checked.  If all the members pass
then the field is considered valid.  If any of the members fail, then the
entire field is invalid.  If any of the members pass then those members will
be included in the C<values> attribute.  An example:

    use Moose::Util::TypeConstraints;
    use Data::Verifier;

    subtype 'Over10'
    => as 'Num'
    => where { $_ > 10 };

    my $verifier = Data::Verifier->new(
    profile => {
        foos => {
            type => 'ArrayRef[NumberOver10]',
        }
    }
    );

    my $res = $verifier->verify(foos => [ 1, 2, 30, 40 ]);
    $res->success; # This is false, as 1 and 2 did not pass
    $res->get_value('foos'); # [ 30, 40 ] because 30 and 40 passed!
    $res->original_value('foos); # [ 1, 2, 30, 40 ] because it's all of them!

It should also be noted that C<post_check>s that are specified in the profile
do B<not> get applied to the individual members, only to the entire, completed
field that they are constituents of.

B<Note>: Filters and such DO get applied to individual fields, so something
like:

    my $verifier = Data::Verifier->new(
      filters => qw(trim),
      profile => {
          foos => {
              type => 'ArrayRef[Str]',
              filters => 'collapse'
          }
      }
    );

In the above example, both C<trim> and C<collapse> B<bill> be applied to each
member of foos.

=head2 Stops on First Failure

Data::Verifier stops checking a field (not all, just the failed one) if it
fails any of it's constraints. Consult the Execution Order below to ascertain
the order.  For example, if a field exceeds it's max length then it will not
be checked against it's type constraint.

=head2 Serialization

Data::Verifier uses L<MooseX::Storage> to allow serialization of
L<Data::Verifier::Results> objects.  You can use this to store results for
validation across redirects.  Note, however, that the C<value>
attribute is B<not> serialized.  Since you can coerce a value into anything
it is not reasonable to expect to be able to serialize it.  Have a look at
the C<original_value> or C<post_filter_value> in L<Data::Verifier::Results>
if you want to know more.

=head2 Verifying Objects

Data::Verifier can verify data encapsulated in objects too. Everything works
the way that it does for hash references.  Each key in the profile is used as
the name of a method to call on the object. In order to maintain consistency
with the hash reference case, missing methods pass an 'undef' value into the
verification process.

=head2 Execution Order

It may be important to understand the order in which the various steps of
verification are performed:

=over 4

=item Global Filters

Any global filters in the profile are executed.

=item Per-Field Filters

Any per-field filters are executed.

=item Empty String Check

If the value of the field is an empty string then it is changed to an undef.

=item Required Check

The parameter must now be defined if it is set as required.

=item Length Check

Minimum then maximum length is checked.

=item Type Check (w/Coercion)

At this point the type will be checked after an optional coercion.

=item Dependency Checks

If this field has dependents then those will now be processed.

=item Post Check

If the field has a post check it will now be executed.

=item Derived Fields

Finally any derived fields are run.

=back

=head1 ATTRIBUTES

=head2 derived

An optional hashref of fields that will be derived from inspecting one or more
fields in the profile.

The keys for C<derived> are as follows:

=over 4

=item B<required>

Marks this derived field as required.  If the C<deriver> returns undef then
when this is true then the field, any source C<fields> and (in turn) the entire
profile will be invalid.

=item B<fields>

An optional arrayref that contains the names of any "source" fields that
should be considered invalid if this field is determiend to be invalid.

=item B<deriver>

A subref that is passed a copy of the final results for the profile.  The
return value of this subref will be used as the value for the field. A return
value of undef will cause the field (and any source fields) to be makred
invalid B<if> required is true.

=back

An example:

    my $verifier = Data::Verifier->new(
        profile => {
            first_name => {
                required => 1
            },
            last_name => {
                required => 1
            }
        },
        derived => {
            'full_name' => {
                required => 1,
                fields => [qw(first_name last_name)],
                deriver => sub {
                    my $r = shift;
                    return $r->get_value('first_name').' '.$r->get_value('last_name')
                }
            }
        }
    );

In the above example a field named C<full_name> will be created that is
the other two fields concatenated.  If the derived field is required and
C<deriver> subref returns undef then the derived field B<and> the fields
listed in C<fields> will also be invalid.

=head2 filters

An optional arrayref of filter names through which B<all> values will be
passed.

=head2 profile

The profile is a hashref.  Each value you'd like to verify is a key.  The
values specify all the options to use with the field.  The available options
are:

=over 4

=item B<coerce>

If true then the value will be given an opportunity to coerce via Moose's
type system.  If this is set, coercion will be ignored.

=item B<coercion>

Set this attribute to the coercion defined for this type.  If B<coerce> is
set this attribute will be ignored.  See the C<coercion> method above.

=item B<dependent>

Allows a set of fields to be specifid as dependents of this one.  The argument
for this key is a full-fledged profile as you would give to the profile key:

  my $verifier = Data::Verifier->new(
      profile => {
          password    => {
              dependent => {
                  password2 => {
                      required => 1,
                  }
              }
          }
      }
  );

In the above example C<password> is not required.  If it is provided then
password2 must also be provided.  If any depedents of a field are missing or
invalid then that field is B<invalid>.  In our example if password is provided
and password2 is missing then password will be invalid.

=item B<filters>

An optional list of filters through which this specific value will be run.
See the documentation for L<Data::Verifier::Filters> to learn more.  This
value my be either a scalar (string or coderef) or an arrayref of strings or
coderefs.

=item B<max_length>

An optional length which the value may not exceed.

=item B<min_length>

An optional length which the value may not be less.

=item B<member_post_check>

A post check that is only to be applied to the members of an ArrayRef based
type.  Because it is verified in something of a vacuum, the results object it
receives will have no other values to look at.  Therefore member_post_check
is only useful if you want to do some sort of weird post-check thing that I
can't imagine would be a good idea.

=item B<post_check>

The C<post_check> key takes a subref and, after all verification has finished,
executes the subref with the results of the verification as it's only argument.
The subref's return value determines if the field to which the post_check
belongs is invalid.  A typical example would be when the value of one field
must be equal to the other, like an email confirmation:

  my $verifier = Data::Verifier->new(
      profile => {
          email    => {
              required => 1,
              dependent => {
                  email2 => {
                      required => 1,
                  }
              },
              post_check => sub {
                  my $r = shift;
                  return $r->get_value('email') eq $r->get_value('email2');
              }
          },
      }
  );

  my $results = $verifier->verify({
      email => 'foo@example.com', email2 => 'foo2@example.com'
  });

  $results->success; # false
  $results->is_valid('email'); # false
  $results->is_valid('email2'); # true, as it has no post_check

In the above example, C<success> will return false, because the value of
C<email> does not match the value of C<email2>.  C<is_valid> will return false
for C<email> but true for C<email2>, since nothing specifically invalidated it.
In this example you should rely on the C<email> field, as C<email2> carries no
significance but to confirm C<email>.

B<Note about post_check and exceptions>: If have a more complex post_check
that could fail in multiple ways, you can C<die> in your post_check coderef
and the exception will be stored in the fields C<reason> attribute.

B<Note about post_check and ArrayRef based types>: The post check is B<not>
executed for ArrayRef based types.  See the note earlier in this documentation
about ArrayRefs.

=item B<required>

Determines if this field is required for verification.

=item B<type>

The name of the Moose type constraint to use with verifying this field's
value. Note, this will also accept an instance of
L<Moose::Meta::TypeConstraint>, although it may not serialize properly as a
result.

=back

=head1 METHODS

=head2 coercion

Define a coercion to use for verification.  This will not define a global
Moose type coercion, but is instead just a single coercion to apply to a
specific entity.

    my $verifier = Data::Verifier->new(
        profile => {
            a_string => {
                type     => 'Str',
                coercion => Data::Verifier::coercion(
                    from => 'Int',
                        via => sub { (qw[ one two three ])[ ($_ - 1) ] }
                ),
            },
        }
    );

=head2 verify (\%parameters)

Call this method and provide the parameters you are checking.  The results
will be provided to you as a L<Data::Verifier::Results> object.

=head1 CONTRIBUTORS

Mike Eldridge

George Hartzell

Tomohiro Hosaka

Stevan Little

Jason May

Dennis Schön

J. Shirley

Wallace Reis

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
