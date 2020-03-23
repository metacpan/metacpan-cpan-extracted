package Data::Object::Vars;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

with 'Data::Object::Role::Buildable';
with 'Data::Object::Role::Proxyable';
with 'Data::Object::Role::Stashable';

our $VERSION = '2.01'; # VERSION

# ATTRIBUTES

has 'named' => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1,
);

# BUILD

method build_self($args) {
  $self->{named} = {} if !$args->{named};

  my $envv = { map +($_, $ENV{$_}), keys %ENV };

  $self->stash(envv => $envv);

  return $self;
}

method build_proxy($package, $method, $value) {
  my $has_value = exists $_[2];

  return sub {

    return $self->get($method) if !$has_value; # no val

    return $self->set($method, $value);
  };
}

# METHODS

method exists($key) {
  return if not defined $key;

  my $pos = $self->name($key);

  return if not defined $pos;

  return exists $self->stashed->{$pos};
}

method get($key) {
  return if not defined $key;

  my $pos = $self->name($key);

  return if not defined $pos;

  return $self->stashed->{$pos};
}

method name($key) {
  if (defined $self->named->{$key}) {
    return $self->named->{$key};
  }

  if (defined $self->stashed->{$key}) {
    return $key;
  }

  if (defined $self->stashed->{uc($key)}) {
    return uc($key);
  }

  return undef;
}

method set($key, $val) {
  return if not defined $key;

  my $pos = $self->name($key);

  return if not defined $pos;

  return $self->stashed->{$pos} = $val;
}

method stashed() {
  my $data = $self->stash('envv');

  return $data;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Vars

=cut

=head1 ABSTRACT

Env Vars Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Vars;

  local %ENV = (USER => 'ubuntu', HOME => '/home/ubuntu');

  my $vars = Data::Object::Vars->new(
    named => { iam => 'USER', root => 'HOME' }
  );

  # $vars->root; # $ENV{HOME}
  # $vars->home; # $ENV{HOME}
  # $vars->get('home'); # $ENV{HOME}
  # $vars->get('HOME'); # $ENV{HOME}

  # $vars->iam; # $ENV{USER}
  # $vars->user; # $ENV{USER}
  # $vars->get('user'); # $ENV{USER}
  # $vars->get('USER'); # $ENV{USER}

=cut

=head1 DESCRIPTION

This package provides methods for accessing C<%ENV> items.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Buildable>

L<Data::Object::Role::Proxyable>

L<Data::Object::Role::Stashable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 named

  named(HashRef)

This attribute is read-only, accepts C<(HashRef)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 exists

  exists(Str $key) : Any

The exists method takes a name or index and returns truthy if an associated
value exists.

=over 4

=item exists example #1

  # given: synopsis

  $vars->exists('iam'); # truthy

=back

=over 4

=item exists example #2

  # given: synopsis

  $vars->exists('USER'); # truthy

=back

=over 4

=item exists example #3

  # given: synopsis

  $vars->exists('PATH'); # falsy

=back

=over 4

=item exists example #4

  # given: synopsis

  $vars->exists('user'); # truthy

=back

=cut

=head2 get

  get(Str $key) : Any

The get method takes a name or index and returns the associated value.

=over 4

=item get example #1

  # given: synopsis

  $vars->get('iam'); # ubuntu

=back

=over 4

=item get example #2

  # given: synopsis

  $vars->get('USER'); # ubuntu

=back

=over 4

=item get example #3

  # given: synopsis

  $vars->get('PATH'); # undef

=back

=over 4

=item get example #4

  # given: synopsis

  $vars->get('user'); # ubuntu

=back

=cut

=head2 name

  name(Str $key) : Any

The name method takes a name or index and returns index if the the associated
value exists.

=over 4

=item name example #1

  # given: synopsis

  $vars->name('iam'); # USER

=back

=over 4

=item name example #2

  # given: synopsis

  $vars->name('USER'); # USER

=back

=over 4

=item name example #3

  # given: synopsis

  $vars->name('PATH'); # undef

=back

=over 4

=item name example #4

  # given: synopsis

  $vars->name('user'); # USER

=back

=cut

=head2 set

  set(Str $key, Maybe[Any] $value) : Any

The set method takes a name or index and sets the value provided if the
associated argument exists.

=over 4

=item set example #1

  # given: synopsis

  $vars->set('iam', 'root'); # root

=back

=over 4

=item set example #2

  # given: synopsis

  $vars->set('USER', 'root'); # root

=back

=over 4

=item set example #3

  # given: synopsis

  $vars->set('PATH', '/tmp'); # undef

  # is not set

=back

=over 4

=item set example #4

  # given: synopsis

  $vars->set('user', 'root'); # root

=back

=cut

=head2 stashed

  stashed() : HashRef

The stashed method returns the stashed data associated with the object.

=over 4

=item stashed example #1

  # given: synopsis

  $vars->stashed

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-vars/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-vars/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-vars>

L<Initiatives|https://github.com/iamalnewkirk/data-object-vars/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-vars/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-vars/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-vars/issues>

=cut
