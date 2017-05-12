package DBIx::Class::WithMetaData::Inflator;

use strict;
use warnings;
use Moose;
extends 'DBIx::Class::ResultClass::HashRefInflator';

around inflate_result => sub {
  my $orig = shift;
  my $self = shift;

  my $hash = $self->$orig(@_);

  my ($source, @rest) = @_;
  my $row =  $source->result_class->inflate_result(@_);
  return [$hash, $row];
};

1;
