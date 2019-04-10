package Data::Object::Func::String::Lt;

use Data::Object 'Class';

extends 'Data::Object::Func::String';

our $VERSION = '0.96'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'StringLike',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($arg1, $arg2) = $self->unpack;

  return ("$arg1" lt "$arg2") ? 1 : 0;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::String::Lt

=cut

=head1 ABSTRACT

Data-Object String Function (Lt) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::String::Lt;

  my $func = Data::Object::Func::String::Lt->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::String::Lt is a function object for Data::Object::String.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::String->new("Hello");

  my $func = Data::Object::Func::String::Lt->new(
    arg1 => $data,
    arg2 => 'hello'
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
