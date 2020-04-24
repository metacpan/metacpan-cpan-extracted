package Data::Object::Role::Formulatable;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Role;
use Data::Object::RoleHas;
use Data::Object::Space;

use Scalar::Util ();

with 'Data::Object::Role::Buildable';
with 'Data::Object::Role::Errable';
with 'Data::Object::Role::Stashable';
with 'Data::Object::Role::Tryable';

requires 'formulate';

our $VERSION = '0.02'; # VERSION

around BUILDARGS(@args) {
  my $results;

  $results = $self->formulate($self->$orig(@args));

  return $results;
}

around formulate($args) {
  my $results;

  $results = $self->formulation($args, $self->$orig($args));

  return $results;
}

method formulate_object(Str $name, Any $value) {
  my $results;

  my $package = Data::Object::Space->new($name)->load;

  if (Scalar::Util::blessed($value) && $value->isa($package)) {
    $results = $value;
  }
  elsif (ref $value eq 'ARRAY') {
    $results = [map $package->new($_), @$value];
  }
  else {
    $results = $package->new($value);
  }

  return $results;
}

method formulation(HashRef $args, HashRef[Str] $form) {
  my $results = {};

  for my $name (grep {exists $args->{$_}} sort keys %$form) {
    $results->{$name} = $self->formulate_object($form->{$name}, $args->{$name});
  }

  return $results;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Formulatable

=cut

=head1 ABSTRACT

Formulatable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Test::Person;

  use registry;
  use routines;

  use Data::Object::Class;
  use Data::Object::ClassHas;

  with 'Data::Object::Role::Formulatable';

  has 'name';
  has 'dates';

  sub formulate {
    {
      name => 'test/data/str',
      dates => 'test/data/str'
    }
  }

  package main;

  my $person = Test::Person->new({
    name => 'levi nolan',
    dates => ['1587717124', '1587717169']
  });

  # $person->name;
  # <Test::Data::Str>

  # $person->dates;
  # [<Test::Data::Str>]

=cut

=head1 DESCRIPTION

This package provides a mechanism for automatically inflating objects from
constructor arguments.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Buildable>

L<Data::Object::Role::Errable>

L<Data::Object::Role::Stashable>

L<Data::Object::Role::Tryable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/foobar/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/foobar/wiki>

L<Project|https://github.com/iamalnewkirk/foobar>

L<Initiatives|https://github.com/iamalnewkirk/foobar/projects>

L<Milestones|https://github.com/iamalnewkirk/foobar/milestones>

L<Contributing|https://github.com/iamalnewkirk/foobar/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/foobar/issues>

=cut
