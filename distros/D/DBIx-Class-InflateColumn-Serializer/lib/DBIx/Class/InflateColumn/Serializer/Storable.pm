package DBIx::Class::InflateColumn::Serializer::Storable;
$DBIx::Class::InflateColumn::Serializer::Storable::VERSION = '0.09';
=head1 NAME

DBIx::Class::InflateColumn::Serializer::Storable - Storable Inflator

=head1 SYNOPSIS

  package MySchema::Table;
  use base 'DBIx::Class';

  __PACKAGE__->load_components('InflateColumn::Serializer', 'Core');
  __PACKAGE__->add_columns(
    'data_column' => {
      'data_type' => 'VARCHAR',
      'size'      => 255,
      'serializer_class'   => 'Storable'
    }
  );

Then in your code...

  my $struct = { 'I' => { 'am' => 'a struct' };
  $obj->data_column($struct);
  $obj->update;

And you can recover your data structure with:

  my $obj = ...->find(...);
  my $struct = $obj->data_column;

The data structures you assign to "data_column" will be saved in the database in Storable format.

=cut

use strict;
use warnings;
use Storable qw//;
use Carp;

=over 4

=item get_freezer

Called by DBIx::Class::InflateColumn::Serializer to get the routine that serializes
the data passed to it. Returns a coderef.

=cut

sub get_freezer{
  my ($class, $column, $info, $args) = @_;

  if (defined $info->{'size'}){
      my $size = $info->{'size'};
      return sub {
        my $s = Storable::nfreeze(shift);
        croak "serialization too big" if (length($s) > $size);
        return $s;
      };
  } else {
      return sub {
        return Storable::nfreeze(shift);
      };
  }
}

=item get_unfreezer

Called by DBIx::Class::InflateColumn::Serializer to get the routine that deserializes
the data stored in the column. Returns a coderef.

=back

=cut


sub get_unfreezer {
  return sub {
    my $value = shift;
    # Storable returns undef if the datastructure couldn't be thawed.
    # Other deserializers throw exceptions, so we'll do the same.
    # If the column had a NULL value, then we return it (don't want to die)
    return undef if (not defined $value);
    my $s = Storable::thaw($value);
    croak "Storable couldn't thaw the value" if (not defined $s);
    return $s;
  };
}


1;
