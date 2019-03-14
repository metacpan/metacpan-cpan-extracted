package Data::Object::Func::Scalar::Ne;

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

  my ($data) = $self->unpack;

  $self->throw("The ne() comparison operation is not supported");
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Scalar::Ne

=cut

=head1 ABSTRACT

Data-Object Scalar Function (Ne) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Scalar::Ne;

  my $func = Data::Object::Func::Scalar::Ne->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Scalar::Ne is a function object for Data::Object::Scalar.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Scalar->new(\*main);

  my $func = Data::Object::Func::Scalar::Ne->new(
    arg1 => $data,
    arg2 => undef
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
