use strict;
use warnings;

use UNIVERSAL;

package Data::FormValidator::Multi::Results;
use base qw(Data::FormValidator::Results);
use List::Util qw(all);

=encoding utf8

=head1 NAME

Data::FormValidator::Multi::Results - Provide a multidimensional hash or array of DFVM results

=head1 SYNOPSIS

    # run the check on the data
    my $results = $dfv->check( $data );
    
    if ( ! $results->success ) {
      $c->stash->{json}{errors} = $results->to_json;
      return;
    }

    # handle valid data

=head1 DESCRIPTION

Results of the check performed by Data::FormValidator::Multi

=head1 METHODS

=head2 success

If this is an array of results, return true if all of the elements in the array
are valid.

If DF::Multi found invalid sub elements, return false. Otherwise, return
the parent class result of success.

=cut

sub success {
  my $self = shift;

  if ( $self->isa('ARRAY') ) {
    return all { $_->success } @$self;
  } else {
    return $self->has_objects ? undef : $self->SUPER::success;
  }
}

=head2 to_json

If this is an array of results, call to_json on each element and return an array
of the results. Otherwise, return a data structure that represents the invalid
(if any) data in the object.

=cut

sub to_json {
  my $self = shift;

  my $json = [];

  if ( $self->isa('ARRAY') ) {
    foreach my $results ( @$self ) {
      push @$json => $results->to_json;
    }
  } else {
    $json = $self->profile_json;
  }

  return $json;
}

=head2 profile_json

Build a hash with invalid field names as keys and that field's errors as the
value. Iterate over the invalid nested objects and call to_json on them.

=cut

sub profile_json {
  my $self = shift;

  my $json = {}; my $messages = $self->msgs;

  foreach my $field ( $self->missing, $self->invalid ) {
    $json->{$field} = $messages->{$field};
  }

  foreach my $field ( $self->objects ) {
    my $results = $self->objects->{ $field };

    if ( ref $results eq 'ARRAY' ) { # at least one element from input array has error
      my $errors = $json->{$field} = [];
      foreach my $result ( @$results ) {
#        if ( $result ) { # uhhh this returns false even when its an object?
        if ( UNIVERSAL::can( $result => 'to_json' ) ) {
          push @$errors => $result->to_json
        } else {
          push @$errors => undef;
        }
      }
    } else {
      $json->{$field} = $results->to_json;
    }
  }

  return $json;
}

=head2 has_objects

This method returns true if the results contain objects fields.

=cut

sub has_objects {
    return scalar keys %{$_[0]{objects}};

}

=head2 objects( [field] )

In list context, it returns the list of fields which are objects.
In a scalar context, it returns an hash reference which contains the objects
fields and their values.

If called with an argument, it returns the value of that C<field> if it
is objects, undef otherwise.

=cut

sub objects {
    return (wantarray ? Data::FormValidator::Results::_arrayify($_[0]{objects}{$_[1]}) : $_[0]{objects}{$_[1]})
      if (defined $_[1]);

    wantarray ? keys %{$_[0]{objects}} : $_[0]{objects};
}

=head1 SEE ALSO

=over 4

=item *

L<Data::FormValidator::Results>

=back

=head1 AUTHOR

Todd Wade <waveright@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Todd Wade.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
