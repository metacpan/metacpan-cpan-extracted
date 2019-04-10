package Data::Object::Func::Hash::Lookup;

use Data::Object 'Class';

extends 'Data::Object::Func::Hash';

our $VERSION = '0.96'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $path) = $self->unpack;

  return undef
    unless ($data and $path)
    and (('HASH' eq ref($data))
    or Scalar::Util::blessed($data) and $data->isa('HASH'));

  return $data->{$path} if $data->{$path};

  my $next;
  my $rest;

  ($next, $rest) = $path =~ /(.*)\.([^\.]+)$/;

  if ($next and $data->{$next}) {
    return $self->new($data->{$next}, $rest)->execute;
  }

  ($next, $rest) = $path =~ /([^\.]+)\.(.*)$/;

  if ($next and $data->{$next}) {
    return $self->new($data->{$next}, $rest)->execute;
  }

  return undef;
}

sub mapping {
  return ('arg1', 'arg2');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::Hash::Lookup

=cut

=head1 ABSTRACT

Data-Object Hash Function (Lookup) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Lookup;

  my $func = Data::Object::Func::Hash::Lookup->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Lookup is a function object for Data::Object::Hash.

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

  my $func = Data::Object::Func::Hash::Lookup->new(
    arg1 => $data,
    arg2 => 1
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
