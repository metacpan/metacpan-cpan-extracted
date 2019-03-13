package Data::Object::Func::Undef::Eq;

use Data::Object Class;

extends 'Data::Object::Func::Undef';

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

  my ($arg1, $arg2) = $self->unpack;

  return !!$arg2 ? 0 : 1;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Undef::Eq

=cut

=head1 ABSTRACT

Data-Object Undef Function (Eq) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Undef::Eq;

  my $func = Data::Object::Func::Undef::Eq->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Undef::Eq is a function object for Data::Object::Undef.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Undef->new(undef);

  my $func = Data::Object::Func::Undef::Eq->new(
    arg1 => $data,
    arg2 => undef
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
