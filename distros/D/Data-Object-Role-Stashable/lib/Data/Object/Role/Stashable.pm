package Data::Object::Role::Stashable;

use 5.014;

use strict;
use warnings;
use routines;

use Moo::Role;

our $VERSION = '2.01'; # VERSION

# BUILD

method BUILD($args) {

  return $args;
}

around BUILD($args) {
  $self->$orig($args);

  $self->{'$stash'} = {} if !$self->{'$stash'};

  return $args;
}

# METHODS

method stash($key, $value) {
  return $self->{'$stash'} if !exists $_[0];

  return $self->{'$stash'}->{$key} if !exists $_[1];

  $self->{'$stash'}->{$key} = $value;

  return $value;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Stashable

=cut

=head1 ABSTRACT

Stashable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Moo;

  with 'Data::Object::Role::Stashable';

  package main;

  my $example = Example->new;

=cut

=head1 DESCRIPTION

This package provides methods for stashing data within the object.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 stash

  stash(Maybe[Str] $key, Maybe[Any] $value) : Any

The stash method is used to fetch and stash named values associated with the
object. Calling this method without arguments returns all values.

=over 4

=item stash example #1

  # given: synopsis

  my $result = $example->stash;

  [$result, $example]

=back

=over 4

=item stash example #2

  # given: synopsis

  my $result = $example->stash(time => time);

  [$result, $example]

=back

=over 4

=item stash example #3

  # given: synopsis

  my $result = $example->stash('time');

  [$result, $example]

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-role-stashable/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-role-stashable/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-role-stashable>

L<Initiatives|https://github.com/iamalnewkirk/data-object-role-stashable/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-role-stashable/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-role-stashable/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-role-stashable/issues>

=cut
