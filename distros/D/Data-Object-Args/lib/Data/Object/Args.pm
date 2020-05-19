package Data::Object::Args;

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

  my $argv = { map +($_, $ARGV[$_]), 0..$#ARGV };

  $self->stash(argv => $argv);

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

  return undef;
}

method set($key, $val) {
  return if not defined $key;

  my $pos = $self->name($key);

  return if not defined $pos;

  return $self->stashed->{$pos} = $val;
}

method stashed() {
  my $data = $self->stash('argv');

  return $data;
}

method unnamed() {
  my $list = [];

  my $argv = $self->stash('argv');
  my $data = +{reverse %{$self->named}};

  for my $index (sort keys %$argv) {
    unless (exists $data->{$index}) {
      push @$list, $argv->{$index};
    }
  }

  return $list;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Args - Args Class

=cut

=head1 ABSTRACT

Args Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Args;

  local @ARGV = qw(--help execute);

  my $args = Data::Object::Args->new(
    named => { flag => 0, command => 1 }
  );

  # $args->flag; # $ARGV[0]
  # $args->get(0); # $ARGV[0]
  # $args->get(1); # $ARGV[1]
  # $args->action; # $ARGV[1]
  # $args->exists(0); # exists $ARGV[0]
  # $args->exists('flag'); # exists $ARGV[0]
  # $args->get('flag'); # $ARGV[0]

=cut

=head1 DESCRIPTION

This package provides methods for accessing C<@ARGS> items.

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

  $args->exists(0); # truthy

=back

=over 4

=item exists example #2

  # given: synopsis

  $args->exists('flag'); # truthy

=back

=over 4

=item exists example #3

  # given: synopsis

  $args->exists(2); # falsy

=back

=cut

=head2 get

  get(Str $key) : Any

The get method takes a name or index and returns the associated value.

=over 4

=item get example #1

  # given: synopsis

  $args->get(0); # --help

=back

=over 4

=item get example #2

  # given: synopsis

  $args->get('flag'); # --help

=back

=over 4

=item get example #3

  # given: synopsis

  $args->get(2); # undef

=back

=cut

=head2 name

  name(Str $key) : Any

The name method takes a name or index and returns index if the the associated
value exists.

=over 4

=item name example #1

  # given: synopsis

  $args->name('flag'); # 0

=back

=cut

=head2 set

  set(Str $key, Maybe[Any] $value) : Any

The set method takes a name or index and sets the value provided if the
associated argument exists.

=over 4

=item set example #1

  # given: synopsis

  $args->set(0, '-?'); # -?

=back

=over 4

=item set example #2

  # given: synopsis

  $args->set('flag', '-?'); # -?

=back

=over 4

=item set example #3

  # given: synopsis

  $args->set('verbose', 1); # undef

  # is not set

=back

=cut

=head2 stashed

  stashed() : HashRef

The stashed method returns the stashed data associated with the object.

=over 4

=item stashed example #1

  # given: synopsis

  $args->stashed

=back

=cut

=head2 unnamed

  unnamed() : ArrayRef

The unnamed method returns an arrayref of values which have not been named
using the C<named> attribute.

=over 4

=item unnamed example #1

  package main;

  use Data::Object::Args;

  local @ARGV = qw(--help execute --format markdown);

  my $args = Data::Object::Args->new(
    named => { flag => 0, command => 1 }
  );

  $args->unnamed # ['--format', 'markdown']

=back

=over 4

=item unnamed example #2

  package main;

  use Data::Object::Args;

  local @ARGV = qw(execute phase-1 --format markdown);

  my $args = Data::Object::Args->new(
    named => { command => 1 }
  );

  $args->unnamed # ['execute', '--format', 'markdown']

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-args/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-args/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-args>

L<Initiatives|https://github.com/iamalnewkirk/data-object-args/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-args/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-args/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-args/issues>

=cut
