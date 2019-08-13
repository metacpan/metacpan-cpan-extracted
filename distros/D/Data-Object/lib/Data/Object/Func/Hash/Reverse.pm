package Data::Object::Func::Hash::Reverse;

use Data::Object 'Class';

extends 'Data::Object::Func::Hash';

our $VERSION = '0.97'; # VERSION

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

  my $retv = {};

  for (keys %$data) {
    if (defined($data->{$_})) {
      $retv->{$_} = $data->{$_};
    }
  }

  return {reverse %$retv};
}

sub mapping {
  return ('arg1');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::Reverse

=cut

=head1 ABSTRACT

Data-Object Hash Function (Reverse) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Reverse;

  my $func = Data::Object::Func::Hash::Reverse->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Reverse is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Hash->new({1..4});

  my $func = Data::Object::Func::Hash::Reverse->new(
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
