package Data::Object::Role::Tryable;

use 5.014;

use strict;
use warnings;
use routines;

use Moo::Role;
use Data::Object::Try;

our $VERSION = '2.00'; # VERSION

# METHODS

method try($callback, @args) {
  my $try = Data::Object::Try->new(invocant => $self, arguments => [@args]);

  $callback = $try->callback($callback); # build callback

  return $try->call($callback);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Tryable

=cut

=head1 ABSTRACT

Tryable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Moo;

  with 'Data::Object::Role::Tryable';

  package main;

  use routines;

  my $example = Example->new;

=cut

=head1 DESCRIPTION

This package provides a wrapper around the L<Data::Object::Try> class which
provides an object-oriented interface for performing complex try/catch
operations.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 try

  try(CodeRef | Str $method) : InstanceOf['Data::Object::Try']

The try method takes a method name or coderef and returns a
L<Data::Object::Try> object with the current object passed as the invocant
which means that C<try> and C<finally> callbacks will receive that as the first
argument.

=over 4

=item try example #1

  # given: synopsis

  my $tryer = $example->try(fun(@args) {
    [@args]
  });

  # $tryer->result(...)

=back

=over 4

=item try example #2

  # given: synopsis

  my $tryer = $example->try(fun(@args) {
    die 'tried';
  });

  $tryer->default(fun($error) {
    return ['tried'] if $error =~ 'tried';
    return [$error];
  });

  # $tryer->result(...)

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-role-tryable/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-role-tryable/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-role-tryable>

L<Initiatives|https://github.com/iamalnewkirk/data-object-role-tryable/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-role-tryable/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-role-tryable/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-role-tryable/issues>

=cut
