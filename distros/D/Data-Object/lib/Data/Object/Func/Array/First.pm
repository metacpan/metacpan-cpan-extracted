package Data::Object::Func::Array::First;

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

  my ($data) = $self->unpack;

  return $data->[0];
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Array::First

=cut

=head1 ABSTRACT

Data-Object Array Function (First) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Array::First;

  my $func = Data::Object::Func::Array::First->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Array::First is a function object for Data::Object::Array.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Array->new([1..4]);

  my $func = Data::Object::Func::Array::First->new(
    arg1 => $data
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
