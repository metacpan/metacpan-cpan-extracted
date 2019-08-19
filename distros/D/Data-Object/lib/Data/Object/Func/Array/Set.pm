package Data::Object::Func::Array::Set;

use Data::Object 'Class';

extends 'Data::Object::Func::Array';

our $VERSION = '0.99'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has arg3 => (
  is => 'ro',
  isa => 'Any',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $index, $value) = $self->unpack;

  return $data->[$index] = $value;
}

sub mapping {
  return ('arg1', 'arg2', 'arg3');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Array::Set

=cut

=head1 ABSTRACT

Data-Object Array Function (Set) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Array::Set;

  my $func = Data::Object::Func::Array::Set->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Array::Set is a function object for Data::Object::Array.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Array->new([1..4]);

  my $func = Data::Object::Func::Array::Set->new(
    arg1 => $data,
    arg2 => 2,
    arg3 => 9
  );

  my $result = $func->execute;

=back

=cut

=head2 mapping

  mapping() : (Str)

Returns the ordered list of named function object arguments.

=over 4

=item mapping example

  my @data = $self->mapping;

=back

=cut
