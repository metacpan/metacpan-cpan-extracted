package Data::Object::Func::Hash::Grep;

use Data::Object Class;

extends 'Data::Object::Func::Hash';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Str | CodeRef',
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

  my @caught;

  for my $key (keys %$data) {
    my $value = $data->{$key};
    my $refs = {'$key' => \$key, '$value' => \$value};
    my $result = $self->codify($code, $refs)->($value, @args);
    push @caught, $key, $value if $result;
  }

  return {@caught};
}

sub mapping {
  return ('arg1', 'arg2', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::Grep

=cut

=head1 ABSTRACT

Data-Object Hash Function (Grep) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Grep;

  my $func = Data::Object::Func::Hash::Grep->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Grep is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Hash->new({1..4});

  my $func = Data::Object::Func::Hash::Grep->new(
    arg1 => $data,
    arg2 => sub { $_[0] >= 3 }
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
