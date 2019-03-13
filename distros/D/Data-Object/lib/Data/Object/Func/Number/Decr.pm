package Data::Object::Func::Number::Decr;

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
  def => 1,
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $arg2) = $self->unpack;

  unless (Scalar::Util::looks_like_number("$arg2")) {
    return $self->throw("Argument is not number-like");
  }

  return "$data" - "$arg2";
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Number::Decr

=cut

=head1 ABSTRACT

Data-Object Number Function (Decr) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Number::Decr;

  my $func = Data::Object::Func::Number::Decr->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Number::Decr is a function object for Data::Object::Number.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Number->new(100);

  my $func = Data::Object::Func::Number::Decr->new(
    arg1 => $data
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
