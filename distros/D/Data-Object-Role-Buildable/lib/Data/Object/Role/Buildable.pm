package Data::Object::Role::Buildable;

use 5.014;

use Moo::Role;

our $VERSION = '0.03'; # VERSION

sub BUILD {

  return $_[0];
}

around BUILD => sub {
  my ($orig, $self, $args) = @_;

  if ($self->can('build_self')) {
    $self->build_self($args);
  }

  return $self;
};

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  # build_arg accepts a single-arg (non-hash)
  my $inflate = @args == 1 && ref $args[0] ne 'HASH';

  # single argument
  if ($class->can('build_arg') && $inflate) {
    @args = ($class->build_arg($args[0]));
  }

  # build_args should not accept a single-arg (non-hash)
  my $ignore = @args == 1 && ref $args[0] ne 'HASH';

  # standard arguments
  if ($class->can('build_args') && !$ignore) {
    @args = ($class->build_args(@args == 1 ? $args[0] : {@args}));
  }

  return $class->$orig(@args);
};

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Buildable

=cut

=head1 ABSTRACT

Buildable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Vehicle;

  use Moo;

  with 'Data::Object::Role::Buildable';

  has name => (
    is => 'rw'
  );

  1;

=cut

=head1 DESCRIPTION

This package provides methods for hooking into object construction of the
consuming class, e.g. handling single-arg object construction.

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 buildarg

  package Car;

  use Moo;

  extends 'Vehicle';

  sub build_arg {
    my ($class, $name) = @_;

    # do something with $name or $class ...

    return { name => $name };
  }

  package main;

  my $car = Car->new('tesla');

This package supports handling a C<build_arg> method, as a hook into object
construction, which is called and passed a single argument if a single argument
is passed to the constructor.

=cut

=head2 buildargs

  package Sedan;

  use Moo;

  extends 'Car';

  sub build_args {
    my ($class, $args) = @_;

    # do something with $args or $class ...

    $args->{name} = ucfirst $args->{name};

    return $args;
  }

  package main;

  my $sedan = Sedan->new('tesla');

This package supports handling a C<build_args> method, as a hook into object
construction, which is called and passed a C<hashref> during object
construction.

=cut

=head2 buildself

  package Taxicab;

  use Moo;

  extends 'Sedan';

  sub build_self {
    my ($self, $args) = @_;

    # do something with $self or $args ...

    $args->{name} = 'Toyota';

    return;
  }

  package main;

  my $taxicab = Taxicab->new('tesla');

This package supports handling a C<build_self> method, as a hook into object
construction, which is called and passed a C<hashref> during object
construction. Note: Manipulating the arguments doesn't effect object's
construction or properties.

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-role-buildable/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-role-buildable/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-role-buildable>

L<Initiatives|https://github.com/iamalnewkirk/data-object-role-buildable/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-role-buildable/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-role-buildable/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-role-buildable/issues>

=cut
