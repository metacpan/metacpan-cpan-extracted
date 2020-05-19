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

requires 'formulate';

our $VERSION = '0.03'; # VERSION

around BUILDARGS(@args) {
  my $results;

  $results = $self->formulate($self->$orig(@args));

  return $results;
}

around formulate($args) {
  my $results;

  my $form = $self->$orig($args);

  # before
  if ($self->can('before_formulate')) {
    my $config = $self->before_formulate($args);

    for my $key (keys %$config) {
      next unless $form->{$key};
      next unless exists $args->{$key};

      my $name = $config->{$key} eq '1' ?
        "before_formulate_${key}" : $config->{$key};

      next unless $self->can($name);

      $args->{$key} = $self->$name($args->{$key});
    }
  }

  # formulation
  $results = $self->formulation($args, $form);

  # after
  if ($self->can('after_formulate')) {
    my $config = $self->after_formulate($results);

    for my $key (keys %$config) {
      next unless $form->{$key};
      next unless exists $results->{$key};

      my $name = $config->{$key} eq '1' ?
        "after_formulate_${key}" : $config->{$key};

      next unless $self->can($name);

      $results->{$key} = $self->$name($results->{$key});
    }
  }

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

Data::Object::Role::Formulatable - Objectify Class Attributes

=cut

=head1 ABSTRACT

Formulatable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Test::Student;

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

  my $student = Test::Student->new({
    name => 'levi nolan',
    dates => ['1587717124', '1587717169']
  });

  # $student->name;
  # <Test::Data::Str>

  # $student->dates;
  # [<Test::Data::Str>]

=cut

=head1 DESCRIPTION

This package provides a mechanism for automatically inflating objects from
constructor arguments.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Buildable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 automation

  package Test::Teacher;

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

  sub after_formulate {
    {
      name => 1
    }
  }

  sub after_formulate_name {
    my ($self, $value) = @_;

    $value
  }

  sub before_formulate {
    {
      name => 1
    }
  }

  sub before_formulate_name {
    my ($self, $value) = @_;

    $value
  }

  package main;

  my $teacher = Test::Teacher->new({
    name => 'levi nolan',
    dates => ['1587717124', '1587717169']
  });

  # $teacher->name;
  # <Test::Data::Str>

  # $teacher->dates;
  # [<Test::Data::Str>]

This package supports automatically calling I<"before"> and I<"after"> routines
specific to each piece of data provided. This is automatically enabled if the
presence of a C<before_formulate> and/or C<after_formulate> routine is
detected. If so, these routines should return a hashref keyed off the class
attributes where the values are either C<1> (denoting that the hook name should
be generated) or some other routine name.

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-role-formulatable/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-role-formulatable/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-role-formulatable>

L<Initiatives|https://github.com/iamalnewkirk/data-object-role-formulatable/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-role-formulatable/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-role-formulatable/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-role-formulatable/issues>

=cut
