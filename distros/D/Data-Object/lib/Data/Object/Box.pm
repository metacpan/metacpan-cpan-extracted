package Data::Object::Box;

use 5.014;

use strict;
use warnings;

use registry 'Data::Object::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Cast;

with 'Data::Object::Role::Buildable';
with 'Data::Object::Role::Proxyable';

our $VERSION = '2.05'; # VERSION

# ATTRIBUTES

has 'source' => (
  is => 'ro',
  isa => 'Any',
  def => sub {
    Data::Object::Cast::Deduce({})
  },
  tgr => sub {
    $_[1] = Data::Object::Cast::Deduce($_[1])
  },
  opt => 1,
);

# BUILD

method build_arg($data) {
  if (ref $data eq 'HASH' && keys %$data == 1 && exists $data->{source}) {

    return $data;
  }
  {
    source => $data
  }
}

method build_args($data) {
  if (ref $data eq 'HASH' && keys %$data == 1 && exists $data->{source}) {

    return $data;
  }
  {
    source => $data
  }
}

# PROXY

method build_proxy($package, $method, @args) {
  my $source = $self->source;

  unless ($source->can($method) || $source->can('AUTOLOAD')) {
    return undef;
  }
  return sub {
    my $result = Data::Object::Cast::Deduce($source->$method(@args));

    if (UNIVERSAL::isa($result, "Data::Object::Kind")) {
      return ref($self)->new(source => $result);
    }
    else {
      return $result;
    }
  }
}

# METHODS

method value() {
  my $source = $self->source;

  return Data::Object::Cast::Detract($source);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Box

=cut

=head1 ABSTRACT

Boxing for Perl 5 Data Objects

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Box;

  my $boxed = Data::Object::Box->new(
    source => [1..4]
  );

  # my $iterator = $boxed->iterator;

  # $iterator->next;

=cut

=head1 DESCRIPTION

This package provides a pure Perl boxing mechanism for wrapping chaining method
calls across data objects.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Buildable>

L<Data::Object::Role::Proxyable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 source

  source(Any)

This attribute is read-only, accepts C<(Any)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 value

  value() : Any

The value method returns the underlying wrapped value, i.e. the value in the
C<source> attribute.

=over 4

=item value example #1

  # given: synopsis

  $boxed->value;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object/wiki>

L<Project|https://github.com/iamalnewkirk/data-object>

L<Initiatives|https://github.com/iamalnewkirk/data-object/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object/issues>

=cut
