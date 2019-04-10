package Data::Object::Func::String::Lines;

use Data::Object 'Class';

extends 'Data::Object::Func::String';

our $VERSION = '0.96'; # VERSION

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

  return [split(/[\n\r]+/, "$data")];
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::String::Lines

=cut

=head1 ABSTRACT

Data-Object String Function (Lines) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::String::Lines;

  my $func = Data::Object::Func::String::Lines->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::String::Lines is a function object for Data::Object::String.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::String->new("hello\nworld");

  my $func = Data::Object::Func::String::Lines->new(
    arg1 => $data
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
