package Data::Object::Role::Arguable;

use 5.014;

use strict;
use warnings;
use routines;

use Moo::Role;

with 'Data::Object::Role::Buildable';

requires 'argslist';

our $VERSION = '0.01'; # VERSION

# BUILD

method build_arg($arg) {
  if (ref $arg eq 'ARRAY') {
    return $self->packargs(@$arg);
  }
  else {
    return $arg;
  }
}

# METHODS

method packargs(@args) {
  my $data = {};

  for my $expr ($self->argslist) {
    last if !@args;

    my $regx = qr/^(\W*)(\w+)$/;

    my ($type, $attr) = $expr =~ $regx;

    if (!$type) {
      $data->{$attr} = shift(@args);
    } elsif ($type eq '@') {
      $data->{$attr} = [@args];
      last;
    } elsif ($type eq '%') {
      $data->{$attr} = {@args};
      last;
    }
  }

  return $data;
}

method unpackargs() {
  my @args;

  for my $expr ($self->argslist) {
    my $regx = qr/^(\W*)(\w+)$/;

    my ($type, $attr) = $expr =~ $regx;

    if (!$type) {
      push @args, $self->$attr;
    } elsif ($type eq '@') {
      push @args, @{$self->$attr} if $self->$attr;
      last;
    } elsif ($type eq '%') {
      push @args, @{$self->$attr} if $self->$attr;
      last;
    }
  }

  return @args;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Arguable

=cut

=head1 ABSTRACT

Arguable Role for Perl 5 Plugin Classes

=cut

=head1 SYNOPSIS

  package Example;

  use Moo;

  with 'Data::Object::Role::Arguable';

  has name => (
    is => 'ro'
  );

  has options => (
    is => 'ro'
  );

  sub argslist {
    ('name', '@options')
  }

  package main;

  my $example = Example->new(['james', 'red', 'white', 'blue']);

=cut

=head1 DESCRIPTION

This package provides a mechanism for unpacking an argument list and creating a
data structure suitable for passing to the consumer constructor. The
C<argslist> routine should return a list of attribute names in the order to be
parsed. An attribute name maybe prefixed with B<"@"> to denote that all remaining
items should be assigned to an arrayref, e.g. C<@options>, or B<"%"> to denote
that all remaining items should be assigned to a hashref, e.g. C<%options>.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 packargs

  packargs() : HashRef

The packargs method uses C<argslist> to return a data structure suitable for
passing to the consumer constructor.

=over 4

=item packargs example #1

  package main;

  my $example = Example->new;

  my $attributes = $example->packargs('james', 'red', 'white', 'blue');

=back

=cut

=head2 unpackargs

  unpackargs(Any @args) : (Any)

The unpackargs method uses C<argslist> to return a list of arguments from the
consumer class instance in the appropriate order.

=over 4

=item unpackargs example #1

  package main;

  my $example = Example->new(['james', 'red', 'white', 'blue']);

  my $arguments = [$example->unpackargs];

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
