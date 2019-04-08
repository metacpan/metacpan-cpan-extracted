package Data::Object::Func::Array::Lt;

use Data::Object 'Class';

extends 'Data::Object::Func::Array';

our $VERSION = '0.95'; # VERSION

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

  $self->throw("Less-than is not supported");

  return;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Array::Lt

=cut

=head1 ABSTRACT

Data-Object Array Function (Lt) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Array::Lt;

  my $func = Data::Object::Func::Array::Lt->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Array::Lt is a function object for Data::Object::Array.

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

  my $func = Data::Object::Func::Array::Lt->new(
    arg1 => $data,
    arg2 => [1..4]
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
