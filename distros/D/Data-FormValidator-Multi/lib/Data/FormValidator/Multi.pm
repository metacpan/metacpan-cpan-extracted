use warnings;
use strict;

use Data::FormValidator::Multi::Results;

package Data::FormValidator::Multi;
use base qw(Data::FormValidator);

our $VERSION = '0.002';

=encoding utf8

=head1 NAME

Data::FormValidator::Multi - Check multidimensional data structures with
Data::FormValidator

=head1 SYNOPSIS

    use Data::FormValidator::Multi;

    # a hash that has hashes and arrays as some of its values
    my $data = { ... };

    # a Data::FormValidator profile
    my $main_profile      = { ... };

    # Data::FormValidator profiles for hashes and arrays in $data
    my $meta_profile      = { ... };
    my $timezones_profile = { ... };
    
    # create the validator
    my $dfv = Data::FormValidator::Multi->new({
      profile     => $main_profile,
      subprofiles => {
        meta        => $meta_profile,
        timezones   => $timezones_profile,
      }
    });
    
    # run the check on the data
    my $results = $dfv->check( $data );
    
    # call ->to_json on the results object to get a data structure of errors
    use Data::Dumper;
    print Data::Dumper->Dump([$results->to_json], ['results_as_json']);

=head1 DESCRIPTION

Data::FormValidator feels like the sanest data validator to me other than now
that I use angular a lot I'm POSTing complex data structures now instead of
CGI key=value pairs.

This module provides the ability to validate complex data structures and keep
the same DFV C<if ( $results-E<gt>success ) { ... }> pattern during validation.

DFVM can validate arbitrarily nested hash and array data structures. For arrays
the specified profile is applied to each element in the array.

After a data structure is C<check()>ed, C<success()> will return false if a
single bit of data in the data structure is invalid. From there C<to_json()> can
be called on the C<$result> to get a data structure that has invalid fields as
keys and the errors for that field as its value. What I do with this return
value is pass it back to an angular controller so that, with of the magic
of two way binding, error messages and indicators magically light up.

=head1 EXAMPLE

Here is a complete example of validating a hash that has a hash and an array
as some of its values. See the F<t/lib/Test/Data/FormValidator/Multi/Nested.pm>
test for an example of validating an arbitrarily deep data structure.

    use warnings;
    use strict;
    
    use Data::FormValidator::Multi;
    
    # the data we are validating. Note the negative $data->{dashboard} and
    # $data->{timezones}[1]{id} fields, and the commented out hash entries.
    # These are the invalid / missing fields that DFVM will report on
    my $data = {
      dashboard => -23,
      name => 'FooBar',
      meta => {
        foo  => 'Foo',
    #    bar  => 'Bar',
        bazz => 'Bazz',
       },
      timezones => [
        {
          id   => 999,
          name => 'Home',
          zone => 'America/New_York',
          date => '01/01',
          time => '23:59'
        },
        {
          id   => -111,
          name => 'L. A.',
          zone => 'America/Los_Angeles',
    #      date => '01/01',
          time => '20:59'
        }
      ]
    };
    
    # profile for the fields in the top level of the input data
    my $main_profile = {
      required           => [qw(name dashboard timezones )],
      optional           => [qw(meta)],
      constraint_methods => {
        dashboard => [
          {
            name              => 'not_positive',
            constraint_method => sub {
              my ($dfv, $val) = @_;
              return $val =~ /\A\d+\z/;
            }
          }
        ]
      },
      msgs => {
        format      => '%s',
        invalid     => 'FIELD IS INVALID',
        missing     => 'FIELD IS REQUIRED',
        constraints => {
          not_positive => 'MUST BE POSITIVE'
        }
      }
    };
    
    # profile for the data in the $data->{meta} hash
    my $meta_profile = {
      required => [qw( foo bar bazz )],
      msgs     => {
        format  => '%s',
        invalid => 'FIELD IS INVALID',
        missing => 'FIELD IS REQUIRED',
      }
    };
    
    # profile for the data in the $data->{timezones} array
    my $timezones_profile = {
      required           => [ qw( id zone name date time ) ],
      constraint_methods => {
        id => [
          {
            name => 'not_positive',
            constraint_method => sub {
              my ($dfv, $val) = @_;
              return $val =~ /\A\d+\z/;
            }
          }
        ]
      },
      msgs => {
        format      => '%s',
        invalid     => 'FIELD IS INVALID',
        missing     => 'FIELD IS REQUIRED',
        constraints => {
          not_positive => 'MUST BE POSITIVE'
        }
      }
    };
    
    # create a profile, passing the top level profile under the 'profile' key, and
    # the profiles for the $data->{meta} hash and $data->{timezones} array as a
    # hash under the 'subprofiles' key.
    my $dfv = Data::FormValidator::Multi->new({
      profile     => $main_profile,
      subprofiles => {
        meta        => $meta_profile,
        timezones   => $timezones_profile,
      }
    });
    
    # run the check on the data
    my $results = $dfv->check( $data );
    
    use Data::Dumper;
    print Data::Dumper->Dump([$results->to_json], ['results_as_json']);

outputs:

    $results_as_json = {
                     'meta' => {
                                 'bar' => 'FIELD IS REQUIRED'
                               },
                     'timezones' => [
                                      undef,
                                      {
                                        'id' => 'MUST BE POSITIVE',
                                        'date' => 'FIELD IS REQUIRED'
                                      }
                                    ],
                     'dashboard' => 'MUST BE POSITIVE'
                   };

=head1 METHODS

=head2 check

If given an array, loop over them, do a DFVM check on each element, and return
an array blessed as a DFV::Multi::Results object.

Otherwise, call in to parent check method (plain Data::FormValidator) for
validation of the data and return the DFV::Multi::Results object.

=cut

sub check {
  my($self, $datas, $profile) = @_;

  my $results = [];
  if ( ref $datas eq 'ARRAY' ) {
    foreach my $data ( @$datas ) {
      my $element_results = (ref $self)->new->check( $data, $self->{profiles}{profile} );
      push @$results => $element_results;
    }
  } else {
    $results = $self->SUPER::check( $datas, $self->{profiles}{profile} || $profile );
  }

  bless $results => 'Data::FormValidator::Multi::Results';

  $self->check_nested( $results ) unless ref $datas eq 'ARRAY';

  return $results;
}

=head2 check_nested

=cut

sub check_nested {
  my($self, $results) = @_;

  my $profiles = $self->{profiles}{subprofiles} || {};
  foreach my $field ( keys %$profiles ) {
    $self->check_nested_for( $field => $results );
  }
}

=head2 check_nested_for

=cut

sub check_nested_for {
  my($self, $field, $results) = @_;

  my $profile = $self->{profiles}{subprofiles}{$field};

  if ( $profile->{subprofiles} ) {
    $self->has_nested_profiles( $profile, $field, $results );
  } else {
    $self->no_nested_profiles( $profile, $field, $results );
  }

}

=head2 has_nested_profiles

=cut

sub has_nested_profiles {
  my($self, $profile, $field, $results) = @_;

  if ( my $data = $results->valid($field) ) { # data can be an array or hash
    my $nested_results = (ref $self)->new( $profile )->check( $data );

    if ( ! $nested_results->success ) {
      $self->move_from_valid_to_objects( $field, $results, $nested_results );
    }
  }
}

=head2 no_nested_profiles

=cut

sub no_nested_profiles {
  my($self, $profile, $field, $results) = @_;

  if ( my $datas = $results->valid($field) ) { # data can be an array or hash

    if ( ref $datas eq 'HASH' ) {
      $self->handle_hash_input( $profile, $field, $results, $datas );
    } elsif ( ref $datas eq 'ARRAY' ) {
      $self->handle_array_input( $profile, $field, $results, $datas );
    } else {
      die 'dont know how to process $datas';
    }

  }

}

=head2 handle_hash_input

=cut

sub handle_hash_input {
  my($self, $profile, $field, $results, $datas) = @_;

  my $nested_results = Data::FormValidator::Multi::Results->new( $profile, $datas );

  if ( $nested_results->success ) {
    $results->valid( $field => $nested_results );
  } else {
    $self->move_from_valid_to_objects( $field, $results, $nested_results );
  }
}

=head2 handle_array_input

=cut

sub handle_array_input {
  my($self, $profile, $field, $results, $datas) = @_;

# $DB::single = 1;

  # set up some local state to handle error condition
  my $error = {};
  my $errors = $error->{errors} = [];
  $error->{total} = $error->{count} = 0;
  my $all_results = [];

  foreach my $data ( @$datas ) {
    $error->{total}++;
    push @$errors => undef; # array element gets replaced if there is an error

    my $nested_results = Data::FormValidator::Multi::Results->new( $profile, $data );

    push @$all_results => $nested_results;
    if ( ! $nested_results->success ) {
      $error->{count}++;
      pop @$errors;
      push @$errors => $nested_results;
    }
  }

  if ( ! $error->{count} ) {
    $results->valid( $field => $all_results );
  } else {
    $self->move_from_valid_to_objects( $field, $results, $errors )
  }
}

=head2 move_from_valid_to_objects

=cut

sub move_from_valid_to_objects {
  my($self, $field, $results, $field_results) = @_;

  delete $results->{valid}{$field};

  $results->{objects} ||= {};
  $results->{objects}{$field} = $field_results;
}

=head1 SEE ALSO

=over 4

=item *

L<Data::FormValidator>

=back

=head1 AUTHOR

Todd Wade <waveright@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Todd Wade.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
