package Data::Object::Kind;

use 5.014;

use strict;
use warnings;
use routines;

use Data::Object::Class;

our $VERSION = '0.01'; # VERSION

# METHODS

method class() {
  my $class = ref $self || $self;

  return $class;
}

method detract() {
  require Data::Object::Cast;

  return Data::Object::Cast::DetractDeep($self);
}

method space() {
  require Data::Object::Space;

  return Data::Object::Space->new($self->class);
}

method type() {
  require Data::Object::Cast;

  return Data::Object::Cast::TypeName($self);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Kind

=cut

=head1 ABSTRACT

Abstract Base Class for Data::Object Value Classes

=cut

=head1 SYNOPSIS

  package Data::Object::Hash;

  use base 'Data::Object::Kind';

  sub new {
    bless {};
  }

  package main;

  my $hash = Data::Object::Hash->new;

=cut

=head1 DESCRIPTION

This package provides methods common across all L<Data::Object> value classes.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 class

  class() : Str

The class method returns the class name for the given class or object.

=over 4

=item class example #1

  # given: synopsis

  $hash->class; # Data::Object::Hash

=back

=cut

=head2 detract

  detract() : Any

The detract method returns the raw data value for a given object.

=over 4

=item detract example #1

  # given: synopsis

  $hash->detract; # {}

=back

=cut

=head2 space

  space() : SpaceObject

The space method returns a L<Data::Object::Space> object for the given object.

=over 4

=item space example #1

  # given: synopsis

  $hash->space; # <Data::Object::Space>

=back

=cut

=head2 type

  type() : Str

The type method returns object type string.

=over 4

=item type example #1

  # given: synopsis

  $hash->type; # HASH

=back

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
