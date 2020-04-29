package Data::Object::Code;

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
  '&{}'    => 'self',
  fallback => 1
);

our $VERSION = '2.05'; # VERSION

# BUILD

method new($data = sub{}) {
  if (Scalar::Util::blessed($data)) {
    $data = $data->detract if $data->can('detract');
  }

  unless (ref($data) eq 'CODE') {
    Carp::confess('Instantiation Error: Not a CodeRef');
  }

  return bless $data, $self;
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

# METHODS

method self() {

  return $self;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Code

=cut

=head1 ABSTRACT

Code Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Code;

  my $code = Data::Object::Code->new(sub { $_[0] + 1 });

=cut

=head1 DESCRIPTION

This package provides methods for manipulating code data.

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

=head2 call

  call(Any $arg1) : Any

The call method executes and returns the result of the code.

=over 4

=item call example #1

  my $code = Data::Object::Code->new(sub { ($_[0] // 0) + 1 });

  $code->call; # 1

=back

=over 4

=item call example #2

  my $code = Data::Object::Code->new(sub { ($_[0] // 0) + 1 });

  $code->call(0); # 1

=back

=over 4

=item call example #3

  my $code = Data::Object::Code->new(sub { ($_[0] // 0) + 1 });

  $code->call(1); # 2

=back

=over 4

=item call example #4

  my $code = Data::Object::Code->new(sub { ($_[0] // 0) + 1 });

  $code->call(2); # 3

=back

=cut

=head2 compose

  compose(CodeRef $arg1, Any $arg2) : CodeLike

The compose method creates a code reference which executes the first argument
(another code reference) using the result from executing the code as it's
argument, and returns a code reference which executes the created code
reference passing it the remaining arguments when executed.

=over 4

=item compose example #1

  my $code = Data::Object::Code->new(sub { [@_] });

  $code->compose($code, 1,2,3);

  # $code->(4,5,6); # [[1,2,3,4,5,6]]

=back

=cut

=head2 conjoin

  conjoin(CodeRef $arg1) : CodeLike

The conjoin method creates a code reference which execute the code and the
argument in a logical AND operation having the code as the lvalue and the
argument as the rvalue.

=over 4

=item conjoin example #1

  my $code = Data::Object::Code->new(sub { $_[0] % 2 });

  $code = $code->conjoin(sub { 1 });

  # $code->(0); # 0
  # $code->(1); # 1
  # $code->(2); # 0
  # $code->(3); # 1
  # $code->(4); # 0

=back

=cut

=head2 curry

  curry(CodeRef $arg1) : CodeLike

The curry method returns a code reference which executes the code passing it
the arguments and any additional parameters when executed.

=over 4

=item curry example #1

  my $code = Data::Object::Code->new(sub { [@_] });

  $code = $code->curry(1,2,3);

  # $code->(4,5,6); # [1,2,3,4,5,6]

=back

=cut

=head2 defined

  defined() : Num

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false.

=over 4

=item defined example #1

  my $code = Data::Object::Code->new;

  $code->defined; # 1

=back

=cut

=head2 disjoin

  disjoin(CodeRef $arg1) : CodeRef

The disjoin method creates a code reference which execute the code and the
argument in a logical OR operation having the code as the lvalue and the
argument as the rvalue.

=over 4

=item disjoin example #1

  my $code = Data::Object::Code->new(sub { $_[0] % 2 });

  $code = $code->disjoin(sub { -1 });

  # $code->(0); # -1
  # $code->(1); #  1
  # $code->(2); # -1
  # $code->(3); #  1
  # $code->(4); # -1

=back

=cut

=head2 next

  next(Any $arg1) : Any

The next method is an alias to the call method. The naming is especially useful
(i.e. helps with readability) when used with closure-based iterators.

=over 4

=item next example #1

  my $code = Data::Object::Code->new(sub { $_[0] * 2 });

  $code->next(72); # 144

=back

=cut

=head2 rcurry

  rcurry(Any $arg1) : CodeLike

The rcurry method returns a code reference which executes the code passing it
the any additional parameters and any arguments when executed.

=over 4

=item rcurry example #1

  my $code = Data::Object::Code->new(sub { [@_] });

  $code = $code->rcurry(1,2,3);

  # $code->(4,5,6); # [4,5,6,1,2,3]

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
