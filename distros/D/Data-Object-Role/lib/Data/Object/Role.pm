package Data::Object::Role;

use 5.014;

use strict;
use warnings;

use parent 'Moo::Role';

our $VERSION = '2.01'; # VERSION

1;

=encoding utf8

=head1 NAME

Data::Object::Role

=cut

=head1 ABSTRACT

Role Builder for Perl 5

=cut

=head1 SYNOPSIS

  package Identity;

  use Data::Object::Role;

  package Example;

  use Moo;

  with 'Identity';

  package main;

  my $example = Example->new;

=cut

=head1 DESCRIPTION

This package modifies the consuming package making it a role.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Moo>

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 has

  package HasIdentity;

  use Data::Object::Role;

  has id => (
    is => 'ro'
  );

  package HasExample;

  use Moo;

  with 'HasIdentity';

  package main;

  my $example = HasExample->new;

This package supports the C<has> keyword, which is used to declare role
attributes, which can be accessed and assigned to using the built-in
getter/setter or by the object constructor. See L<Moo> for more information.

=cut

=head2 requires

  package EntityRequires;

  use Data::Object::Role;

  requires 'execute';

  package RequiresExample;

  use Moo;

  with 'EntityRequires';

  sub execute {

    # does something ...
  }

  package main;

  my $example = RequiresExample->new;

This package supports the C<requires> keyword, which is used to declare methods
which must exist in the consuming package. See L<Moo> for more information.

=cut

=head2 with

  package WithEntity;

  use Data::Object::Role;

  package WithIdentity;

  use Data::Object::Role;

  with 'WithEntity';

  package WithExample;

  use Moo;

  with 'WithIdentity';

  package main;

  my $example = WithExample->new;

This package supports the C<with> keyword, which is used to declare roles to be
used and compose into your role. See L<Moo> for more information.

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-role/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-role/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-role>

L<Initiatives|https://github.com/iamalnewkirk/data-object-role/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-role/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-role/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-role/issues>

=cut
