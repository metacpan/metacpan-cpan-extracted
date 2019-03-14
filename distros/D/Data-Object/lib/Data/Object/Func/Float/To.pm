package Data::Object::Func::Float::To;

use Data::Object Class;

extends 'Data::Object::Func::Float';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'StringLike',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($arg1, $arg2) = $self->unpack;

  unless (Scalar::Util::looks_like_number("$arg2")) {
    return $self->throw("Argument is not number-like");
  }

  return [reverse(int("$arg2") .. int("$arg1"))] if "$arg2" <= "$arg1";

  return [int("$arg1") .. int("$arg2")];
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Float::To

=cut

=head1 ABSTRACT

Data-Object Float Function (To) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Float::To;

  my $func = Data::Object::Func::Float::To->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Float::To is a function object for Data::Object::Float.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Float->new(1.23);

  my $func = Data::Object::Func::Float::To->new(
    arg1 => $data,
    arg2 => 2
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
