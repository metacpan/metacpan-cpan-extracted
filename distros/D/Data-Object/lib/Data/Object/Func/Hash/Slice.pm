package Data::Object::Func::Hash::Slice;

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
  isa => 'ArrayRef[Any]',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, @args) = $self->unpack;

  return {map { $_ => $data->{$_} } @args};
}

sub mapping {
  return ('arg1', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::Slice

=cut

=head1 ABSTRACT

Data-Object Hash Function (Slice) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Slice;

  my $func = Data::Object::Func::Hash::Slice->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Slice is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Hash->new({1..8});

  my $func = Data::Object::Func::Hash::Slice->new(
    arg1 => $data,
    args => [1,5]
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
