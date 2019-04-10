package Data::Object::Func::String::Contains;

use Data::Object 'Class';

extends 'Data::Object::Func::String';

our $VERSION = '0.96'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Str | RegexpRef',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $pattern) = $self->unpack;

  return 0 unless defined($pattern);

  my $regexp = UNIVERSAL::isa($pattern, 'Regexp');

  return index("$data", $pattern) < 0 ? 0 : 1 if !$regexp;

  return ("$data" =~ $pattern) ? 1 : 0;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::String::Contains

=cut

=head1 ABSTRACT

Data-Object String Function (Contains) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::String::Contains;

  my $func = Data::Object::Func::String::Contains->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::String::Contains is a function object for Data::Object::String.

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

  my $func = Data::Object::Func::String::Contains->new(
    arg1 => $data,
    arg2 => 'he'
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
