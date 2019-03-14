package Data::Object::Func::String::Replace;

use Data::Object Class;

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
  req => 1
);

has arg3 => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has arg4 => (
  is => 'ro',
  isa => 'Str',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $search, $replace, $flags) = $self->unpack;

  my $result = "$data";
  my $regexp = UNIVERSAL::isa($search, 'Regexp');

  $flags = defined($flags) ? $flags : '';
  $search = quotemeta($search) if $search and !$regexp;

  local $@;
  eval("sub { \$_[0] =~ s/$search/$replace/$flags }")->($result);

  return $result;
}

sub mapping {
  return ('arg1', 'arg2', 'arg3', 'arg4');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Func::String::Replace

=cut

=head1 ABSTRACT

Data-Object String Function (Replace) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::String::Replace;

  my $func = Data::Object::Func::String::Replace->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::String::Replace is a function object for Data::Object::String.

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

  my $func = Data::Object::Func::String::Replace->new(
    arg1 => $data,
    arg2 => 'ello',
    arg3 => 'ey'
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
