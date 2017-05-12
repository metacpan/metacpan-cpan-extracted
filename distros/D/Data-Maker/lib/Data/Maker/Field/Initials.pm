package Data::Maker::Field::Initials;
use Moose;
extends 'Data::Maker::Field::Code';

our $VERSION = '0.17';

has from_field => ( is => 'rw', isa => 'Str' );
has from_field_set => ( is => 'rw', isa => 'ArrayRef' );

has code => (
  is => 'rw',
  default => sub {
    sub {
      my ($this, $maker) = @_;
      my $out;
      if ($this->from_field_set) {
        $out = join('', map { substr($_, 0, 1) } map { $maker->in_progress($_) } @{$this->from_field_set} );
      } elsif ($this->from_field) {
        my $source = $maker->in_progress( $this->from_field );
        $out = join('', map { substr($_, 0, 1) } split(' ', $source));
      }
      return $out;
    }
  }
);

1;
__END__

=head1 NAME

Data::Maker::Field::Initials - A L<Data::Maker> field class that generates its data from the initials of either the the value of a single field, or the value of multiple fields, previously determined in the same record.   This class is a subclass of L<Data::Maker::Field::Code>.

=head1 SYNOPSIS

There are two ways to use the Initials class:

=head2 Derive the initials from one field

The initials will be derived from the first letter of each word in the last value generated for the given field.

  use Data::Maker;
  use Data::Maker::Field::Lorem;
  use Data::Maker::Field::Initials;

  my $maker = Data::Maker->new(
    record_count => 10,
    fields => [
      {
        name => 'foo',
        class => 'Data::Maker::Field::Lorem',
        args => {
          words => 5
        }
      },
      {
        name => 'foo_initials',
        class => 'Data::Maker::Field::Initials',
        args => {
          from_field => 'foo'
        }
      },
    ]
  );

=head2 Derive the initials from multiple fields

The initials will be derived from the first letter of the last value generated for the each field.

  use Data::Maker;
  use Data::Maker::Field::Person;
  use Data::Maker::Field::Initials;

  my $maker = Data::Maker->new(
    record_count => 10,
    fields => [
      {
        name => 'firstname',
        class => 'Data::Maker::Field::Person::FirstName'
      },
      {
        name => 'lastname',
        class => 'Data::Maker::Field::Person::LastName'
      },
      {
        name => 'initials',
        class => 'Data::Maker::Field::Initials',
        args => {
          from_field_set => [ 'firstname', 'lastname']
        }
      },
    ]
  );

=head1 DESCRIPTION

Data::Maker::Field::Initials takes one of two arguments:

=over 4

=item B<from_field> NAME

Takes the name of the field from which the initials will be derived, based on the first letter of each word of the last value generated for the named field.

=item B<from_field> ARRAYREF

Takes the a list of fields from which the initials will be derived, based on the first letters of the last values generated for each field in the list.

=back

=head1 AUTHOR

John Ingram (john@funnycow.com)

=head1 LICENSE

Copyright 2010 by John Ingram. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
