package Data::Object::Func::Float::Defined;

use Data::Object Class;

extends 'Data::Object::Func::Float';

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

Data::Object::Func::Float::Defined

=cut

=head1 ABSTRACT

Data-Object Float Function (Defined) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Float::Defined;

  my $func = Data::Object::Func::Float::Defined->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Float::Defined is a function object for Data::Object::Float.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Float->new(1.23);

  my $func = Data::Object::Func::Float::Defined->new(
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
