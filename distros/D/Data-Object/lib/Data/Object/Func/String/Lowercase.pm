package Data::Object::Func::String::Lowercase;

use Data::Object 'Class';

extends 'Data::Object::Func::String';

our $VERSION = '0.95'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  return $self->arg1->lc;
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::String::Lowercase

=cut

=head1 ABSTRACT

Data-Object String Function (Lowercase) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::String::Lowercase;

  my $func = Data::Object::Func::String::Lowercase->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::String::Lowercase is a function object for Data::Object::String.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::String->new("hellO World");

  my $func = Data::Object::Func::String::Lowercase->new(
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
