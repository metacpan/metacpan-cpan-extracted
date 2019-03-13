package Data::Object::Func::Code::Call;

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
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, @args) = $self->unpack;

  return $data->(@args);
}

sub mapping {
  return ('arg1', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Code::Call

=cut

=head1 ABSTRACT

Data-Object Code Function (Call) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Code::Call;

  my $func = Data::Object::Func::Code::Call->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Code::Call is a function object for Data::Object::Code.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Code->new(sub { [@_] });

  my $func = Data::Object::Func::Code::Call->new(
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
