package Data::Object::Name;

use 5.014;

use strict;
use warnings;
use routines;

our $VERSION = '2.03'; # VERSION

# BUILD

my $sep = qr/'|__|::|\\|\//;

# METHODS

method dist() {

  return $self->label =~ s/_/-/gr;
}

method file() {
  return $$self if $self->lookslike_a_file;

  my $string = $self->package;

  return join '__', map {
    join '_', map {lc} map {split /_/} grep {length}
    split /([A-Z]{1}[^A-Z]*)/
  } split /$sep/, $string;
}

method format($method, $format) {
  my $string = $self->$method;

  return sprintf($format || '%s', $string);
}

method label() {
  return $$self if $self->lookslike_a_label;

  return join '_', split /$sep/, $self->package;
}

method lookslike_a_file() {
  my $string = $$self;

  return $string =~ /^[a-z](?:\w*[a-z])?$/;
}

method lookslike_a_label() {
  my $string = $$self;

  return $string =~ /^[A-Z](?:\w*[a-zA-Z0-9])?$/;
}

method lookslike_a_package() {
  my $string = $$self;

  return $string =~ /^[A-Z](?:(?:\w|::)*[a-zA-Z0-9])?$/;
}

method lookslike_a_path() {
  my $string = $$self;

  return $string =~ /^[A-Z](?:(?:\w|\\|\/|[\:\.]{1}[a-zA-Z0-9])*[a-zA-Z0-9])?$/;
}

method lookslike_a_pragma() {
  my $string = $$self;

  return $string =~ /^\[\w+\]$/;
}

method new($class: $name = '') {

  return bless \$name, $class;
}

method package() {
  return $$self if $self->lookslike_a_package;

  return substr($$self, 1, -1) if $self->lookslike_a_pragma;

  my $string = $$self;

  if ($string !~ $sep) {
    return join '', map {ucfirst} split /[^a-zA-Z0-9]/, $string;
  } else {
    return join '::', map {
      join '', map {ucfirst} split /[^a-zA-Z0-9]/
    } split /$sep/, $string;
  }
}

method path() {
  return $$self if $self->lookslike_a_path;

  return join '/', split /$sep/, $self->package;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Name

=cut

=head1 ABSTRACT

Name Class for Perl 5

=cut

=head1 SYNOPSIS

  use Data::Object::Name;

  my $name = Data::Object::Name->new('FooBar/Baz');

=cut

=head1 DESCRIPTION

This package provides methods for converting "name" strings.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 dist

  dist() : Str

The dist method returns a package distribution representation of the name.

=over 4

=item dist example #1

  # given: synopsis

  my $dist = $name->dist; # FooBar-Baz

=back

=cut

=head2 file

  file() : Str

The file method returns a file representation of the name.

=over 4

=item file example #1

  # given: synopsis

  my $file = $name->file; # foo_bar__baz

=back

=cut

=head2 format

  format(Str $method, Str $format) : Str

The format method calls the specified method passing the result to the core
L</sprintf> function with itself as an argument.

=over 4

=item format example #1

  # given: synopsis

  my $file = $name->format('file', '%s.t'); # foo_bar__baz.t

=back

=cut

=head2 label

  label() : Str

The label method returns a label (or constant) representation of the name.

=over 4

=item label example #1

  # given: synopsis

  my $label = $name->label; # FooBar_Baz

=back

=cut

=head2 lookslike_a_file

  lookslike_a_file() : Bool

The lookslike_a_file method returns truthy if its state resembles a filename.

=over 4

=item lookslike_a_file example #1

  # given: synopsis

  my $is_file = $name->lookslike_a_file; # falsy

=back

=cut

=head2 lookslike_a_label

  lookslike_a_label() : Bool

The lookslike_a_label method returns truthy if its state resembles a label (or
constant).

=over 4

=item lookslike_a_label example #1

  # given: synopsis

  my $is_label = $name->lookslike_a_label; # falsy

=back

=cut

=head2 lookslike_a_package

  lookslike_a_package() : Bool

The lookslike_a_package method returns truthy if its state resembles a package
name.

=over 4

=item lookslike_a_package example #1

  # given: synopsis

  my $is_package = $name->lookslike_a_package; # falsy

=back

=cut

=head2 lookslike_a_path

  lookslike_a_path() : Bool

The lookslike_a_path method returns truthy if its state resembles a file path.

=over 4

=item lookslike_a_path example #1

  # given: synopsis

  my $is_path = $name->lookslike_a_path; # truthy

=back

=cut

=head2 lookslike_a_pragma

  lookslike_a_pragma() : Bool

The lookslike_a_pragma method returns truthy if its state resembles a pragma.

=over 4

=item lookslike_a_pragma example #1

  # given: synopsis

  my $is_pragma = $name->lookslike_a_pragma; # falsy

=back

=over 4

=item lookslike_a_pragma example #2

  use Data::Object::Name;

  my $name = Data::Object::Name->new('[strict]');

  my $is_pragma = $name->lookslike_a_pragma; # truthy

=back

=cut

=head2 new

  new(Str $arg) : Object

The new method instantiates the class and returns an object.

=over 4

=item new example #1

  use Data::Object::Name;

  my $name = Data::Object::Name->new;

=back

=over 4

=item new example #2

  use Data::Object::Name;

  my $name = Data::Object::Name->new('FooBar');

=back

=cut

=head2 package

  package() : Str

The package method returns a package name representation of the name given.

=over 4

=item package example #1

  # given: synopsis

  my $package = $name->package; # FooBar::Baz

=back

=cut

=head2 path

  path() : Str

The path method returns a path representation of the name.

=over 4

=item path example #1

  # given: synopsis

  my $path = $name->path; # FooBar/Baz

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/data-object-name/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/data-object-name/wiki>

L<Project|https://github.com/iamalnewkirk/data-object-name>

L<Initiatives|https://github.com/iamalnewkirk/data-object-name/projects>

L<Milestones|https://github.com/iamalnewkirk/data-object-name/milestones>

L<Contributing|https://github.com/iamalnewkirk/data-object-name/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/data-object-name/issues>

=cut
