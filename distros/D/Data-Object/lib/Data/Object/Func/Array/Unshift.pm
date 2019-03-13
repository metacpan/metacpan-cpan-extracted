package Data::Object::Func::Array::Unshift;

use Data::Object Class;

extends 'Data::Object::Func::Array';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has args => (
  is => 'ro',
  isa => 'ArrayRef[Any]',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, @args) = $self->unpack;

  unshift(@$data, @args);

  return $data;
}

sub mapping {
  return ('arg1', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Array::Unshift

=cut

=head1 ABSTRACT

Data-Object Array Function (Unshift) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Array::Unshift;

  my $func = Data::Object::Func::Array::Unshift->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Array::Unshift is a function object for Data::Object::Array.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Array->new([1..4]);

  my $func = Data::Object::Func::Array::Unshift->new(
    arg1 => $data,
    args => [5,6,7]
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
