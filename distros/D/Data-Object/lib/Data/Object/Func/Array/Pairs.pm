package Data::Object::Func::Array::Pairs;

use Data::Object Class;

extends 'Data::Object::Func::Array';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  return $self->arg1->pairs_array;
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Array::Pairs

=cut

=head1 ABSTRACT

Data-Object Array Function (Pairs) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Array::Pairs;

  my $func = Data::Object::Func::Array::Pairs->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Array::Pairs is a function object for Data::Object::Array.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Array->new([1..4]);

  my $func = Data::Object::Func::Array::Pairs->new(
    arg1 => $data
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
