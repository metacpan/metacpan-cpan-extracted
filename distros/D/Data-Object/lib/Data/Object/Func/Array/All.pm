package Data::Object::Func::Array::All;

use Data::Object 'Class';

extends 'Data::Object::Func::Array';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'CodeRef',
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

  my ($data, $code, @args) = $self->unpack;

  my $found = 0;

  for (my $i = 0; $i < @$data; $i++) {
    my $index = $i;
    my $value = $data->[$i];

    $found++ if $code->($value, @args);
  }

  return $found == @$data ? 1 : 0;
}

sub mapping {
  return ('arg1', 'arg2', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Array::All

=cut

=head1 ABSTRACT

Data-Object Array Function (All) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Array::All;

  my $func = Data::Object::Func::Array::All->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Array::All is a function object for Data::Object::Array.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Array->new([1..4]);

  my $func = Data::Object::Func::Array::All->new(
    arg1 => $data,
    arg2 => sub { $_[0] >= 1 }
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
