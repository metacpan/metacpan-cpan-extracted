package Data::Object::Func::Regexp::Gt;

use Data::Object 'Class';

extends 'Data::Object::Func::Regexp';

our $VERSION = '0.99'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Any',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  $self->throw("Greater-than is not supported");

  return;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Regexp::Gt

=cut

=head1 ABSTRACT

Data-Object Regexp Function (Gt) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Regexp::Gt;

  my $func = Data::Object::Func::Regexp::Gt->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Regexp::Gt is a function object for Data::Object::Regexp.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Regexp->new(qr/test/);

  my $func = Data::Object::Func::Regexp::Gt->new(
    arg1 => $data,
    arg2 => ''
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
