package Data::Object::Types::Library;

use 5.014;

use strict;
use warnings;

use base 'Type::Library';

our $VERSION = '0.04'; # VERSION

1;

=encoding utf8

=head1 NAME

Data::Object::Types::Library

=cut

=head1 ABSTRACT

Data-Object Type Library Superclass

=cut

=head1 SYNOPSIS

  package Test::Library;

  use base 'Data::Object::Types::Library';

  package main;

  my $libary = Test::Library->meta;

=cut

=head1 DESCRIPTION

This package provides an abstract base class which turns the consumer into a
L<Type::Library> type library.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Type::Library>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-types/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-types/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-types>

L<Initiatives|https://github.com/iamalnewkirk/data-object-types/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-types/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-types/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-types/issues>

=cut
