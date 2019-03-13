package Data::Object::Registry;

use strict;
use warnings;

use Data::Object::State;
use Type::Registry;

use parent 'Data::Object::Kind';

# BUILD
# METHODS

sub def {
  'Data::Object::Config::Library';
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

  my $def = $registry->def();

Returns the default type library.

=cut

=head2 get

  my $get = $registry->get($key);

The get method returns the value of the element with the specific key.

=cut

=head2 lut

  my $lut = $registry->lut($key);

Returns the lookup table for a given namespace.

=cut

=head2 obj

  my $obj = $registry->obj($key);

Return the L<Type::Registry> object for a given namespace.

=cut

=head2 rem

  my $rem = $registry->rem($key, $val);

Remove the registered type library from a given namespace.

=cut

=head2 set

  my $set = $registry->set($key, $val);

Set the supplied key and value, and return the value.

=cut

=head2 tns

  my $tns = $registry->tns();

Returns the registered type-namespaces.

=cut
