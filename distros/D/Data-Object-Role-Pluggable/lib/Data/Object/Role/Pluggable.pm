package Data::Object::Role::Pluggable;

use 5.014;

use strict;
use warnings;
use routines;

use Moo::Role;

our $VERSION = '0.01'; # VERSION

# METHODS

method plugin($name, @args) {
  require Data::Object::Space;

  my $space = Data::Object::Space->new(ref $self);
  my $plugin = $space->child('plugin')->child($name);

  return $plugin->build(@args);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Pluggable

=cut

=head1 ABSTRACT

Pluggable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Data::Object::Class;

  with 'Data::Object::Role::Pluggable';

  package main;

  my $example = Example->new;

=cut

=head1 DESCRIPTION

This package provides a mechanism for dispatching to plugin classes.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 plugin

  plugin(Str $name, Any @args) : InstanceOf['Data::Object::Plugin']

The plugin method returns an instantiated plugin class whose namespace is based
on the package name of the calling class and the C<$name> argument provided. If
the plugin cannot be loaded this method will cause the program to crash.

=over 4

=item plugin example #1

  # given: synopsis

  package Example::Plugin::Formatter;

  use Data::Object::Class;

  extends 'Data::Object::Plugin';

  has name => (
    is => 'ro'
  );

  package main;

  $example->plugin(formatter => (name => 'lorem'));

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-role-functable/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-role-functable/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-role-functable>

L<Initiatives|https://github.com/iamalnewkirk/data-object-role-functable/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-role-functable/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-role-functable/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-role-functable/issues>

=cut
