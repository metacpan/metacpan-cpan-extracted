package Data::Object::Class;

use 5.014;

use strict;
use warnings;

use parent 'Moo';

our $VERSION = '2.02'; # VERSION

1;

=encoding utf8

=head1 NAME

Data::Object::Class

=cut

=head1 ABSTRACT

Class Builder for Perl 5

=cut

=head1 SYNOPSIS

  package Identity;

  use Data::Object::Class;

  package main;

  my $id = Identity->new;

=cut

=head1 DESCRIPTION

This package modifies the consuming package making it a class.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Moo>

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 extends

  # given: synopsis

  package Person;

  use Data::Object::Class;

  extends 'Identity';

  package main;

  my $person = Person->new;

This package supports the C<extends> keyword, which is used to declare
superclasses your class will inherit from. See L<Moo> for more information.

=cut

=head2 has

  # given: synopsis

  package Person;

  use Data::Object::Class;

  has name => (
    is => 'ro'
  );

  package main;

  my $person = Person->new(name => '...');

This package supports the C<has> keyword, which is used to declare class
attributes, which can be accessed and assigned to using the built-in
getter/setter or by the object constructor. See L<Moo> for more information.

=cut

=head2 with

  # given: synopsis

  package Employable;

  use Moo::Role;

  package Person;

  use Data::Object::Class;

  with 'Employable';

  package main;

  my $person = Person->new;

This package supports the C<with> keyword, which is used to declare roles to be
used and compose into your class. See L<Moo> for more information.

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-class/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-class/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-class>

L<Initiatives|https://github.com/iamalnewkirk/data-object-class/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-class/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-class/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-class/issues>

=cut
