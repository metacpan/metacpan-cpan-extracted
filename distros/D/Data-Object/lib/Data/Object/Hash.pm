package Data::Object::Hash;

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
  '%{}'    => 'self',
  fallback => 1
);

our $VERSION = '2.05'; # VERSION

# BUILD

method new($data = {}) {
  if (Scalar::Util::blessed($data)) {
    $data = $data->detract if $data->can('detract');
  }

  unless (ref($data) eq 'HASH') {
    Carp::confess('Instantiation Error: Not a HashRef');
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

  return wantarray ? (%$self) : [%$self];
}

1;

=encoding utf8

=head1 NAME

Data::Object::Hash

=cut

=head1 ABSTRACT

Hash Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Data::Object::Hash;

  my $hash = Data::Object::Hash->new({1..4});

=cut

=head1 DESCRIPTION

This package provides methods for manipulating hash data.

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

=head2 clear

  clear() : HashLike

The clear method is an alias to the empty method.

=over 4

=item clear example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->clear; # {}

=back

=cut

=head2 count

  count() : Num

The count method returns the total number of keys defined.

=over 4

=item count example #1

  my $hash = Data::Object::Hash->new({1..4});

  $hash->count; # 2

=back

=cut

=head2 defined

  defined() : Num

The defined method returns true if the value matching the key specified in the
argument if defined, otherwise returns false.

=over 4

=item defined example #1

  my $hash = Data::Object::Hash->new;

  $hash->defined;

=back

=cut

=head2 delete

  delete(Num $arg1) : Any

The delete method returns the value matching the key specified in the argument
and returns the value.

=over 4

=item delete example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->delete(1); # 2

=back

=cut

=head2 each

  each(CodeRef $arg1, Any @args) : Any

The each method executes callback for each element in the hash passing the
routine the key and value at the current position in the loop.

=over 4

=item each example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->each(sub {
    my ($key, $value) = @_;

    [$key, $value]
  });

=back

=cut

=head2 each_key

  each_key(CodeRef $arg1, Any @args) : Any

The each_key method executes callback for each element in the hash passing the
routine the key at the current position in the loop.

=over 4

=item each_key example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->each_key(sub {
    my ($key) = @_;

    [$key]
  });

=back

=cut

=head2 each_n_values

  each_n_values(Num $arg1, CodeRef $arg2, Any @args) : Any

The each_n_values method executes callback for each element in the hash passing
the routine the next n values until all values have been seen.

=over 4

=item each_n_values example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->each_n_values(4, sub {
    my (@values) = @_;

    # $values[1] # 2
    # $values[2] # 4
    # $values[3] # 6
    # $values[4] # 8

    [@values]
  });

=back

=cut

=head2 each_value

  each_value(CodeRef $arg1, Any @args) : Any

The each_value method executes callback for each element in the hash passing
the routine the value at the current position in the loop.

=over 4

=item each_value example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->each_value(sub {
    my ($value) = @_;

    [$value]
  });

=back

=cut

=head2 empty

  empty() : HashLike

The empty method drops all elements from the hash.

=over 4

=item empty example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->empty; # {}

=back

=cut

=head2 eq

  eq(Any $arg1) : Num

The eq method will throw an exception if called.

=over 4

=item eq example #1

  my $hash = Data::Object::Hash->new;

  $hash->eq({});

=back

=cut

=head2 exists

  exists(Num $arg1) : Num

The exists method returns true if the value matching the key specified in the
argument exists, otherwise returns false.

=over 4

=item exists example #1

  my $hash = Data::Object::Hash->new({1..8,9,undef});

  $hash->exists(1); # 1; true

=back

=over 4

=item exists example #2

  my $hash = Data::Object::Hash->new({1..8,9,undef});

  $hash->exists(0); # 0; false

=back

=cut

=head2 filter_exclude

  filter_exclude(Str @args) : HashRef

The filter_exclude method returns a hash reference consisting of all key/value
pairs in the hash except for the pairs whose keys are specified in the
arguments.

=over 4

=item filter_exclude example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->filter_exclude(1,3); # {5=>6,7=>8}

=back

=cut

=head2 filter_include

  filter_include(Str @args) : HashRef

The filter_include method returns a hash reference consisting of only key/value
pairs whose keys are specified in the arguments.

=over 4

=item filter_include example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->filter_include(1,3); # {1=>2,3=>4}

=back

=cut

=head2 fold

  fold(Str $arg1, HashRef $arg2, HashRef $arg3) : HashRef

The fold method returns a single-level hash reference consisting of key/value
pairs whose keys are paths (using dot-notation where the segments correspond to
nested hash keys and array indices) mapped to the nested values.

=over 4

=item fold example #1

  my $hash = Data::Object::Hash->new({3,[4,5,6],7,{8,8,9,9}});

  $hash->fold; # {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}

=back

=cut

=head2 ge

  ge(Any $arg1) : Num

The ge method will throw an exception if called.

=over 4

=item ge example #1

  my $hash = Data::Object::Hash->new;

  $hash->ge({});

=back

=cut

=head2 get

  get(Str $arg1) : Any

The get method returns the value of the element in the hash whose key
corresponds to the key specified in the argument.

=over 4

=item get example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->get(5); # 6

=back

=cut

=head2 grep

  grep(CodeRef $arg1, Any $arg2) : HashRef

The grep method executes callback for each key/value pair in the hash passing
the routine the key and value at the current position in the loop and returning
a new hash reference containing the elements for which the argument evaluated
true.

=over 4

=item grep example #1

  my $hash = Data::Object::Hash->new({1..4});

  $hash->grep(sub {
    my ($value) = @_;

    $value >= 3
  });

  # {3=>4}

=back

=cut

=head2 gt

  gt(Any $arg1) : Num

The gt method will throw an exception if called.

=over 4

=item gt example #1

  my $hash = Data::Object::Hash->new;

  $hash->gt({});

=back

=cut

=head2 head

  head() : Any

The head method will throw an exception if called.

=over 4

=item head example #1

  my $hash = Data::Object::Hash->new;

  $hash->head;

=back

=cut

=head2 invert

  invert() : Any

The invert method returns the hash after inverting the keys and values
respectively. Note, keys with undefined values will be dropped, also, this
method modifies the hash.

=over 4

=item invert example #1

  my $hash = Data::Object::Hash->new({1..8,9,undef,10,''});

  $hash->invert; # {''=>10,2=>1,4=>3,6=>5,8=>7}

=back

=cut

=head2 iterator

  iterator() : CodeRef

The iterator method returns a code reference which can be used to iterate over
the hash. Each time the iterator is executed it will return the values of the
next element in the hash until all elements have been seen, at which point the
iterator will return an undefined value.

=over 4

=item iterator example #1

  my $hash = Data::Object::Hash->new({1..8});

  my $iterator = $hash->iterator;

  # while (my $value = $iterator->next) {
  #     say $value; # 2
  # }

=back

=cut

=head2 join

  join() : Any

The join method will throw an exception if called.

=over 4

=item join example #1

  my $hash = Data::Object::Hash->new;

  $hash->join;

=back

=cut

=head2 keys

  keys() : ArrayRef

The keys method returns an array reference consisting of all the keys in the
hash.

=over 4

=item keys example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->keys; # [1,3,5,7]

=back

=cut

=head2 kvslice

  kvslice(Str @args) : HashRef

The kvslice method returns a hash reference containing the elements in the hash
at the key(s) specified in the arguments.

=over 4

=item kvslice example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->kvslice(1,5); # {1=>2,5=>6}

=back

=cut

=head2 le

  le(Any $arg1) : Num

The le method will throw an exception if called.

=over 4

=item le example #1

  my $hash = Data::Object::Hash->new;

  $hash->le;

=back

=cut

=head2 length

  length() : Num

The length method returns the number of keys in the hash.

=over 4

=item length example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->length; # 4

=back

=cut

=head2 list

  list() : (Any)

The list method returns a shallow copy of the underlying hash reference as an
array reference.

=over 4

=item list example #1

  my $hash = Data::Object::Hash->new({1..8});

  [$hash->list];

=back

=cut

=head2 lookup

  lookup(Str $arg1) : Any

The lookup method returns the value of the element in the hash whose key
corresponds to the key specified in the argument. The key can be a string which
references (using dot-notation) nested keys within the hash. This method will
return undefined if the value is undef or the location expressed in the
argument can not be resolved. Please note, keys containing dots (periods) are
not handled.

=over 4

=item lookup example #1

  my $hash = Data::Object::Hash->new({1..3,{4,{5,6,7,{8,9,10,11}}}});

  $hash->lookup('3.4.7'); # {8=>9,10=>11}

=back

=over 4

=item lookup example #2

  my $hash = Data::Object::Hash->new({1..3,{4,{5,6,7,{8,9,10,11}}}});

  $hash->lookup('3.4'); # {5=>6,7=>{8=>9,10=>11}}

=back

=over 4

=item lookup example #3

  my $hash = Data::Object::Hash->new({1..3,{4,{5,6,7,{8,9,10,11}}}});

  $hash->lookup(1); # 2

=back

=cut

=head2 lt

  lt(Any $arg1) : Num

The lt method will throw an exception if called.

=over 4

=item lt example #1

  my $hash = Data::Object::Hash->new;

  $hash->lt({});

=back

=cut

=head2 map

  map(CodeRef $arg1, Any $arg2) : ArrayRef

The map method executes callback for each key/value in the hash passing the
routine the value at the current position in the loop and returning a new hash
reference containing the elements for which the argument returns a value or
non-empty list.

=over 4

=item map example #1

  my $hash = Data::Object::Hash->new({1..4});

  $hash->map(sub {
    $_[0] + 1
  });

=back

=cut

=head2 merge

  merge() : HashRef

The merge method returns a hash reference where the elements in the hash and
the elements in the argument(s) are merged. This operation performs a deep
merge and clones the datasets to ensure no side-effects. The merge behavior
merges hash references only, all other data types are assigned with precendence
given to the value being merged.

=over 4

=item merge example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->merge({7,7,9,9}); # {1=>2,3=>4,5=>6,7=>7,9=>9}

=back

=cut

=head2 ne

  ne(Any $arg1) : Num

The ne method will throw an exception if called.

=over 4

=item ne example #1

  my $hash = Data::Object::Hash->new;

  $hash->ne({});

=back

=cut

=head2 pairs

  pairs() : ArrayRef

The pairs method is an alias to the pairs_array method.

=over 4

=item pairs example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->pairs; # [[1,2],[3,4],[5,6],[7,8]]

=back

=cut

=head2 reset

  reset() : HashLike

The reset method returns nullifies the value of each element in the hash.

=over 4

=item reset example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->reset; # {1=>undef,3=>undef,5=>undef,7=>undef}

=back

=cut

=head2 reverse

  reverse() : HashRef

The reverse method returns a hash reference consisting of the hash's keys and
values inverted. Note, keys with undefined values will be dropped.

=over 4

=item reverse example #1

  my $hash = Data::Object::Hash->new({1..8,9,undef});

  $hash->reverse; # {8=>7,6=>5,4=>3,2=>1}

=back

=cut

=head2 set

  set(Str $arg1, Any $arg2) : Any

The set method returns the value of the element in the hash corresponding to
the key specified by the argument after updating it to the value of the second
argument.

=over 4

=item set example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->set(1,10); # 10

=back

=over 4

=item set example #2

  my $hash = Data::Object::Hash->new({1..8});

  $hash->set(1,12); # 12

=back

=over 4

=item set example #3

  my $hash = Data::Object::Hash->new({1..8});

  $hash->set(1,0); # 0

=back

=cut

=head2 slice

  slice(Str @args) : ArrayRef

The slice method returns an array reference of the values that correspond to
the key(s) specified in the arguments.

=over 4

=item slice example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->slice(1,3); # [2,4]

=back

=cut

=head2 sort

  sort() : Any

The sort method will throw an exception if called.

=over 4

=item sort example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->sort;

=back

=cut

=head2 tail

  tail() : Any

The tail method will throw an exception if called.

=over 4

=item tail example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->tail;

=back

=cut

=head2 unfold

  unfold() : HashRef

The unfold method processes previously folded hash references and returns an
unfolded hash reference where the keys, which are paths (using dot-notation
where the segments correspond to nested hash keys and array indices), are used
to created nested hash and/or array references.

=over 4

=item unfold example #1

  my $hash = Data::Object::Hash->new(
    {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}
  );

  $hash->unfold; # {3=>[4,5,6],7,{8,8,9,9}}

=back

=cut

=head2 values

  values() : ArrayRef

The values method returns an array reference consisting of the values of the
elements in the hash.

=over 4

=item values example #1

  my $hash = Data::Object::Hash->new({1..8});

  $hash->values; # [2,4,6,8]

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
