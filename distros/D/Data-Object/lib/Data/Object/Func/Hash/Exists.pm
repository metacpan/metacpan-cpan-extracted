package Data::Object::Func::Hash::Exists;

use Data::Object 'Class';

extends 'Data::Object::Func::Hash';

our $VERSION = '0.99'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Num',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $key) = $self->unpack;

  return exists $data->{$key} ? 1 : 0;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::Exists

=cut

=head1 ABSTRACT

Data-Object Hash Function (Exists) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Exists;

  my $func = Data::Object::Func::Hash::Exists->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Exists is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Hash->new({1..8,9,undef});

  my $func = Data::Object::Func::Hash::Exists->new(
    arg1 => $data,
    arg2 => 1
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
