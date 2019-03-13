package Data::Object::Func::Code::Rcurry;

use Data::Object Class;

extends 'Data::Object::Func::Code';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has args => (
  is => 'ro',
  isa => 'ArrayRef[Any]',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, @args) = $self->unpack;

  return sub { $data->(@_, @args) };
}

sub mapping {
  return ('arg1', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Code::Rcurry

=cut

=head1 ABSTRACT

Data-Object Code Function (Rcurry) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Code::Rcurry;

  my $func = Data::Object::Func::Code::Rcurry->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Code::Rcurry is a function object for Data::Object::Code.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Code->new(sub { [@_] });

  my $func = Data::Object::Func::Code::Rcurry->new(
    arg1 => $data,
    args => [1,2,3]
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
