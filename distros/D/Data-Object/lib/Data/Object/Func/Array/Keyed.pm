package Data::Object::Func::Array::Keyed;

use Data::Object 'Class';

extends 'Data::Object::Func::Array';

our $VERSION = '0.96'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has args => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, @keys) = $self->unpack;

  my $i = 0;
  return {map { $_ => $data->[$i++] } @keys};
}

sub mapping {
  return ('arg1', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Array::Keyed

=cut

=head1 ABSTRACT

Data-Object Array Function (Keyed) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Array::Keyed;

  my $func = Data::Object::Func::Array::Keyed->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Array::Keyed is a function object for Data::Object::Array.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Array->new([1..5]);

  my $func = Data::Object::Func::Array::Keyed->new(
    arg1 => $data,
    args => ['a'..'d']
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
