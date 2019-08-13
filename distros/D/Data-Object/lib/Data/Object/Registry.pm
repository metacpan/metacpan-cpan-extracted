package Data::Object::Registry;

use strict;
use warnings;

use Data::Object::State;
use Type::Registry;

use parent 'Data::Object::Base';

our $VERSION = '0.97'; # VERSION

# BUILD
# METHODS

sub def {
  'Data::Object::Library';
}

sub get {
  my ($self, $key) = @_;

  return undef if !$key;

  return $self->tns->{$key};
}

sub lut {
  my ($self, $key) = @_;

  return [] if !$key;

  my $tbl = $self->get($key);

  return [] if !$tbl;

  return [sort { $tbl->{$a} <=> $tbl->{$b} } keys %$tbl];
}

sub obj {
  my ($self, $key) = @_;

  my $lut = $self->lut($key);

  unshift @$lut, $self->def;

  my $obj = "Type::Registry"->for_class($key);

  $obj->add_types($_) for @$lut;

  return $obj;
}

sub rem {
  my ($self, $key, $val) = @_;

  return undef if !$key || !$val;
  return undef if !$self->get($key);

  my $tns = $self->tns;

  return delete $tns->{$key}{$val};
}

sub set {
  my ($self, $key, $val) = @_;

  my $tns = $self->tns;
  my $tbl = $self->get($key) || {};

  $tns->{$key}{$val} = (keys(%$tbl) || 0) + 1 if !$tns->{$key}{$val};

  return $tns->{$key}{$val};
}

sub tns {
  my ($self) = @_;

  $self->{spaces} ||= {} if !$self->{spaces};

  return $self->{spaces};
}

1;

=encoding utf8

=head1 NAME

Data::Object::Registry

=cut

=head1 ABSTRACT

Data-Object Namespace Registry

=cut

=head1 SYNOPSIS

  use Data::Object::Registry;

  my $registry = Data::Object::Registry->new;

=cut

=head1 DESCRIPTION

Data::Object::Registry is a singleton that holds mappings for namespaces and
type libraries.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 def

  def() : Str

Returns the default type library.

=over 4

=item def example

  my $def = $registry->def();

=back

=cut

=head2 get

  get(Str $arg1) : Any

The get method returns the value of the element with the specific key.

=over 4

=item get example

  my $get = $registry->get($key);

=back

=cut

=head2 lut

  lut(Str $arg1) : ArrayRef

Returns the lookup table for a given namespace.

=over 4

=item lut example

  my $lut = $registry->lut($key);

=back

=cut

=head2 obj

  obj(ClassName $arg1) : InstanceOf[Type::Registry]

Return the L<Type::Registry> object for a given namespace.

=over 4

=item obj example

  my $obj = $registry->obj($key);

=back

=cut

=head2 rem

  rem(Str $arg1, Str $arg2) : Str

Remove the registered type library from a given namespace.

=over 4

=item rem example

  my $rem = $registry->rem($key, $val);

=back

=cut

=head2 set

  set(Str $arg1, Any $arg2) : Any

Set the supplied key and value, and return the value.

=over 4

=item set example

  my $set = $registry->set($key, $val);

=back

=cut

=head2 tns

  tns() : HashRef

Returns the registered type-namespaces.

=over 4

=item tns example

  my $tns = $registry->tns();

=back

=cut
