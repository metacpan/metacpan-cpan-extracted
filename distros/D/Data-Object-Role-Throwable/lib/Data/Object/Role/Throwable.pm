package Data::Object::Role::Throwable;

use 5.014;

use strict;
use warnings;
use routines;

use Moo::Role;

our $VERSION = '2.01'; # VERSION

# METHODS

method throw(@args) {
  require Data::Object::Exception;

  my $class = 'Data::Object::Exception';

  @args = ($args[0], $self, @args[1..$#args]);

  @_ = ($class, @args);

  goto $class->can('throw');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Throwable

=cut

=head1 ABSTRACT

Throwable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Moo;

  with 'Data::Object::Role::Throwable';

  package main;

  my $example = Example->new;

  # $example->throw

=cut

=head1 DESCRIPTION

This package provides mechanisms for throwing the object as an exception.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 throw

  throw(Tuple[Str, Str] | Str $message, Maybe[Number] $offset) : Any

The throw method throws an exception with the object and the given message. The
object is thrown as the exception context. See L<Data::Object::Exception> for
more information.

=over 4

=item throw example #1

  # given: synopsis

  $example->throw('Oops!');

=back

=over 4

=item throw example #2

  # given: synopsis

  $example->throw(['E001', 'Oops!']);

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-role-throwable/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-role-throwable/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-role-throwable>

L<Initiatives|https://github.com/iamalnewkirk/data-object-role-throwable/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-role-throwable/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-role-throwable/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-role-throwable/issues>

=cut
