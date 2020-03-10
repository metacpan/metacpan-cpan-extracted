package Data::Object::Plugin;

use 5.014;

use strict;
use warnings;
use routines;

use Data::Object::Class;

our $VERSION = '0.01'; # VERSION

# METHODS

method execute() {

  return $self;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Plugin

=cut

=head1 ABSTRACT

Plugin Class for Perl 5

=cut

=head1 SYNOPSIS

  package Plugin;

  use Data::Object::Class;

  extends 'Data::Object::Plugin';

  package main;

  my $plugin = Plugin->new;

=cut

=head1 DESCRIPTION

This package provides an abstract base class for defining plugin classes.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 execute

  execute() : Any

The execute method is the main method and entrypoint for plugin classes.

=over 4

=item execute example #1

  # given: synopsis

  $plugin->execute

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-plugin/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-plugin/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-plugin>

L<Initiatives|https://github.com/iamalnewkirk/data-object-plugin/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-plugin/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-plugin/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-plugin/issues>

=cut
