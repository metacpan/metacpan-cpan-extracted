package Data::Object::Scalar;

use 5.014;

use strict;
use warnings;
use routines;

use Carp ();
use Scalar::Util ();

use Role::Tiny::With;

use parent 'Data::Object::Kind';

with 'Data::Object::Role::Dumpable';
with 'Data::Object::Role::Proxyable';
with 'Data::Object::Role::Throwable';

use overload (
  '""'     => 'detract',
  '~~'     => 'detract',
  fallback => 1
);

our $VERSION = '2.05'; # VERSION

# BUILD

method new($data = '') {
  if (Scalar::Util::blessed($data)) {
    $data = $data->detract if $data->can('detract');
  }

  if (Scalar::Util::blessed($data) && $data->isa('Regexp') && $^V <= v5.12.0) {
    $data = do { \(my $q = qr/$data/) };
  }

  return bless ref($data) ? $data : \$data, $self;
}

# PROXY

method build_proxy($package, $method, @args) {
  my $plugin = $self->plugin($method) or return undef;

  return sub {
    use Try::Tiny;

    my $is_func = $plugin->package->can('mapping');

    try {
      my $instance = $plugin->build($is_func ? ($self, @args) : [$self, @args]);

      return $instance->execute;
    }
    catch {
      my $error = $_;
      my $class = $self->class;
      my $arity = $is_func ? 'mapping' : 'argslist';
      my $message = ref($error) ? $error->{message} : "$error";
      my $signature = "${class}::${method}(@{[join(', ', $plugin->package->$arity)]})";

      Carp::confess("$signature: $error");
    };
  };
}

# PLUGIN

method plugin($name, @args) {
  my $plugin;

  my $space = $self->space;

  return undef if !$name;

  if ($plugin = eval { $space->child('plugin')->child($name)->load }) {

    return undef unless $plugin->can('argslist');

    return $space->child('plugin')->child($name);
  }

  if ($plugin = $space->child('func')->child($name)->load) {

    return undef unless $plugin->can('mapping');

    return $space->child('func')->child($name);
  }

  return undef;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Scalar

=cut

=head1 ABSTRACT

Scalar Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Scalar;

  my $scalar = Data::Object::Scalar->new(\*main);

=cut

=head1 DESCRIPTION

This package provides methods for manipulating scalar data.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Kind>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 defined

  defined() : Num

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false.

=over 4

=item defined example #1

  my $scalar = Data::Object::Scalar->new;

  $scalar->defined; # 1

=back

=cut

=head2 eq

  eq(Any $arg1) : Any

The eq method will throw an exception if called.

=over 4

=item eq example #1

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->eq(\*test);

=back

=cut

=head2 ge

  ge(Any $arg1) : Any

The ge method will throw an exception if called.

=over 4

=item ge example #1

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->ge(\*test);

=back

=cut

=head2 gt

  gt(Any $arg1) : Any

The gt method will throw an exception if called.

=over 4

=item gt example #1

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->gt(\*test);

=back

=cut

=head2 le

  le(Any $arg1) : Any

The le method will throw an exception if called.

=over 4

=item le example #1

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->le(\*test);

=back

=cut

=head2 lt

  lt(Any $arg1) : Any

The lt method will throw an exception if called.

=over 4

=item lt example #1

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->lt(\*test);

=back

=cut

=head2 ne

  ne(Any $arg1) : Any

The ne method will throw an exception if called.

=over 4

=item ne example #1

  my $scalar = Data::Object::Scalar->new(\*main);

  $scalar->ne(\*test);

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
