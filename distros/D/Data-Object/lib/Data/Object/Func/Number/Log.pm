package Data::Object::Func::Number::Log;

use Data::Object 'Class';

extends 'Data::Object::Func::Number';

our $VERSION = '0.99'; # VERSION

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

  return log($data);
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Number::Log

=cut

=head1 ABSTRACT

Data-Object Number Function (Log) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Number::Log;

  my $func = Data::Object::Func::Number::Log->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Number::Log is a function object for Data::Object::Number.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Number->new(12345);

  my $func = Data::Object::Func::Number::Log->new(
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
