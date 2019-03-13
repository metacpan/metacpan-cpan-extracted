package Data::Object::Func::String::Lcfirst;

use Data::Object Class;

extends 'Data::Object::Func::String';

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

  return lcfirst("$data");
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::String::Lcfirst

=cut

=head1 ABSTRACT

Data-Object String Function (Lcfirst) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::String::Lcfirst;

  my $func = Data::Object::Func::String::Lcfirst->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::String::Lcfirst is a function object for Data::Object::String.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::String->new("Hello world");

  my $func = Data::Object::Func::String::Lcfirst->new(
    arg1 => $data
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
