  package Data::Object;

use 5.014;

use strict;
use warnings;
use routines;

fun import($class, @args) {

  "Data::Object::Keyword"->import($class, @args);
}

package
  Data::Object::Keyword;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use parent 'Exporter';

our $VERSION = '2.05'; # VERSION

our @EXPORT = qw(
  Array
  Boolean
  Box
  Code
  False
  Float
  Hash
  Number
  Regexp
  Scalar
  String
  True
  Undef
);

our @EXPORT_OK = (@EXPORT, qw(
  Args
  Data
  Error
  Opts
  Name
  Space
  Struct
  Vars
));

our %EXPORT_TAGS = (
  all => \@EXPORT_OK
);

no warnings 'redefine';

# IMPORT

fun import($class, @args) {
  if (caller eq "Data::Object") {
    "Data::Object::Keyword"->export_to_level(2, @args);
  }
}

# FUNCTIONS

fun Args(Maybe[HashRef] $data) {
  $data //= {};

  require Data::Object::Args;

  return Data::Object::Args->new(named => $data);
}

fun Array(Maybe[ArrayRef] $data) {
  $data //= [];

  require Data::Object::Array;

  return Data::Object::Array->new($data);
}

fun Boolean(Maybe[Bool] $data) {
  $data //= 0;

  require Data::Object::Boolean;

  return Data::Object::Boolean->new($data)
}

fun Box(Any $data = undef) {

  require Data::Object::Box;

  return Data::Object::Box->new($data)
}

fun Code(Maybe[CodeRef] $data) {
  $data //= sub {};

  require Data::Object::Code;

  return Data::Object::Code->new($data);
}

fun Data(Maybe[Str] $data) {
  $data //= $0;

  require Data::Object::Data;

  return Data::Object::Data->new(file => $data);
}

fun Error(Maybe[Str | HashRef] $data) {
  $data = { message => $data } if !$data || !ref $data;

  require Data::Object::Exception;

  return Data::Object::Exception->new($data);
}

fun False() {

  require Data::Object::Boolean;

  return Data::Object::Boolean::False();
}

fun Float(Maybe[Num] $data) {
  $data //= '0.0';

  require Data::Object::Float;

  return Data::Object::Float->new($data);
}

fun Hash(Maybe[HashRef] $data) {
  $data //= {};

  require Data::Object::Hash;

  return Data::Object::Hash->new($data);
}

fun Name(Maybe[Str] $data) {
  $data //= '';

  require Data::Object::Name;

  return Data::Object::Name->new($data);
}

fun Number(Maybe[Num] $data) {
  $data //= 1;

  require Data::Object::Number;

  return Data::Object::Number->new($data);
}

fun Opts(Maybe[HashRef] $data) {
  $data //= {};

  require Data::Object::Opts;

  return Data::Object::Opts->new($data);
}

fun Regexp(Maybe[RegexpRef] $data) {
  $data //= qr/.*/;

  require Data::Object::Regexp;

  return Data::Object::Regexp->new($data);
}

fun Scalar(Maybe[Ref] $data) {
  $data //= do { my $ref = ''; \$ref };

  require Data::Object::Scalar;

  return Data::Object::Scalar->new($data);
}

fun Space(Maybe[Str] $data) {
  $data //= 'main';

  require Data::Object::Space;

  return Data::Object::Space->new($data);
}

fun String(Maybe[Str] $data) {
  $data //= '';

  require Data::Object::String;

  return Data::Object::String->new($data);
}

fun Struct(Maybe[HashRef] $data) {
  $data //= {};

  require Data::Object::Struct;

  return Data::Object::Struct->new($data);
}

fun True() {

  require Data::Object::Boolean;

  return Data::Object::Boolean::True();
}

fun Undef() {

  require Data::Object::Undef;

  return Data::Object::Undef->new;
}

fun Vars(Maybe[HashRef] $data) {
  $data //= {};

  require Data::Object::Vars;

  return Data::Object::Vars->new(named => $data);
}

1;

=encoding utf8

=head1 NAME

Data::Object

=cut

=head1 ABSTRACT

Object-Orientation for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object;

  my $array = Box Array [1..4];

  # my $iterator = $array->iterator;

  # $iterator->next; # 1

=cut

=head1 DESCRIPTION

This package automatically exports and provides constructor functions for
creating chainable data type objects from raw Perl data types.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Types>

=cut

=head1 FUNCTIONS

This package implements the following functions:

=cut

=head2 args

  Args(HashRef $data) : InstanceOf["Data::Object::Args"]

The Args function returns a L<Data::Object::Args> object.

=over 4

=item Args example #1

  package main;

  use Data::Object 'Args';

  my $args = Args; # [...]

=back

=over 4

=item Args example #2

  package main;

  my $args = Args {
    subcommand => 0
  };

  # $args->subcommand;

=back

=cut

=head2 array

  Array(ArrayRef $data) : InstanceOf["Data::Object::Array"]

The Array function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Array> object.

=over 4

=item Array example #1

  package main;

  my $array = Array; # []

=back

=over 4

=item Array example #2

  package main;

  my $array = Array [1..4];

=back

=cut

=head2 boolean

  Boolean(Bool $data) : BooleanObject

The Boolean function returns a L<Data::Object::Boolean> object representing a
true or false value.

=over 4

=item Boolean example #1

  package main;

  my $boolean = Boolean;

=back

=over 4

=item Boolean example #2

  package main;

  my $boolean = Boolean 0;

=back

=cut

=head2 box

  Box(Any $data) : InstanceOf["Data::Object::Box"]

The Box function returns a L<Data::Object::Box> object representing a data type
object which is automatically deduced.

=over 4

=item Box example #1

  package main;

  my $box = Box;

=back

=over 4

=item Box example #2

  package main;

  my $box = Box 123;

=back

=over 4

=item Box example #3

  package main;

  my $box = Box [1..4];

=back

=over 4

=item Box example #4

  package main;

  my $box = Box {1..4};

=back

=cut

=head2 code

  Code(CodeRef $data) : InstanceOf["Data::Object::Code"]

The Code function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Code> object.

=over 4

=item Code example #1

  package main;

  my $code = Code;

=back

=over 4

=item Code example #2

  package main;

  my $code = Code sub { shift };

=back

=cut

=head2 data

  Data(Str $file) : InstanceOf["Data::Object::Data"]

The Data function returns a L<Data::Object::Data> object.

=over 4

=item Data example #1

  package main;

  use Data::Object 'Data';

  my $data = Data;

=back

=over 4

=item Data example #2

  package main;

  my $data = Data 't/Data_Object.t';

  # $data->contents(...);

=back

=cut

=head2 error

  Error(Str | HashRef) : InstanceOf["Data::Object::Exception"]

The Error function returns a L<Data::Object::Exception> object.

=over 4

=item Error example #1

  package main;

  use Data::Object 'Error';

  my $error = Error;

  # die $error;

=back

=over 4

=item Error example #2

  package main;

  my $error = Error 'Oops!';

  # die $error;

=back

=over 4

=item Error example #3

  package main;

  my $error = Error {
    message => 'Oops!',
    context => { time => time }
  };

  # die $error;

=back

=cut

=head2 false

  False() : BooleanObject

The False function returns a L<Data::Object::Boolean> object representing a
false value.

=over 4

=item False example #1

  package main;

  my $false = False;

=back

=cut

=head2 float

  Float(Num $data) : InstanceOf["Data::Object::Float"]

The Float function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Float> object.

=over 4

=item Float example #1

  package main;

  my $float = Float;

=back

=over 4

=item Float example #2

  package main;

  my $float = Float '0.0';

=back

=cut

=head2 hash

  Hash(HashRef $data) : InstanceOf["Data::Object::Hash"]

The Hash function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Hash> object.

=over 4

=item Hash example #1

  package main;

  my $hash = Hash;

=back

=over 4

=item Hash example #2

  package main;

  my $hash = Hash {1..4};

=back

=cut

=head2 name

  Name(Str $data) : InstanceOf["Data::Object::Name"]

The Name function returns a L<Name::Object::Name> object.

=over 4

=item Name example #1

  package main;

  use Data::Object 'Name';

  my $name = Name 'Example Title';

  # $name->package;

=back

=cut

=head2 number

  Number(Num $data) : InstanceOf["Data::Object::Number"]

The Number function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Number> object.

=over 4

=item Number example #1

  package main;

  my $number = Number;

=back

=over 4

=item Number example #2

  package main;

  my $number = Number 123;

=back

=cut

=head2 opts

  Opts(HashRef $data) : InstanceOf["Data::Object::Opts"]

The Opts function returns a L<Data::Object::Opts> object.

=over 4

=item Opts example #1

  package main;

  use Data::Object 'Opts';

  my $opts = Opts;

=back

=over 4

=item Opts example #2

  package main;

  my $opts = Opts {
    spec => ['files|f=s']
  };

  # $opts->files; [...]

=back

=cut

=head2 regexp

  Regexp(RegexpRef $data) : InstanceOf["Data::Object::Regexp"]

The Regexp function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Regexp> object.

=over 4

=item Regexp example #1

  package main;

  my $regexp = Regexp;

=back

=over 4

=item Regexp example #2

  package main;

  my $regexp = Regexp qr/.*/;

=back

=cut

=head2 scalar

  Scalar(Ref $data) : InstanceOf["Data::Object::Scalar"]

The Scalar function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Scalar> object.

=over 4

=item Scalar example #1

  package main;

  my $scalar = Scalar;

=back

=over 4

=item Scalar example #2

  package main;

  my $scalar = Scalar \*main;

=back

=cut

=head2 space

  Space(Str $data) : InstanceOf["Data::Object::Space"]

The Space function returns a L<Data::Object::Space> object.

=over 4

=item Space example #1

  package main;

  use Data::Object 'Space';

  my $space = Space 'Example Namespace';

=back

=cut

=head2 string

  String(Str $data) : InstanceOf["Data::Object::String"]

The String function returns a L<Data::Object::Box> which wraps a
L<Data::Object::String> object.

=over 4

=item String example #1

  package main;

  my $string = String;

=back

=over 4

=item String example #2

  package main;

  my $string = String 'abc';

=back

=cut

=head2 struct

  Struct(HashRef $data) : InstanceOf["Data::Object::Struct"]

The Struct function returns a L<Data::Object::Struct> object.

=over 4

=item Struct example #1

  package main;

  use Data::Object 'Struct';

  my $struct = Struct;

=back

=over 4

=item Struct example #2

  package main;

  my $struct = Struct {
    name => 'example',
    time => time
  };

=back

=cut

=head2 true

  True() : BooleanObject

The True function returns a L<Data::Object::Boolean> object representing a true
value.

=over 4

=item True example #1

  package main;

  my $true = True;

=back

=cut

=head2 undef

  Undef() : InstanceOf["Data::Object::Undef"]

The Undef function returns a L<Data::Object::Undef> object representing the
I<undefined> value.

=over 4

=item Undef example #1

  package main;

  my $undef = Undef;

=back

=cut

=head2 vars

  Vars() : InstanceOf["Data::Object::Vars"]

The Vars function returns a L<Data::Object::Vars> object representing the
available environment variables.

=over 4

=item Vars example #1

  package main;

  use Data::Object 'Vars';

  my $vars = Vars;

=back

=over 4

=item Vars example #2

  package main;

  my $vars = Vars {
    user => 'USER'
  };

  # $vars->user; # $USER

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
