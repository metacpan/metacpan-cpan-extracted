package Data::Object::Func::Hash::FilterInclude;

use Data::Object 'Class';

extends 'Data::Object::Func::Hash';

our $VERSION = '0.99'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has args => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, @args) = $self->unpack;

  return {
    map { exists($data->{$_}) ? ($_ => $data->{$_}) : () }
      @args
  };
}

sub mapping {
  return ('arg1', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::FilterInclude

=cut

=head1 ABSTRACT

Data-Object Hash Function (FilterInclude) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::FilterInclude;

  my $func = Data::Object::Func::Hash::FilterInclude->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::FilterInclude is a function object for Data::Object::Hash.

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

  my $func = Data::Object::Func::Hash::FilterInclude->new(
    arg1 => $data,
    args => [1,3]
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
