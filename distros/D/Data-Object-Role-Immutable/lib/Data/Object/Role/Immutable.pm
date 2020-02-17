package Data::Object::Role::Immutable;

use 5.014;

use strict;
use warnings;
use routines;

use Moo::Role;
use Readonly;

our $VERSION = '2.01'; # VERSION

# METHODS

method immutable() {
  if (UNIVERSAL::isa($self, 'HASH')) {
    Readonly::Hash(%$self, %$self);
  }
  if (UNIVERSAL::isa($self, 'ARRAY')) {
    Readonly::Array(@$self, @$self);
  }
  if (UNIVERSAL::isa($self, 'SCALAR')) {
    Readonly::Scalar($$self, $$self);
  }

  return $self;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Immutable

=cut

=head1 ABSTRACT

Immutable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Moo;

  with 'Data::Object::Role::Immutable';

  package main;

  my $example = Example->new;

=cut

=head1 DESCRIPTION

This package provides a mechanism for making any derived object immutable.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 immutable

  immutable() : Object

The immutable method returns the invocant as an immutable object, and will
throw an error if an attempt is made to modify the underlying value.

=over 4

=item immutable example #1

  # given: synopsis

  $example->immutable;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-role-immutable/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-role-immutable/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-role-immutable>

L<Initiatives|https://github.com/iamalnewkirk/data-object-role-immutable/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-role-immutable/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-role-immutable/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-role-immutable/issues>

=cut
