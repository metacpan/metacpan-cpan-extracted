package Data::Object::Func::Hash::Values;

use Data::Object Class;

extends 'Data::Object::Func::Hash';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has args => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, @args) = $self->unpack;

  return [@args ? @{$data}{@args} : values(%$data)];
}

sub mapping {
  return ('arg1', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::Values

=cut

=head1 ABSTRACT

Data-Object Hash Function (Values) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Values;

  my $func = Data::Object::Func::Hash::Values->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Values is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Hash->new({1..8});

  my $func = Data::Object::Func::Hash::Values->new(
    arg1 => $data,
    args => [1,3]
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
