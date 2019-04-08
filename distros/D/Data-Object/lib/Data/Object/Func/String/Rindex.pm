package Data::Object::Func::String::Rindex;

use Data::Object 'Class';

extends 'Data::Object::Func::String';

our $VERSION = '0.95'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has arg3 => (
  is => 'ro',
  isa => 'Num',
  def => 0,
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $substr, $start) = $self->unpack;

  return rindex("$data", $substr) if not defined $start;
  return rindex("$data", $substr, $start);
}

sub mapping {
  return ('arg1', 'arg2', 'arg3');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::String::Rindex

=cut

=head1 ABSTRACT

Data-Object String Function (Rindex) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::String::Rindex;

  my $func = Data::Object::Func::String::Rindex->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::String::Rindex is a function object for Data::Object::String.

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

  my $func = Data::Object::Func::String::Rindex->new(
    arg1 => $data,
    arg2 => 'l'
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
