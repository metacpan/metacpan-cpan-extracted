package Data::Object::Func::String::Split;

use Data::Object 'Class';

extends 'Data::Object::Func::String';

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'RegexpRef | Str',
  def => sub { qr() },
  opt => 1
);

has arg3 => (
  is => 'ro',
  isa => 'Num',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $pattern, $limit) = $self->unpack;

  my $regexp = UNIVERSAL::isa($pattern, 'Regexp');

  $pattern = quotemeta($pattern) if $pattern and !$regexp;

  return [split(/$pattern/, "$data")] if !defined($limit);
  return [split(/$pattern/, "$data", $limit)];
}

sub mapping {
  return ('arg1', 'arg2', 'arg3');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::String::Split

=cut

=head1 ABSTRACT

Data-Object String Function (Split) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::String::Split;

  my $func = Data::Object::Func::String::Split->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::String::Split is a function object for Data::Object::String.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::String->new("hello");

  my $func = Data::Object::Func::String::Split->new(
    arg1 => $data,
    arg2 => qr/[aeiou]/,
    arg3 => 0
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
