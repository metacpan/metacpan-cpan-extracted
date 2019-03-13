package Data::Object::Func::Scalar::Ge;

use Data::Object Class;

extends 'Data::Object::Func::Scalar';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Any',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  $self->throw("Greater-than or equal-to is not supported");

  return;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Scalar::Ge

=cut

=head1 ABSTRACT

Data-Object Scalar Function (Ge) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Scalar::Ge;

  my $func = Data::Object::Func::Scalar::Ge->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Scalar::Ge is a function object for Data::Object::Scalar.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Scalar->new(\*main);

  my $func = Data::Object::Func::Scalar::Ge->new(
    arg1 => $data,
    arg2 => ''
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
