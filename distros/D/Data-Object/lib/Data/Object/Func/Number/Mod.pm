package Data::Object::Func::Number::Mod;

use Data::Object 'Class';

extends 'Data::Object::Func::Number';

our $VERSION = '0.98'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'StringLike',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $arg2) = $self->unpack;

  return "$data" % "$arg2";
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Number::Mod

=cut

=head1 ABSTRACT

Data-Object Number Function (Mod) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Number::Mod;

  my $func = Data::Object::Func::Number::Mod->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Number::Mod is a function object for Data::Object::Number.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Number->new(100);

  my $func = Data::Object::Func::Number::Mod->new(
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
