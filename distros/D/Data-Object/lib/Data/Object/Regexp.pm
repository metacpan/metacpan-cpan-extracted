package Data::Object::Regexp;

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

method new($data = qr/.*/) {
  if (Scalar::Util::blessed($data)) {
    $data = $data->detract if $data->can('detract');
  }

  if (!defined($data) || !re::is_regexp($data)) {
    Carp::confess('Instantiation Error: Not a RegexpRef');
  }

  return bless \$data, $self;
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

Data::Object::Regexp

=cut

=head1 ABSTRACT

Regexp Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Regexp;

  my $re = Data::Object::Regexp->new(qr(\w+));

=cut

=head1 DESCRIPTION

This package provides methods for manipulating regexp data.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Kind>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Dumpable>

L<Data::Object::Role::Proxyable>

L<Data::Object::Role::Throwable>

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

  my $re = Data::Object::Regexp->new;

  $re->defined; # 1

=back

=cut

=head2 eq

  eq(Any $arg1) : Any

The eq method will throw an exception if called.

=over 4

=item eq example #1

  my $re = Data::Object::Regexp->new(qr//);

  $re->eq(qr//);

=back

=cut

=head2 ge

  ge(Any $arg1) : Any

The ge method will throw an exception if called.

=over 4

=item ge example #1

  my $re = Data::Object::Regexp->new(qr//);

  $re->ge(qr//);

=back

=cut

=head2 gt

  gt(Any $arg1) : Any

The gt method will throw an exception if called.

=over 4

=item gt example #1

  my $re = Data::Object::Regexp->new(qr//);

  $re->gt(qr//);

=back

=cut

=head2 le

  le(Any $arg1) : Any

The le method will throw an exception if called.

=over 4

=item le example #1

  my $re = Data::Object::Regexp->new(qr//);

  $re->le(qr//);

=back

=cut

=head2 lt

  lt(Any $arg1) : Any

The lt method will throw an exception if called.

=over 4

=item lt example #1

  my $re = Data::Object::Regexp->new(qr//);

  $re->lt(qr//);

=back

=cut

=head2 ne

  ne(Any $arg1) : Any

The ne method will throw an exception if called.

=over 4

=item ne example #1

  my $re = Data::Object::Regexp->new(qr//);

  $re->ne(qr//);

=back

=cut

=head2 replace

  replace(Str $arg1, Str $arg2) : ReplaceObject

The replace method performs a regular expression substitution on the given
string. The first argument is the string to match against. The second argument
is the replacement string. The optional third argument might be a string
representing flags to append to the s///x operator, such as 'g' or 'e'.  This
method will always return a L<Data::Object::Replace> object which can be used
to introspect the result of the operation.

=over 4

=item replace example #1

  my $re = Data::Object::Regexp->new(qr/test/);

  $re->replace('this is a test', 'drill');

=back

=over 4

=item replace example #2

  my $re = Data::Object::Regexp->new(qr/test/);

  $re->replace('test 1 test 2 test 3', 'drill', 'gi');

=back

=cut

=head2 search

  search(Str $arg1) : SearchObject

The search method performs a regular expression match against the given string,
this method will always return a L<Data::Object::Search> object which can be
used to introspect the result of the operation.

=over 4

=item search example #1

  my $re = Data::Object::Regexp->new(qr/test/);

  $re->search('this is a test');

=back

=over 4

=item search example #2

  my $re = Data::Object::Regexp->new(qr/test/);

  $re->search('this does not match', 'gi');

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
