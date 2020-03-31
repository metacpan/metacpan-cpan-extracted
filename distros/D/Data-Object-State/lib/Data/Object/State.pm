package Data::Object::State;

use 5.014;

use strict;
use warnings;

use Moo;

use parent 'Moo';

no warnings 'redefine';

our $VERSION = '2.00'; # VERSION

# BUILD

my %seen;

sub import {
  my ($class) = @_;

  my $target = caller;

  return if $seen{$target}++;

  eval "package $target; use Moo; 1;";

  no strict 'refs';

  *{"${target}::renew"} = $class->can('renew');
  *{"${target}::singleton"} = $class->can('singleton');
  *{"${target}::BUILD"} = $class->can('BUILD');

  return;
}

sub BUILD {
  my ($self, $args) = @_;

  $_[0] = $self->singleton($args);

  return $self;
}

# METHODS

sub renew {
  my ($self, @args) = @_;

  my $class = ref($self) || $self;

  no strict 'refs';

  undef ${"${class}::data"};

  return $class->new(@args);
}

sub singleton {
  my ($self, $args) = @_;

  my $class = ref($self) || $self;

  no strict 'refs';

  ${"${class}::data"} = {%$self, %$args} if !${"${class}::data"};

  return $_[0] = bless ${"${class}::data"}, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::State

=cut

=head1 ABSTRACT

Singleton Builder for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Data::Object::State;

  has data => (
    is => 'ro'
  );

  package main;

  my $example = Example->new;

=cut

=head1 DESCRIPTION

This package provides an abstract base class for creating singleton classes.
This package is derived from L<Moo> and makes consumers Moo classes (with all
that that entails). This package also injects a C<BUILD> method which is
responsible for hooking into the build process and returning the appropriate
state.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 new

  renew() : Object

The new method sets the internal state and returns a new class instance.
Subsequent calls to C<new> will return the same instance as was previously
returned.

=over 4

=item new example #1

  package Example::New;

  use Data::Object::State;

  has data => (
    is => 'ro'
  );

  my $example1 = Example::New->new(data => 'a');
  my $example2 = Example::New->new(data => 'b');

  [$example1, $example2]

=back

=cut

=head2 renew

  renew() : Object

The renew method resets the internal state and returns a new class instance.
Each call to C<renew> will discard the previous state, then reconstruct and
stash the new state as requested.

=over 4

=item renew example #1

  package Example::Renew;

  use Data::Object::State;

  has data => (
    is => 'ro'
  );

  my $example1 = Example::Renew->new(data => 'a');
  my $example2 = $example1->renew(data => 'b');
  my $example3 = Example::Renew->new(data => 'c');

  [$example1, $example2, $example3]

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-state/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-state/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-state>

L<Initiatives|https://github.com/iamalnewkirk/data-object-state/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-state/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-state/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-state/issues>

=cut
