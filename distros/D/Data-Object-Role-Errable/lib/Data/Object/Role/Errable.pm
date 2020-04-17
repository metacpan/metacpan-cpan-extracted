package Data::Object::Role::Errable;

use 5.014;

use strict;
use warnings;

use registry 'Data::Object::Types';
use routines;

use Data::Object::Role;
use Data::Object::RoleHas;
use Data::Object::Exception;

with 'Data::Object::Role::Tryable';

our $VERSION = '0.01'; # VERSION

# ATTRIBUTES

has 'error' => (
  is => 'rw',
  isa => 'ExceptionObject | HashRef | Str',
  opt => 1,
  tgr => method($value) {
    $value = { message => $value } if !ref $value;

    die $self->{error} = Data::Object::Exception->new(
      %$value, context => $self
    );
  },
  clr => 'error_reset'
);

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Errable

=cut

=head1 ABSTRACT

Errable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Moo;

  with 'Data::Object::Role::Errable';

  package main;

  my $example = Example->new;

  # $example->error('Oops!')

=cut

=head1 DESCRIPTION

This package provides a mechanism for handling errors (exceptions). It's a more
structured approach to being L<"throwable"|Data::Object::Role::Throwable>. The
idea is that any object that consumes this role can set an error which
automatically throws an exception which if trapped includes the state (object
as thrown) in the exception context.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Tryable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 error

  error(ExceptionObject)

This attribute is read-write, accepts C<(ExceptionObject)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 error

  error(ExceptionObject $exception | HashRef $options | Str $message) : ExceptionObject

The error method takes an error message (string) or hashref of exception object
constructor attributes and throws an L<"exception"|Data::Object::Exception>. If
the exception is trapped the exception object will contain the object as the
exception context. The original object will also have the exception set as the
error attribute. The error attribute can be cleared using the C<error_reset>
method.

=over 4

=item error example #1

  package main;

  my $example = Example->new;

  $example->error('Oops!');

  # throws exception

=back

=over 4

=item error example #2

  package main;

  my $example = Example->new;

  $example->error({ message => 'Oops!'});

  # throws exception

=back

=over 4

=item error example #3

  package main;

  my $example = Example->new;
  my $exception = Data::Object::Exception->new('Oops!');

  $example->error($exception);

  # throws exception

=back

=cut

=head2 error_reset

  error_reset() : Any

The error_reset method clears any exception object set on the object.

=over 4

=item error_reset example #1

  package main;

  my $example = Example->new;

  eval { $example->error('Oops!') };

  $example->error_reset

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-role-errable/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-role-errable/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-role-errable>

L<Initiatives|https://github.com/iamalnewkirk/data-object-role-errable/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-role-errable/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-role-errable/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-role-errable/issues>

=cut
