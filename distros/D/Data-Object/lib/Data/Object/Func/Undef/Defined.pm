package Data::Object::Func::Undef::Defined;

use Data::Object Class;

extends 'Data::Object::Func::Undef';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  return 0;
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Undef::Defined

=cut

=head1 ABSTRACT

Data-Object Undef Function (Defined) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Undef::Defined;

  my $func = Data::Object::Func::Undef::Defined->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Undef::Defined is a function object for Data::Object::Undef.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Undef->new(undef);

  my $func = Data::Object::Func::Undef::Defined->new(
    arg1 => $data
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
