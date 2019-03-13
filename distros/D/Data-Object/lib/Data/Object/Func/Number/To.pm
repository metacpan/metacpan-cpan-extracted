package Data::Object::Func::Number::To;

use Data::Object Class;

extends 'Data::Object::Func::Number';

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

Data::Object::Func::Number::To

=cut

=head1 ABSTRACT

Data-Object Number Function (To) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Number::To;

  my $func = Data::Object::Func::Number::To->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Number::To is a function object for Data::Object::Number.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Number->new(5);

  my $func = Data::Object::Func::Number::To->new(
    arg1 => $data,
    arg2 => 8
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
