package Data::Object::Func::Hash::Join;

use Data::Object Class;

extends 'Data::Object::Func::Hash';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data) = $self->unpack;

  $self->throw("The join() comparison operation is not supported");
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::Join

=cut

=head1 ABSTRACT

Data-Object Hash Function (Join) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Join;

  my $func = Data::Object::Func::Hash::Join->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Join is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Hash->new({1..4});

  my $func = Data::Object::Func::Hash::Join->new(
    arg1 => $data
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
