package Data::Object::Func::Integer::Ne;

use Data::Object Class;

extends 'Data::Object::Func::Integer';

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

  return (("$arg1" + 0) != ("$arg2" + 0)) ? 1 : 0;

}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Integer::Ne

=cut

=head1 ABSTRACT

Data-Object Integer Function (Ne) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Integer::Ne;

  my $func = Data::Object::Func::Integer::Ne->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Integer::Ne is a function object for Data::Object::Integer.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Integer->new(1);

  my $func = Data::Object::Func::Integer::Ne->new(
    arg1 => $data,
    arg2 => 1
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
