package Data::Object::Func::String::Lcfirst;

use Data::Object 'Class';

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

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::String->new("Hello world");

  my $func = Data::Object::Func::String::Lcfirst->new(
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
