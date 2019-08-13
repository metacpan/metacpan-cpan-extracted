package Data::Object::Func::Array::Random;

use Data::Object 'Class';

extends 'Data::Object::Func::Array';

our $VERSION = '0.97'; # VERSION

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

  return @$data[rand($#{$data} + 1)];
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Array::Random

=cut

=head1 ABSTRACT

Data-Object Array Function (Random) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Array::Random;

  my $func = Data::Object::Func::Array::Random->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Array::Random is a function object for Data::Object::Array.

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

  my $func = Data::Object::Func::Array::Random->new(
    arg1 => $data
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
