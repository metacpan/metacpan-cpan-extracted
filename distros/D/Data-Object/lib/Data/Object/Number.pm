package Data::Object::Number;

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

method new($data = 0) {
  if (Scalar::Util::blessed($data)) {
    $data = $data->detract if $data->can('detract');
  }

  if (defined $data) {
    $data =~ s/^\+//; # not keen on this but ...
  }

  if (!defined($data) || ref($data)) {
    Carp::confess('Instantiation Error: Not a Number');
  }

  if (!Scalar::Util::looks_like_number($data)) {
    Carp::confess('Instantiation Error: Not an Number');
  }

  $data += 0 unless $data =~ /[a-zA-Z]/;

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

Data::Object::Number

=cut

=head1 ABSTRACT

Number Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Number;

  my $number = Data::Object::Number->new(1_000_000);

=cut

=head1 DESCRIPTION

This package provides methods for manipulating number data.

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

=head2 abs

  abs() : Any

The abs method returns the absolute value of the number.

=over 4

=item abs example #1

  my $number = Data::Object::Number->new(12);

  $number->abs; # 12

=back

=over 4

=item abs example #2

  my $number = Data::Object::Number->new(-12);

  $number->abs; # 12

=back

=cut

=head2 atan2

  atan2(Num $arg1) : Num

The atan2 method returns the arctangent of Y/X in the range -PI to PI.

=over 4

=item atan2 example #1

  my $number = Data::Object::Number->new(1);

  $number->atan2(1); # 0.785398163397448

=back

=cut

=head2 cos

  cos() : Num

The cos method computes the cosine of the number (expressed in radians).

=over 4

=item cos example #1

  my $number = Data::Object::Number->new(12);

  $number->cos; # 0.843853958732492

=back

=cut

=head2 decr

  decr(Num $arg1) : Num

The decr method returns the numeric number decremented by 1.

=over 4

=item decr example #1

  my $number = Data::Object::Number->new(123456789);

  $number->decr; # 123456788

=back

=cut

=head2 defined

  defined() : Num

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false.

=over 4

=item defined example #1

  my $number = Data::Object::Number->new;

  $number->defined; # 1

=back

=cut

=head2 downto

  downto(Num $arg1) : ArrayRef

The downto method returns an array reference containing integer decreasing
values down to and including the limit.

=over 4

=item downto example #1

  my $number = Data::Object::Number->new(10);

  $number->downto(5); # [10,9,8,7,6,5]

=back

=cut

=head2 eq

  eq(Any $arg1) : Num

The eq method performs a numeric equality operation.

=over 4

=item eq example #1

  my $number = Data::Object::Number->new(12345);

  $number->eq(12346); # 0

=back

=cut

=head2 exp

  exp() : Num

The exp method returns e (the natural logarithm base) to the power of the
number.

=over 4

=item exp example #1

  my $number = Data::Object::Number->new(0);

  $number->exp; # 1

=back

=over 4

=item exp example #2

  my $number = Data::Object::Number->new(1);

  $number->exp; # 2.71828182845905

=back

=over 4

=item exp example #3

  my $number = Data::Object::Number->new(1.5);

  $number->exp; # 4.48168907033806

=back

=cut

=head2 ge

  ge(Any $arg1) : Num

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object.

=over 4

=item ge example #1

  my $number = Data::Object::Number->new(0);

  $number->ge(0); # 1

=back

=cut

=head2 gt

  gt(Any $arg1) : Num

The gt method performs a numeric greater-than comparison.

=over 4

=item gt example #1

  my $number = Data::Object::Number->new(99);

  $number->gt(50); # 1

=back

=cut

=head2 hex

  hex() : Str

The hex method returns a hex string representing the value of the number.

=over 4

=item hex example #1

  my $number = Data::Object::Number->new(175);

  $number->hex; # 0xaf

=back

=cut

=head2 incr

  incr(Num $arg1) : Num

The incr method returns the numeric number incremented by 1.

=over 4

=item incr example #1

  my $number = Data::Object::Number->new(123456789);

  $number->incr; # 123456790

=back

=cut

=head2 int

  int() : Num

The int method returns the integer portion of the number. Do not use this
method for rounding.

=over 4

=item int example #1

  my $number = Data::Object::Number->new(12.5);

  $number->int; # 12

=back

=cut

=head2 le

  le(Any $arg1) : Num

The le method returns true if the argument provided is less-than or equal-to
the value represented by the object.

=over 4

=item le example #1

  my $number = Data::Object::Number->new(0);

  $number->le(-1); # 0

=back

=cut

=head2 log

  log() : Num

The log method returns the natural logarithm (base e) of the number.

=over 4

=item log example #1

  my $number = Data::Object::Number->new(12345);

  $number->log; # 9.42100640177928

=back

=cut

=head2 lt

  lt(Any $arg1) : Num

The lt method performs a numeric less-than comparison.

=over 4

=item lt example #1

  my $number = Data::Object::Number->new(86);

  $number->lt(88); # 1

=back

=cut

=head2 mod

  mod() : Num

The mod method returns the division remainder of the number divided by the
argment.

=over 4

=item mod example #1

  my $number = Data::Object::Number->new(12);

  $number->mod(1); # 0

=back

=over 4

=item mod example #2

  my $number = Data::Object::Number->new(12);

  $number->mod(2); # 0

=back

=over 4

=item mod example #3

  my $number = Data::Object::Number->new(12);

  $number->mod(3); # 0

=back

=over 4

=item mod example #4

  my $number = Data::Object::Number->new(12);

  $number->mod(4); # 0

=back

=over 4

=item mod example #5

  my $number = Data::Object::Number->new(12);

  $number->mod(5); # 2

=back

=cut

=head2 ne

  ne(Any $arg1) : Num

The ne method performs a numeric equality operation.

=over 4

=item ne example #1

  my $number = Data::Object::Number->new(-100);

  $number->ne(100); # 1

=back

=cut

=head2 neg

  neg() : Num

The neg method returns a negative version of the number.

=over 4

=item neg example #1

  my $number = Data::Object::Number->new(12345);

  $number->neg; # -12345

=back

=cut

=head2 pow

  pow() : Num

The pow method returns a number, the result of a math operation, which is the
number to the power of the argument.

=over 4

=item pow example #1

  my $number = Data::Object::Number->new(12345);

  $number->pow(3); # 1881365963625

=back

=cut

=head2 sin

  sin() : Num

The sin method returns the sine of the number (expressed in radians).

=over 4

=item sin example #1

  my $number = Data::Object::Number->new(12345);

  $number->sin; # -0.993771636455681

=back

=cut

=head2 sqrt

  sqrt(Num $arg1) : Num

The sqrt method returns the positive square root of the number.

=over 4

=item sqrt example #1

  my $number = Data::Object::Number->new(12345);

  $number->sqrt; # 111.108055513541

=back

=cut

=head2 to

  to(Num $arg1) : ArrayRef

The to method returns an array reference containing integer increasing or
decreasing values to and including the limit in ascending or descending order
based on the value of the floating-point object.

=over 4

=item to example #1

  my $number = Data::Object::Number->new(5);

  $number->to(9); # [5,6,7,8,9]

=back

=over 4

=item to example #2

  my $number = Data::Object::Number->new(5);

  $number->to(1); # [5,4,3,2,1]

=back

=cut

=head2 upto

  upto(Num $arg1) : Any

The upto method returns an array reference containing integer increasing values
up to and including the limit.

=over 4

=item upto example #1

  my $number = Data::Object::Number->new(23);

  $number->upto(25); # [23,24,25]

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
