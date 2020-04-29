package Data::Object::String;

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
  $self = ref $self || $self;

  if (Scalar::Util::blessed($data)) {
    $data = $data->detract if $data->can('detract');
  }

  $data = $data ? "$data" : "";

  if (!defined($data) || ref($data)) {
    Carp::confess('Instantiation Error: Not a String');
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

Data::Object::String

=cut

=head1 ABSTRACT

String Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::String;

  my $string = Data::Object::String->new('abcedfghi');

=cut

=head1 DESCRIPTION

This package provides methods for manipulating string data.

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

=head2 append

  append() : Str

The append method appends arugments to the string using spaces.

=over 4

=item append example #1

  my $string = Data::Object::String->new('firstname');

  $string->append('lastname'); # firstname lastname

=back

=cut

=head2 camelcase

  camelcase() : Str

The camelcase method converts the string to camelcase.

=over 4

=item camelcase example #1

  my $string = Data::Object::String->new('hello world');

  $string->camelcase; # HelloWorld

=back

=cut

=head2 chomp

  chomp() : Str

The chomp method removes the newline (or the current value of $/) from the end
of the string.

=over 4

=item chomp example #1

  my $string = Data::Object::String->new("name, age, dob, email\n");

  $string->chomp; # name, age, dob, email

=back

=cut

=head2 chop

  chop() : Str

The chop method removes and returns the last character of the string.

=over 4

=item chop example #1

  my $string = Data::Object::String->new("this is just a test.");

  $string->chop; # this is just a test

=back

=cut

=head2 concat

  concat(Any $arg1) : Str

The concat method returns the string with the argument list appended to it.

=over 4

=item concat example #1

  my $string = Data::Object::String->new('ABC');

  $string->concat('DEF', 'GHI'); # ABCDEFGHI

=back

=cut

=head2 contains

  contains(Str | RegexpRef $arg1) : Num

The contains method searches the string for a substring or expression returns
true or false if found.

=over 4

=item contains example #1

  my $string = Data::Object::String->new('Nullam ultrices placerat.');

  $string->contains('trices'); # 1

=back

=over 4

=item contains example #2

  my $string = Data::Object::String->new('Nullam ultrices placerat.');

  $string->contains('itrices'); # 0

=back

=over 4

=item contains example #3

  my $string = Data::Object::String->new('Nullam ultrices placerat.');

  $string->contains(qr/trices/); # 1

=back

=over 4

=item contains example #4

  my $string = Data::Object::String->new('Nullam ultrices placerat.');

  $string->contains(qr/itrices/); # 0

=back

=cut

=head2 defined

  defined() : Num

The defined method returns true, always.

=over 4

=item defined example #1

  my $string = Data::Object::String->new();

  $string->defined; # 1

=back

=cut

=head2 eq

  eq(Any $arg1) : Num

The eq method returns true if the argument provided is equal to the string.

=over 4

=item eq example #1

  my $string = Data::Object::String->new('exciting');

  $string->eq('Exciting'); # 0

=back

=cut

=head2 ge

  ge(Any $arg1) : Num

The ge method returns true if the argument provided is greater-than or equal-to
the string.

=over 4

=item ge example #1

  my $string = Data::Object::String->new('exciting');

  $string->ge('Exciting'); # 1

=back

=cut

=head2 gt

  gt(Any $arg1) : Num

The gt method returns true if the argument provided is greater-than the string.

=over 4

=item gt example #1

  my $string = Data::Object::String->new('exciting');

  $string->gt('Exciting'); # 1

=back

=cut

=head2 hex

  hex() : Str

The hex method returns the value resulting from interpreting the string as a hex string.

=over 4

=item hex example #1

  my $string = Data::Object::String->new('0xaf');

  $string->hex; # 175

=back

=cut

=head2 index

  index(Str $arg1, Num $arg2) : Num

The index method searches for the argument within the string and returns the
position of the first occurrence of the argument.

=over 4

=item index example #1

  my $string = Data::Object::String->new('unexplainable');

  $string->index('explain'); # 2

=back

=over 4

=item index example #2

  my $string = Data::Object::String->new('unexplainable');

  $string->index('explain', 0); # 2

=back

=over 4

=item index example #3

  my $string = Data::Object::String->new('unexplainable');

  $string->index('explain', 1); # 2

=back

=over 4

=item index example #4

  my $string = Data::Object::String->new('unexplainable');

  $string->index('explain', 2); # 2

=back

=over 4

=item index example #5

  my $string = Data::Object::String->new('unexplainable');

  $string->index('explained'); # -1

=back

=cut

=head2 lc

  lc() : Str

The lc method returns a lowercased version of the string.

=over 4

=item lc example #1

  my $string = Data::Object::String->new('EXCITING');

  $string->lc; # exciting

=back

=cut

=head2 lcfirst

  lcfirst() : Str

The lcfirst method returns a the string with the first character lowercased.

=over 4

=item lcfirst example #1

  my $string = Data::Object::String->new('EXCITING');

  $string->lcfirst; # eXCITING

=back

=cut

=head2 le

  le(Any $arg1) : Num

The le method returns true if the argument provided is less-than or equal-to
the string.

=over 4

=item le example #1

  my $string = Data::Object::String->new('exciting');

  $string->le('Exciting'); # 0

=back

=cut

=head2 length

  length() : Num

The length method returns the number of characters within the string.

=over 4

=item length example #1

  my $string = Data::Object::String->new('longggggg');

  $string->length; # 9

=back

=cut

=head2 lines

  lines() : ArrayRef

The lines method returns an arrayref of parts by splitting on 1 or more newline
characters.

=over 4

=item lines example #1

  my $string = Data::Object::String->new(
    "who am i?\nwhere am i?\nhow did I get here"
  );

  $string->lines; # ['who am i?','where am i?','how did I get here']

=back

=cut

=head2 lowercase

  lowercase() : Str

The lowercase method is an alias to the lc method.

=over 4

=item lowercase example #1

  my $string = Data::Object::String->new('EXCITING');

  $string->lowercase; # exciting

=back

=cut

=head2 lt

  lt(Any $arg1) : Num

The lt method returns true if the argument provided is less-than the string.

=over 4

=item lt example #1

  my $string = Data::Object::String->new('exciting');

  $string->lt('Exciting'); # 0

=back

=cut

=head2 ne

  ne(Any $arg1) : Num

The ne method returns true if the argument provided is not equal to the string.

=over 4

=item ne example #1

  my $string = Data::Object::String->new('exciting');

  $string->ne('Exciting'); # 1

=back

=cut

=head2 render

  render(HashRef $arg1) : Str

The render method treats the string as a template and performs a simple token
replacement using the argument provided.

=over 4

=item render example #1

  my $string = Data::Object::String->new('Hi, {name}!');

  $string->render({name => 'Friend'}); # Hi, Friend!

=back

=cut

=head2 replace

  replace(Str $arg1, Str $arg2) : Str

The replace method performs a search and replace operation and returns the modified string.

=over 4

=item replace example #1

  my $string = Data::Object::String->new('Hello World');

  $string->replace('World', 'Universe'); # Hello Universe

=back

=over 4

=item replace example #2

  my $string = Data::Object::String->new('Hello World');

  $string->replace('world', 'Universe', 'i'); # Hello Universe

=back

=over 4

=item replace example #3

  my $string = Data::Object::String->new('Hello World');

  $string->replace(qr/world/i, 'Universe'); # Hello Universe

=back

=over 4

=item replace example #4

  my $string = Data::Object::String->new('Hello World');

  $string->replace(qr/.*/, 'Nada'); # Nada

=back

=cut

=head2 reverse

  reverse() : Str

The reverse method returns a string where the characters in the string are in
the opposite order.

=over 4

=item reverse example #1

  my $string = Data::Object::String->new('dlrow ,olleH');

  $string->reverse; # Hello, world

=back

=cut

=head2 rindex

  rindex(Str $arg1, Num $arg2) : Num

The rindex method searches for the argument within the string and returns the
position of the last occurrence of the argument.

=over 4

=item rindex example #1

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain'); # 14

=back

=over 4

=item rindex example #10

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explained'); # -1

=back

=over 4

=item rindex example #2

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 0); # 0

=back

=over 4

=item rindex example #3

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 21); # 14

=back

=over 4

=item rindex example #4

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 22); # 14

=back

=over 4

=item rindex example #5

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 23); # 14

=back

=over 4

=item rindex example #6

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 20); # 14

=back

=over 4

=item rindex example #7

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 14); # 0

=back

=over 4

=item rindex example #8

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 13); # 0

=back

=over 4

=item rindex example #9

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 0); # 0

=back

=cut

=head2 snakecase

  snakecase() : Str

The snakecase method converts the string to snakecase.

=over 4

=item snakecase example #1

  my $string = Data::Object::String->new('hello world');

  $string->snakecase; # hello_world

=back

=cut

=head2 split

  split(RegexpRef $arg1, Num $arg2) : ArrayRef

The split method returns an arrayref by splitting on the argument.

=over 4

=item split example #1

  my $string = Data::Object::String->new('name, age, dob, email');

  $string->split(', '); # ['name', 'age', 'dob', 'email']

=back

=over 4

=item split example #2

  my $string = Data::Object::String->new('name, age, dob, email');

  $string->split(', ', 2); # ['name', 'age, dob, email']

=back

=over 4

=item split example #3

  my $string = Data::Object::String->new('name, age, dob, email');

  $string->split(qr/\,\s*/); # ['name', 'age', 'dob', 'email']

=back

=over 4

=item split example #4

  my $string = Data::Object::String->new('name, age, dob, email');

  $string->split(qr/\,\s*/, 2); # ['name', 'age, dob, email']

=back

=cut

=head2 strip

  strip() : Str

The strip method returns the string replacing occurences of 2 or more
whitespaces with a single whitespace.

=over 4

=item strip example #1

  my $string = Data::Object::String->new('one,  two,  three');

  $string->strip; # one, two, three

=back

=cut

=head2 titlecase

  titlecase() : Str

The titlecase method returns the string capitalizing the first character of
each word.

=over 4

=item titlecase example #1

  my $string = Data::Object::String->new('mr. john doe');

  $string->titlecase; # Mr. John Doe

=back

=cut

=head2 trim

  trim() : Str

The trim method removes one or more consecutive leading and/or trailing spaces
from the string.

=over 4

=item trim example #1

  my $string = Data::Object::String->new('   system is   ready   ');

  $string->trim; # system is   ready

=back

=cut

=head2 uc

  uc() : Str

The uc method returns an uppercased version of the string.

=over 4

=item uc example #1

  my $string = Data::Object::String->new('exciting');

  $string->uc; # EXCITING

=back

=cut

=head2 ucfirst

  ucfirst() : Str

The ucfirst method returns a the string with the first character uppercased.

=over 4

=item ucfirst example #1

  my $string = Data::Object::String->new('exciting');

  $string->ucfirst; # Exciting

=back

=cut

=head2 uppercase

  uppercase() : Str

The uppercase method is an alias to the uc method.

=over 4

=item uppercase example #1

  my $string = Data::Object::String->new('exciting');

  $string->uppercase; # EXCITING

=back

=cut

=head2 words

  words() : ArrayRef

The words method returns an arrayref by splitting on 1 or more consecutive
spaces.

=over 4

=item words example #1

  my $string = Data::Object::String->new(
    'is this a bug we\'re experiencing'
  );

  $string->words; # ["is","this","a","bug","we're","experiencing"]

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
