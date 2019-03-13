package Data::Object::Func::Array::Le;

use Data::Object Class;

extends 'Data::Object::Func::Array';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'ArrayLike',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  $self->throw("Less-then or equal-to is not supported");

  return;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Array::Le

=cut

=head1 ABSTRACT

Data-Object Array Function (Le) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Array::Le;

  my $func = Data::Object::Func::Array::Le->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Array::Le is a function object for Data::Object::Array.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Array->new([1..4]);

  my $func = Data::Object::Func::Array::Le->new(
    arg1 => $data,
    arg2 => [1..4]
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
