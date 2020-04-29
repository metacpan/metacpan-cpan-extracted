package Data::Object::Boolean;

use 5.014;

use strict;
use warnings;
use routines;

use Scalar::Util ();

use parent 'Data::Object::Kind';

our $VERSION = '2.05'; # VERSION

state $TrueVal = 1;
state $TrueRef = \$TrueVal;
state $TrueType = 'True';
state $True = bless $TrueRef;

state $FalseVal = 0;
state $FalseRef = \$FalseVal;
state $FalseType = 'False';
state $False = bless $FalseRef;

use overload (
  '""'     => sub{${$_[0]}},
  '!'      => sub{${$_[0]}?$False:$True},
  fallback => 1
);

# METHODS

method new($arg) {

  return IsTrue($arg);
}

# FUNCTIONS

fun False() {

  return $False;
}

fun IsFalse($arg) {

  return Type($arg) eq $FalseType ? $True : $False;
}

fun IsTrue($arg) {

  return Type($arg) eq $TrueType ? $True : $False;
}

fun TO_JSON($arg) {
  no strict 'refs';

  return ${$arg} ? $TrueRef : $FalseRef;
}

fun True() {

  return $True;
}

fun Type($arg) {
  if (not defined $arg) {
    return $FalseType;
  }

  if (not ref $arg) {
    return !!$arg ? $TrueType : $FalseType;
  }

  if (Scalar::Util::reftype($arg) eq 'SCALAR') {
    return ${$arg} ? $TrueType : $FalseType;
  }

  if (Scalar::Util::blessed($arg)) {
    return $TrueType;
  }

  return !!$arg ? $TrueType : $FalseType;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Boolean

=cut

=head1 ABSTRACT

Boolean Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Boolean;

  my $bool = Data::Object::Boolean->new; # false

=cut

=head1 DESCRIPTION

This package provides functions and representation for boolean values.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Kind>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Types>

=cut

=head1 FUNCTIONS

This package implements the following functions:

=cut

=head2 false

  False() : Object

The False method returns a boolean object representing false.

=over 4

=item False example #1

  Data::Object::Boolean::False(); # false

=back

=cut

=head2 isfalse

  IsFalse(Maybe[Any] $arg) : Object

The IsFalse method returns a boolean object representing false if no arugments
are passed, otherwise this function will return a boolean object based on the
argument provided.

=over 4

=item IsFalse example #1

  Data::Object::Boolean::IsFalse(); # true

=back

=over 4

=item IsFalse example #2

  Data::Object::Boolean::IsFalse(0); # true

=back

=over 4

=item IsFalse example #3

  Data::Object::Boolean::IsFalse(1); # false

=back

=cut

=head2 istrue

  IsTrue() : Object

The IsTrue method returns a boolean object representing truth if no arugments
are passed, otherwise this function will return a boolean object based on the
argument provided.

=over 4

=item IsTrue example #1

  Data::Object::Boolean::IsTrue(); # false

=back

=over 4

=item IsTrue example #2

  Data::Object::Boolean::IsTrue(1); # true

=back

=over 4

=item IsTrue example #3

  Data::Object::Boolean::IsTrue(0); # false

=back

=cut

=head2 to_json

  TO_JSON(Any $arg) : Ref['SCALAR']

The TO_JSON method returns a scalar ref representing truthiness or falsiness
based on the arguments passed, this function is commonly used by JSON encoders
and instructs them on how they should represent the value.

=over 4

=item TO_JSON example #1

  my $bool = Data::Object::Boolean->new(1);

  $bool->TO_JSON; # \1

=back

=over 4

=item TO_JSON example #2

  Data::Object::Boolean::TO_JSON(
    Data::Object::Boolean::True()
  );

  # \1

=back

=over 4

=item TO_JSON example #3

  my $bool = Data::Object::Boolean->new(0);

  $bool->TO_JSON(0); # \0

=back

=over 4

=item TO_JSON example #4

  Data::Object::Boolean::TO_JSON(
    Data::Object::Boolean::False()
  );

  # \0

=back

=cut

=head2 true

  True() : Object

The True method returns a boolean object representing truth.

=over 4

=item True example #1

  Data::Object::Boolean::True(); # true

=back

=cut

=head2 type

  Type() : Str

The Type method returns either "True" or "False" based on the truthiness or
falsiness of the argument provided.

=over 4

=item Type example #1

  Data::Object::Boolean::Type(); # False

=back

=over 4

=item Type example #2

  Data::Object::Boolean::Type(1); # True

=back

=over 4

=item Type example #3

  Data::Object::Boolean::Type(0); # False

=back

=over 4

=item Type example #4

  Data::Object::Boolean::Type(
    Data::Object::Boolean::True()
  );

  # True

=back

=over 4

=item Type example #5

  Data::Object::Boolean::Type(
    Data::Object::Boolean::False()
  );

  # False

=back

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 new

  new(Maybe[Any] $arg) : Object

The new method returns a boolean object based on the value of the argument
provided.

=over 4

=item new example #1

  my $bool = Data::Object::Boolean->new(1); # true

=back

=over 4

=item new example #2

  my $bool = Data::Object::Boolean->new(0); # false

=back

=over 4

=item new example #3

  my $bool = Data::Object::Boolean->new(''); # false

=back

=over 4

=item new example #4

  my $bool = Data::Object::Boolean->new(undef); # false

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
