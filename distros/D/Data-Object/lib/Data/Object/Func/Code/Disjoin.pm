package Data::Object::Func::Code::Disjoin;

use Data::Object Class;

extends 'Data::Object::Func::Code';

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

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $code) = $self->unpack;

  my $refs = {'$code' => \$code};

  $code = $self->codify($code);

  return sub { $data->(@_) || $code->(@_) };
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Code::Disjoin

=cut

=head1 ABSTRACT

Data-Object Code Function (Disjoin) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Code::Disjoin;

  my $func = Data::Object::Func::Code::Disjoin->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Code::Disjoin is a function object for Data::Object::Code.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  my $data = Data::Object::Code->new(sub { $_[0] % 2 });

  my $func = Data::Object::Func::Code::Disjoin->new(
    arg1 => $data,
    arg2 => sub { -1 }
  );

  my $result = $func->execute;

Executes the function logic and returns the result.

=cut

=head2 mapping

  my @data = $self->mapping;

Returns the ordered list of named function object arguments.

=cut
