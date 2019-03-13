package Data::Object::Func::Integer::Defined;

use Data::Object Class;

extends 'Data::Object::Func::Integer';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  return 1;
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Integer::Defined

=cut

=head1 ABSTRACT

Data-Object Integer Function (Defined) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Integer::Defined;

  my $func = Data::Object::Func::Integer::Defined->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Integer::Defined is a function object for Data::Object::Integer.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Integer->new(-100);

  my $func = Data::Object::Func::Integer::Defined->new(
    arg1 => $data
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
