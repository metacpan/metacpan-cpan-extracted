package Data::Object::Func::Code::Compose;

use Data::Object 'Class';

extends 'Data::Object::Func::Code';

our $VERSION = '0.96'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'CodeLike',
  req => 1
);

has args => (
  is => 'ro',
  isa => 'ArrayRef[Any]',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $code, @args) = $self->unpack;

  return sub { (sub { $code->($data->(@_)) })->(@args, @_) };
}

sub mapping {
  return ('arg1', 'arg2', '@args');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Code::Compose

=cut

=head1 ABSTRACT

Data-Object Code Function (Compose) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Code::Compose;

  my $func = Data::Object::Func::Code::Compose->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Code::Compose is a function object for Data::Object::Code.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Code->new(sub { [@_] });

  my $func = Data::Object::Func::Code::Compose->new(
    arg1 => $data,
    arg2 => sub { [@_] },
    args => [1,2,3]
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
