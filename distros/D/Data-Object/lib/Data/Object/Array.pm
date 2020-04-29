package Data::Object::Array;

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
  '@{}'    => 'self',
  fallback => 1
);

our $VERSION = '2.05'; # VERSION

# BUILD

method new($data = []) {
  if (Scalar::Util::blessed($data)) {
    $data = $data->detract if $data->can('detract');
  }

  unless (ref($data) eq 'ARRAY') {
    Carp::confess('Instantiation Error: Not a ArrayRef');
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

method list() {

  return wantarray ? (@$self) : [@$self];
}

1;

=encoding utf8

=head1 NAME

Data::Object::Array

=cut

=head1 ABSTRACT

Array Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Array;

  my $array = Data::Object::Array->new([1..9]);

=cut

=head1 DESCRIPTION

This package provides methods for manipulating array data.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Kind>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Dumpable>

L<Data::Object::Role::Pluggable>

L<Data::Object::Role::Throwable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Data::Object::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 all

  all(CodeRef $arg1, Any @args) : Num

The all method returns true if the callback returns true for all of the
elements.

=over 4

=item all example #1

  my $array = Data::Object::Array->new([2..5]);

  $array->all(sub {
    my ($value, @args) = @_;

    $value > 1;
  });

=back

=cut

=head2 any

  any(CodeRef $arg1, Any @args) : Num

The any method returns true if the callback returns true for any of the
elements.

=over 4

=item any example #1

  my $array = Data::Object::Array->new([2..5]);

  $array->any(sub {
    my ($value) = @_;

    $value > 5;
  });

=back

=cut

=head2 clear

  clear() : ArrayLike

The clear method is an alias to the empty method.

=over 4

=item clear example #1

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->clear;

=back

=cut

=head2 count

  count() : Num

The count method returns the number of elements within the array.

=over 4

=item count example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->count;

=back

=cut

=head2 defined

  defined() : Num

The defined method returns true if the element at the array index is defined.

=over 4

=item defined example #1

  my $array = Data::Object::Array->new;

  $array->defined;

=back

=cut

=head2 delete

  delete(Int $arg1) : Any

The delete method returns the value of the element at the index specified after
removing it from the array.

=over 4

=item delete example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->delete(2);

=back

=cut

=head2 each

  each(CodeRef $arg1, Any @args) : ArrayLike

The each method executes a callback for each element in the array passing the
index and value as arguments.

=over 4

=item each example #1

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->each(sub {
    my ($index, $value) = @_;

    [$index, $value]
  });

=back

=cut

=head2 each_key

  each_key(CodeRef $arg1, Any @args) : ArrayRef

The each_key method executes a callback for each element in the array passing
the index as an argument.

=over 4

=item each_key example #1

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->each_key(sub {
    my ($index)  = @_;

    [$index]
  });

=back

=cut

=head2 each_n_values

  each_n_values(Num $arg1, CodeRef $arg2, Any @args) : ArrayRef

The each_n_values method executes a callback for each element in the array
passing the routine the next B<n> values until all values have been handled.

=over 4

=item each_n_values example #1

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->each_n_values(4, sub {
    my (@values) = @_;

    # $values[1] # a
    # $values[2] # b
    # $values[3] # c
    # $values[4] # d

    [@values]
  });

=back

=cut

=head2 each_value

  each_value(CodeRef $arg1, Any @args) : ArrayRef

The each_value method executes a callback for each element in the array passing
the routine the value as an argument.

=over 4

=item each_value example #1

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->each_value(sub {
    my ($value, @args) = @_;

    [$value, @args]
  });

=back

=cut

=head2 empty

  empty() : ArrayLike

The empty method drops all elements from the array.

=over 4

=item empty example #1

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->empty;

=back

=cut

=head2 eq

  eq(Any $arg1) : Num

The eq method will throw an exception if called.

=over 4

=item eq example #1

  my $array = Data::Object::Array->new;

  $array->eq([]);

=back

=cut

=head2 exists

  exists(Int $arg1) : Num

The exists method returns true if the element at the index specified exists,
otherwise it returns false.

=over 4

=item exists example #1

  my $array = Data::Object::Array->new([1,2,3,4,5]);

  $array->exists(0);

=back

=cut

=head2 first

  first() : Any

The first method returns the value of the first element.

=over 4

=item first example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->first;

=back

=cut

=head2 ge

  ge(Any $arg1) : Num

The ge method will throw an exception if called.

=over 4

=item ge example #1

  my $array = Data::Object::Array->new;

  $array->ge([]);

=back

=cut

=head2 get

  get(Int $arg1) : Any

The get method returns the value of the element at the index specified.

=over 4

=item get example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->get(0);

=back

=cut

=head2 grep

  grep(CodeRef $arg1, Any @args) : ArrayRef

The grep method executes a callback for each element in the array passing the
value as an argument, returning a new array reference containing the elements
for which the returned true.

=over 4

=item grep example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->grep(sub {
    my ($value) = @_;

    $value >= 3
  });

=back

=cut

=head2 gt

  gt(Any $arg1) : Num

The gt method will throw an exception if called.

=over 4

=item gt example #1

  my $array = Data::Object::Array->new;

  $array->gt([]);

=back

=cut

=head2 hash

  hash() : HashRef

The hash method returns a hash reference where each key and value pairs
corresponds to the index and value of each element in the array.

=over 4

=item hash example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->hash; # {0=>1,1=>2,2=>3,3=>4,4=>5}

=back

=cut

=head2 hashify

  hashify(CodeRef $arg1, Any $arg2) : HashRef

The hashify method returns a hash reference where the elements of array become
the hash keys and the corresponding values are assigned a value of 1.

=over 4

=item hashify example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->hashify;

=back

=over 4

=item hashify example #2

  my $array = Data::Object::Array->new([1..5]);

  $array->hashify(sub { my ($value) = @_; $value % 2 });

=back

=cut

=head2 head

  head() : Any

The head method returns the value of the first element in the array.

=over 4

=item head example #1

  my $array = Data::Object::Array->new([9,8,7,6,5]);

  $array->head; # 9

=back

=cut

=head2 invert

  invert() : Any

The invert method returns an array reference containing the elements in the
array in reverse order.

=over 4

=item invert example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->invert; # [5,4,3,2,1]

=back

=cut

=head2 iterator

  iterator() : CodeRef

The iterator method returns a code reference which can be used to iterate over
the array. Each time the iterator is executed it will return the next element
in the array until all elements have been seen, at which point the iterator
will return an undefined value.

=over 4

=item iterator example #1

  my $array = Data::Object::Array->new([1..5]);

  my $iterator = $array->iterator;

  # while (my $value = $iterator->next) {
  #   say $value; # 1
  # }

=back

=cut

=head2 join

  join(Str $arg1) : Str

The join method returns a string consisting of all the elements in the array
joined by the join-string specified by the argument. Note: If the argument is
omitted, an empty string will be used as the join-string.

=over 4

=item join example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->join; # 12345

=back

=over 4

=item join example #2

  my $array = Data::Object::Array->new([1..5]);

  $array->join(', '); # 1, 2, 3, 4, 5

=back

=cut

=head2 keyed

  keyed(Str $arg1) : HashRef

The keyed method returns a hash reference where the arguments become the keys,
and the elements of the array become the values.

=over 4

=item keyed example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->keyed('a'..'d'); # {a=>1,b=>2,c=>3,d=>4}

=back

=cut

=head2 keys

  keys() : ArrayRef

The keys method returns an array reference consisting of the indicies of the
array.

=over 4

=item keys example #1

  my $array = Data::Object::Array->new(['a'..'d']);

  $array->keys; # [0,1,2,3]

=back

=cut

=head2 last

  last() : Any

The last method returns the value of the last element in the array.

=over 4

=item last example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->last; # 5

=back

=cut

=head2 le

  le(Any $arg1) : Num

The le method will throw an exception if called.

=over 4

=item le example #1

  my $array = Data::Object::Array->new;

  $array->le([]);

=back

=cut

=head2 length

  length() : Num

The length method returns the number of elements in the array.

=over 4

=item length example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->length; # 5

=back

=cut

=head2 list

  list() : (Any)

The list method returns a shallow copy of the underlying array reference as an
array reference.

=over 4

=item list example #1

  my $array = Data::Object::Array->new([1..5]);

  my @list = $array->list;

  [@list]

=back

=cut

=head2 lt

  lt(Any $arg1) : Num

The lt method will throw an exception if called.

=over 4

=item lt example #1

  my $array = Data::Object::Array->new;

  $array->lt([]);

=back

=cut

=head2 map

  map(CodeRef $arg1, Any $arg2) : ArrayRef

The map method iterates over each element in the array, executing the code
reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing the
elements for which the argument returns a value or non-empty list.

=over 4

=item map example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->map(sub {
    $_[0] + 1
  });

  # [2,3,4,5,6]

=back

=cut

=head2 max

  max() : Any

The max method returns the element in the array with the highest numerical
value. All non-numerical element are skipped during the evaluation process.

=over 4

=item max example #1

  my $array = Data::Object::Array->new([8,9,1,2,3,4,5]);

  $array->max; # 9

=back

=cut

=head2 min

  min() : Any

The min method returns the element in the array with the lowest numerical
value. All non-numerical element are skipped during the evaluation process.

=over 4

=item min example #1

  my $array = Data::Object::Array->new([8,9,1,2,3,4,5]);

  $array->min; # 1

=back

=cut

=head2 ne

  ne(Any $arg1) : Num

The ne method will throw an exception if called.

=over 4

=item ne example #1

  my $array = Data::Object::Array->new;

  $array->ne([]);

=back

=cut

=head2 none

  none(CodeRef $arg1, Any $arg2) : Num

The none method returns true if none of the elements in the array meet the
criteria set by the operand and rvalue.

=over 4

=item none example #1

  my $array = Data::Object::Array->new([2..5]);

  $array->none(sub {
    my ($value) = @_;

    $value <= 1; # 1; true
  });

=back

=over 4

=item none example #2

  my $array = Data::Object::Array->new([2..5]);

  $array->none(sub {
    my ($value) = @_;

    $value <= 1; # 1; true
  });

=back

=cut

=head2 nsort

  nsort() : ArrayRef

The nsort method returns an array reference containing the values in the array
sorted numerically.

=over 4

=item nsort example #1

  my $array = Data::Object::Array->new([5,4,3,2,1]);

  $array->nsort; # [1,2,3,4,5]

=back

=cut

=head2 one

  one(CodeRef $arg1, Any $arg2) : Num

The one method returns true if only one of the elements in the array meet the
criteria set by the operand and rvalue.

=over 4

=item one example #1

  my $array = Data::Object::Array->new([2..5]);

  $array->one(sub {
    my ($value) = @_;

    $value == 5; # 1; true
  });

=back

=over 4

=item one example #2

  my $array = Data::Object::Array->new([2..5]);

  $array->one(sub {
    my ($value) = @_;

    $value == 6; # 0; false
  });

=back

=cut

=head2 pairs

  pairs() : ArrayRef

The pairs method is an alias to the pairs_array method.

=over 4

=item pairs example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->pairs; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

=back

=cut

=head2 pairs_array

  pairs_array() : ArrayRef

The pairs_array method returns an array reference consisting of array
references where each sub-array reference has two elements corresponding to the
index and value of each element in the array.

=over 4

=item pairs_array example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->pairs_array; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

=back

=cut

=head2 pairs_hash

  pairs_hash() : HashRef

The pairs_hash method returns a hash reference where each key and value pairs
corresponds to the index and value of each element in the array.

=over 4

=item pairs_hash example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->pairs_hash; # {0=>1,1=>2,2=>3,3=>4,4=>5}

=back

=cut

=head2 part

  part(CodeRef $arg1, Any $arg2) : Tuple[ArrayRef, ArrayRef]

The part method iterates over each element in the array, executing the code
reference supplied in the argument, using the result of the code reference to
partition to array into two distinct array references.

=over 4

=item part example #1

  my $array = Data::Object::Array->new([1..10]);

  $array->part(sub { my ($value) = @_; $value > 5 });

  # [[6, 7, 8, 9, 10], [1, 2, 3, 4, 5]]

=back

=cut

=head2 pop

  pop() : Any

The pop method returns the last element of the array shortening it by one.
Note, this method modifies the array.

=over 4

=item pop example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->pop; # 5

=back

=cut

=head2 push

  push(Any $arg1) : Any

The push method appends the array by pushing the agruments onto it and returns
itself.

=over 4

=item push example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->push(6,7,8); # [1,2,3,4,5,6,7,8]

=back

=cut

=head2 random

  random() : Any

The random method returns a random element from the array.

=over 4

=item random example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->random; # 4

=back

=cut

=head2 reverse

  reverse() : ArrayRef

The reverse method returns an array reference containing the elements in the
array in reverse order.

=over 4

=item reverse example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->reverse; # [5,4,3,2,1]

=back

=cut

=head2 rnsort

  rnsort() : ArrayRef

The rnsort method returns an array reference containing the values in the array
sorted numerically in reverse.

=over 4

=item rnsort example #1

  my $array = Data::Object::Array->new([5,4,3,2,1]);

  $array->rnsort; # [5,4,3,2,1]

=back

=cut

=head2 rotate

  rotate() : ArrayLike

The rotate method rotates the elements in the array such that first elements
becomes the last element and the second element becomes the first element each
time this method is called.

=over 4

=item rotate example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->rotate; # [2,3,4,5,1]

=back

=over 4

=item rotate example #2

  my $array = Data::Object::Array->new([2,3,4,5,1]);

  $array->rotate; # [3,4,5,1,2]

=back

=cut

=head2 rsort

  rsort() : ArrayRef

The rsort method returns an array reference containing the values in the array
sorted alphanumerically in reverse.

=over 4

=item rsort example #1

  my $array = Data::Object::Array->new(['a'..'d']);

  $array->rsort; # ['d','c','b','a']

=back

=cut

=head2 set

  set(Str $arg1, Any $arg2) : Any

The set method returns the value of the element in the array at the index
specified by the argument after updating it to the value of the second
argument.

=over 4

=item set example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->set(4,6); # 6

=back

=cut

=head2 shift

  shift() : Any

The shift method returns the first element of the array shortening it by one.

=over 4

=item shift example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->shift; # 1

=back

=cut

=head2 size

  size() : Num

The size method is an alias to the length method.

=over 4

=item size example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->size; # 5

=back

=cut

=head2 slice

  slice(Any @args) : HashRef

The slice method returns a hash reference containing the elements in the array
at the index(es) specified in the arguments.

=over 4

=item slice example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->kvslice(2,4); # {2=>3, 4=>5}

=back

=cut

=head2 sort

  sort() : ArrayRef

The sort method returns an array reference containing the values in the array
sorted alphanumerically.

=over 4

=item sort example #1

  my $array = Data::Object::Array->new(['d','c','b','a']);

  $array->sort; # ['a','b','c','d']

=back

=cut

=head2 sum

  sum() : Num

The sum method returns the sum of all values for all numerical elements in the
array. All non-numerical element are skipped during the evaluation process.

=over 4

=item sum example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->sum; # 15

=back

=cut

=head2 tail

  tail() : Any

The tail method returns an array reference containing the second through the
last elements in the array omitting the first.

=over 4

=item tail example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->tail; # [2,3,4,5]

=back

=cut

=head2 unique

  unique() : ArrayRef

The unique method returns an array reference consisting of the unique elements
in the array.

=over 4

=item unique example #1

  my $array = Data::Object::Array->new([1,1,1,1,2,3,1]);

  $array->unique; # [1,2,3]

=back

=cut

=head2 unshift

  unshift() : Any

The unshift method prepends the array by pushing the agruments onto it and
returns itself.

=over 4

=item unshift example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->unshift(-2,-1,0); # [-2,-1,0,1,2,3,4,5]

=back

=cut

=head2 values

  values() : ArrayRef

The values method returns an array reference consisting of the elements in the
array. This method essentially copies the content of the array into a new
container.

=over 4

=item values example #1

  my $array = Data::Object::Array->new([1..5]);

  $array->values; # [1,2,3,4,5]

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
