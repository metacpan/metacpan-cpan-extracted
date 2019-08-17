package Data::Object::Func::Hash::EachKey;

use Data::Object 'Class';

extends 'Data::Object::Func::Hash';

our $VERSION = '0.98'; # VERSION

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

  my $results = [];

  my ($data, $code, $args) = $self->unpack;

  for my $key (keys %$data) {
    my $value = $data->{$key};

    push @$results, $code->($key, @$args);
  }

  return $results;
}

sub mapping {
  return ('arg1', 'arg2', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::EachKey

=cut

=head1 ABSTRACT

Data-Object Hash Function (EachKey) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::EachKey;

  my $func = Data::Object::Func::Hash::EachKey->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::EachKey is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Hash->new({1..8,9,undef});

  my $sets = [];

  my $func = Data::Object::Func::Hash::EachKey->new(
    arg1 => $data,
    arg2 => sub { push @$sets, [@_] }
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
