package Data::Object::Func::Hash::Lt;

use Data::Object Class;

extends 'Data::Object::Func::Hash';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'HashLike',
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

Data::Object::Func::Hash::Lt

=cut

=head1 ABSTRACT

Data-Object Hash Function (Lt) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Lt;

  my $func = Data::Object::Func::Hash::Lt->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Lt is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Hash->new({1..8});

  my $func = Data::Object::Func::Hash::Lt->new(
    arg1 => $data,
    arg2 => {1..4}
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
