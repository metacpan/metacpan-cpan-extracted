package Data::Object::Func::String::Append;

use Data::Object 'Class';

extends 'Data::Object::Func::String';

our $VERSION = '0.96'; # VERSION

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

  return join(' ', "$data", @args);
}

sub mapping {
  return ('arg1', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::String::Append

=cut

=head1 ABSTRACT

Data-Object String Function (Append) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::String::Append;

  my $func = Data::Object::Func::String::Append->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::String::Append is a function object for Data::Object::String.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::String->new("hello");

  my $func = Data::Object::Func::String::Append->new(
    arg1 => $data,
    args => ['world']
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
