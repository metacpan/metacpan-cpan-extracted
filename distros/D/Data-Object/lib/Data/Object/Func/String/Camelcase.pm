package Data::Object::Func::String::Camelcase;

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

  my $result = ucfirst(lc("$data"));

  $result =~ s/[^a-zA-Z0-9]+([a-z])/\U$1/g;
  $result =~ s/[^a-zA-Z0-9]+//g;

  return $result;
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::String::Camelcase

=cut

=head1 ABSTRACT

Data-Object String Function (Camelcase) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::String::Camelcase;

  my $func = Data::Object::Func::String::Camelcase->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::String::Camelcase is a function object for Data::Object::String.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::String->new("hello world");

  my $func = Data::Object::Func::String::Camelcase->new(
    arg1 => $data
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
