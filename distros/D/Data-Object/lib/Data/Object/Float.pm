package Data::Object::Float;

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

method new($data = '0.0') {
  if (Scalar::Util::blessed($data)) {
    $data = $data->detract if $data->can('detract');
  }

  if (defined($data)) {
    $data =~ s/^\+//;
  }

  if (!defined($data) || ref($data)) {
    Carp::confess('Instantiation Error: Not a Float');
  }

  if (!Scalar::Util::looks_like_number($data)) {
    Carp::confess('Instantiation Error: Not a Float');
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

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Float

=cut

=head1 ABSTRACT

Float Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Float;

  my $float = Data::Object::Float->new(9.9999);

=cut

=head1 DESCRIPTION

This package provides methods for manipulating float data.

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

  my $float = Data::Object::Float->new;

  $float->defined; # 1

=back

=cut

=head2 downto

  downto(Int $arg1) : ArrayRef

The downto method returns an array reference containing integer decreasing
values down to and including the limit.

=over 4

=item downto example #1

  my $float = Data::Object::Float->new(1.23);

  $float->downto(0); # [1,0]

=back

=cut

=head2 eq

  eq(Any $arg1) : Num

The eq method performs a numeric equality operation.

=over 4

=item eq example #1

  my $float = Data::Object::Float->new(1.23);

  $float->eq(1); # 0

=back

=cut

=head2 ge

  ge(Any $arg1) : Num

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object.

=over 4

=item ge example #1

  my $float = Data::Object::Float->new(1.23);

  $float->ge(1); # 1

=back

=cut

=head2 gt

  gt(Any $arg1) : Num

The gt method performs a numeric greater-than comparison.

=over 4

=item gt example #1

  my $float = Data::Object::Float->new(1.23);

  $float->gt(1); # 1

=back

=cut

=head2 le

  le(Any $arg1) : Num

The le method returns true if the argument provided is less-than or equal-to
the value represented by the object.

=over 4

=item le example #1

  my $float = Data::Object::Float->new(1.23);

  $float->le(1); # 0

=back

=cut

=head2 lt

  lt(Any $arg1) : Num

The lt method performs a numeric less-than comparison.

=over 4

=item lt example #1

  my $float = Data::Object::Float->new(1.23);

  $float->lt(1.24); # 1

=back

=cut

=head2 ne

  ne(Any $arg1) : Num

The ne method performs a numeric equality operation.

=over 4

=item ne example #1

  my $float = Data::Object::Float->new(1.23);

  $float->ne(1); # 1

=back

=cut

=head2 to

  to(Int $arg1) : ArrayRef

The to method returns an array reference containing integer increasing or
decreasing values to and including the limit in ascending or descending order
based on the value of the floating-point object.

=over 4

=item to example #1

  my $float = Data::Object::Float->new(1.23);

  $float->to(2); # [1,2]

=back

=over 4

=item to example #2

  my $float = Data::Object::Float->new(1.23);

  $float->to(0); # [1,0]

=back

=cut

=head2 upto

  upto(Int $arg1) : Any

The upto method returns an array reference containing integer increasing values
up to and including the limit.

=over 4

=item upto example #1

  my $float = Data::Object::Float->new(1.23);

  $float->upto(2); # [1,2]

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
