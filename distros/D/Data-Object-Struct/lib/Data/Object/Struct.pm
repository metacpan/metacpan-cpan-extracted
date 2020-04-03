package Data::Object::Struct;

use 5.014;

use strict;
use warnings;
use routines;

use Data::Object::Class;

with 'Data::Object::Role::Buildable';
with 'Data::Object::Role::Immutable';
with 'Data::Object::Role::Proxyable';

our $VERSION = '2.00'; # VERSION

method build_self($args) {
  %$self = %$args;

  $self->immutable;

  return $self;
}

method build_proxy($package, $method) {
  return sub { $self->{$method} } if exists $self->{$method};

  return undef;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Struct

=cut

=head1 ABSTRACT

Struct Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Struct;

  my $person = Data::Object::Struct->new(
    fname => 'Aron',
    lname => 'Nienow',
    cname => 'Jacobs, Sawayn and Nienow'
  );

  # $person->fname # Aron
  # $person->lname # Nienow
  # $person->cname # Jacobs, Sawayn and Nienow

  # $person->mname
  # Error!

  # $person->mname = 'Clifton'
  # Error!

  # $person->{mname} = 'Clifton'
  # Error!

=cut

=head1 DESCRIPTION

This package provides a class that creates struct-like objects which bundle
attributes together, is immutable, and provides accessors, without having to
write an explicit class.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Buildable>

L<Data::Object::Role::Immutable>

L<Data::Object::Role::Proxyable>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-struct/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-struct/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-struct>

L<Initiatives|https://github.com/iamalnewkirk/data-object-struct/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-struct/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-struct/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-struct/issues>

=cut
