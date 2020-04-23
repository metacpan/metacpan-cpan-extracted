use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Hash

=cut

=abstract

Hash Class for Perl 5

=cut

=includes

method: clear
method: count
method: defined
method: delete
method: each
method: each_key
method: each_n_values
method: each_value
method: empty
method: eq
method: exists
method: filter_exclude
method: filter_include
method: fold
method: ge
method: get
method: grep
method: gt
method: head
method: invert
method: iterator
method: join
method: keys
method: kvslice
method: le
method: length
method: list
method: lookup
method: lt
method: map
method: merge
method: ne
method: pairs
method: reset
method: reverse
method: set
method: slice
method: sort
method: tail
method: unfold
method: values

=cut

=synopsis

  package main;

  use Data::Object::Hash;

  my $hash = Data::Object::Hash->new({1..4});

=cut

=libraries

Data::Object::Types

=cut

=inherits

Data::Object::Kind

=cut

=integrates

Data::Object::Role::Dumpable
Data::Object::Role::Proxyable
Data::Object::Role::Throwable

=cut

=description

This package provides methods for manipulating hash data.

=cut

=method clear

The clear method is an alias to the empty method.

=signature clear

clear() : HashLike

=example-1 clear

  my $hash = Data::Object::Hash->new({1..8});

  $hash->clear; # {}

=cut

=method count

The count method returns the total number of keys defined.

=signature count

count() : Num

=example-1 count

  my $hash = Data::Object::Hash->new({1..4});

  $hash->count; # 2

=cut

=method defined

The defined method returns true if the value matching the key specified in the
argument if defined, otherwise returns false.

=signature defined

defined() : Num

=example-1 defined

  my $hash = Data::Object::Hash->new;

  $hash->defined;

=cut

=method delete

The delete method returns the value matching the key specified in the argument
and returns the value.

=signature delete

delete(Num $arg1) : Any

=example-1 delete

  my $hash = Data::Object::Hash->new({1..8});

  $hash->delete(1); # 2

=cut

=method each

The each method executes callback for each element in the hash passing the
routine the key and value at the current position in the loop.

=signature each

each(CodeRef $arg1, Any @args) : Any

=example-1 each

  my $hash = Data::Object::Hash->new({1..8});

  $hash->each(sub {
    my ($key, $value) = @_;

    [$key, $value]
  });

=cut

=method each_key

The each_key method executes callback for each element in the hash passing the
routine the key at the current position in the loop.

=signature each_key

each_key(CodeRef $arg1, Any @args) : Any

=example-1 each_key

  my $hash = Data::Object::Hash->new({1..8});

  $hash->each_key(sub {
    my ($key) = @_;

    [$key]
  });

=cut

=method each_n_values

The each_n_values method executes callback for each element in the hash passing
the routine the next n values until all values have been seen.

=signature each_n_values

each_n_values(Num $arg1, CodeRef $arg2, Any @args) : Any

=example-1 each_n_values

  my $hash = Data::Object::Hash->new({1..8});

  $hash->each_n_values(4, sub {
    my (@values) = @_;

    # $values[1] # 2
    # $values[2] # 4
    # $values[3] # 6
    # $values[4] # 8

    [@values]
  });

=cut

=method each_value

The each_value method executes callback for each element in the hash passing
the routine the value at the current position in the loop.

=signature each_value

each_value(CodeRef $arg1, Any @args) : Any

=example-1 each_value

  my $hash = Data::Object::Hash->new({1..8});

  $hash->each_value(sub {
    my ($value) = @_;

    [$value]
  });

=cut

=method empty

The empty method drops all elements from the hash.

=signature empty

empty() : HashLike

=example-1 empty

  my $hash = Data::Object::Hash->new({1..8});

  $hash->empty; # {}

=cut

=method eq

The eq method will throw an exception if called.

=signature eq

eq(Any $arg1) : Num

=example-1 eq

  my $hash = Data::Object::Hash->new;

  $hash->eq({});

=cut

=method exists

The exists method returns true if the value matching the key specified in the
argument exists, otherwise returns false.

=signature exists

exists(Num $arg1) : Num

=example-1 exists

  my $hash = Data::Object::Hash->new({1..8,9,undef});

  $hash->exists(1); # 1; true

=example-2 exists

  my $hash = Data::Object::Hash->new({1..8,9,undef});

  $hash->exists(0); # 0; false

=cut

=method filter_exclude

The filter_exclude method returns a hash reference consisting of all key/value
pairs in the hash except for the pairs whose keys are specified in the
arguments.

=signature filter_exclude

filter_exclude(Str @args) : HashRef

=example-1 filter_exclude

  my $hash = Data::Object::Hash->new({1..8});

  $hash->filter_exclude(1,3); # {5=>6,7=>8}

=cut

=method filter_include

The filter_include method returns a hash reference consisting of only key/value
pairs whose keys are specified in the arguments.

=signature filter_include

filter_include(Str @args) : HashRef

=example-1 filter_include

  my $hash = Data::Object::Hash->new({1..8});

  $hash->filter_include(1,3); # {1=>2,3=>4}

=cut

=method fold

The fold method returns a single-level hash reference consisting of key/value
pairs whose keys are paths (using dot-notation where the segments correspond to
nested hash keys and array indices) mapped to the nested values.

=signature fold

fold(Str $arg1, HashRef $arg2, HashRef $arg3) : HashRef

=example-1 fold

  my $hash = Data::Object::Hash->new({3,[4,5,6],7,{8,8,9,9}});

  $hash->fold; # {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}

=cut

=method ge

The ge method will throw an exception if called.

=signature ge

ge(Any $arg1) : Num

=example-1 ge

  my $hash = Data::Object::Hash->new;

  $hash->ge({});

=cut

=method get

The get method returns the value of the element in the hash whose key
corresponds to the key specified in the argument.

=signature get

get(Str $arg1) : Any

=example-1 get

  my $hash = Data::Object::Hash->new({1..8});

  $hash->get(5); # 6

=cut

=method grep

The grep method executes callback for each key/value pair in the hash passing
the routine the key and value at the current position in the loop and returning
a new hash reference containing the elements for which the argument evaluated
true.

=signature grep

grep(CodeRef $arg1, Any $arg2) : HashRef

=example-1 grep

  my $hash = Data::Object::Hash->new({1..4});

  $hash->grep(sub {
    my ($value) = @_;

    $value >= 3
  });

  # {3=>4}

=cut

=method gt

The gt method will throw an exception if called.

=signature gt

gt(Any $arg1) : Num

=example-1 gt

  my $hash = Data::Object::Hash->new;

  $hash->gt({});

=cut

=method head

The head method will throw an exception if called.

=signature head

head() : Any

=example-1 head

  my $hash = Data::Object::Hash->new;

  $hash->head;

=cut

=method invert

The invert method returns the hash after inverting the keys and values
respectively. Note, keys with undefined values will be dropped, also, this
method modifies the hash.

=signature invert

invert() : Any

=example-1 invert

  my $hash = Data::Object::Hash->new({1..8,9,undef,10,''});

  $hash->invert; # {''=>10,2=>1,4=>3,6=>5,8=>7}

=cut

=method iterator

The iterator method returns a code reference which can be used to iterate over
the hash. Each time the iterator is executed it will return the values of the
next element in the hash until all elements have been seen, at which point the
iterator will return an undefined value.

=signature iterator

iterator() : CodeRef

=example-1 iterator

  my $hash = Data::Object::Hash->new({1..8});

  my $iterator = $hash->iterator;

  # while (my $value = $iterator->next) {
  #     say $value; # 2
  # }

=cut

=method join

The join method will throw an exception if called.

=signature join

join() : Any

=example-1 join

  my $hash = Data::Object::Hash->new;

  $hash->join;

=cut

=method keys

The keys method returns an array reference consisting of all the keys in the
hash.

=signature keys

keys() : ArrayRef

=example-1 keys

  my $hash = Data::Object::Hash->new({1..8});

  $hash->keys; # [1,3,5,7]

=cut

=method kvslice

The kvslice method returns a hash reference containing the elements in the hash
at the key(s) specified in the arguments.

=signature kvslice

kvslice(Str @args) : HashRef

=example-1 kvslice

  my $hash = Data::Object::Hash->new({1..8});

  $hash->kvslice(1,5); # {1=>2,5=>6}

=cut

=method le

The le method will throw an exception if called.

=signature le

le(Any $arg1) : Num

=example-1 le

  my $hash = Data::Object::Hash->new;

  $hash->le;

=cut

=method length

The length method returns the number of keys in the hash.

=signature length

length() : Num

=example-1 length

  my $hash = Data::Object::Hash->new({1..8});

  $hash->length; # 4

=cut

=method list

The list method returns a shallow copy of the underlying hash reference as an
array reference.

=signature list

list() : (Any)

=example-1 list

  my $hash = Data::Object::Hash->new({1..8});

  [$hash->list];

=cut

=method lookup

The lookup method returns the value of the element in the hash whose key
corresponds to the key specified in the argument. The key can be a string which
references (using dot-notation) nested keys within the hash. This method will
return undefined if the value is undef or the location expressed in the
argument can not be resolved. Please note, keys containing dots (periods) are
not handled.

=signature lookup

lookup(Str $arg1) : Any

=example-1 lookup

  my $hash = Data::Object::Hash->new({1..3,{4,{5,6,7,{8,9,10,11}}}});

  $hash->lookup('3.4.7'); # {8=>9,10=>11}

=example-2 lookup

  my $hash = Data::Object::Hash->new({1..3,{4,{5,6,7,{8,9,10,11}}}});

  $hash->lookup('3.4'); # {5=>6,7=>{8=>9,10=>11}}

=example-3 lookup

  my $hash = Data::Object::Hash->new({1..3,{4,{5,6,7,{8,9,10,11}}}});

  $hash->lookup(1); # 2

=cut

=method lt

The lt method will throw an exception if called.

=signature lt

lt(Any $arg1) : Num

=example-1 lt

  my $hash = Data::Object::Hash->new;

  $hash->lt({});

=cut

=method map

The map method executes callback for each key/value in the hash passing the
routine the value at the current position in the loop and returning a new hash
reference containing the elements for which the argument returns a value or
non-empty list.

=signature map

map(CodeRef $arg1, Any $arg2) : ArrayRef

=example-1 map

  my $hash = Data::Object::Hash->new({1..4});

  $hash->map(sub {
    $_[0] + 1
  });

=cut

=method merge

The merge method returns a hash reference where the elements in the hash and
the elements in the argument(s) are merged. This operation performs a deep
merge and clones the datasets to ensure no side-effects. The merge behavior
merges hash references only, all other data types are assigned with precendence
given to the value being merged.

=signature merge

merge() : HashRef

=example-1 merge

  my $hash = Data::Object::Hash->new({1..8});

  $hash->merge({7,7,9,9}); # {1=>2,3=>4,5=>6,7=>7,9=>9}

=cut

=method ne

The ne method will throw an exception if called.

=signature ne

ne(Any $arg1) : Num

=example-1 ne

  my $hash = Data::Object::Hash->new;

  $hash->ne({});

=cut

=method pairs

The pairs method is an alias to the pairs_array method.

=signature pairs

pairs() : ArrayRef

=example-1 pairs

  my $hash = Data::Object::Hash->new({1..8});

  $hash->pairs; # [[1,2],[3,4],[5,6],[7,8]]

=cut

=method reset

The reset method returns nullifies the value of each element in the hash.

=signature reset

reset() : HashLike

=example-1 reset

  my $hash = Data::Object::Hash->new({1..8});

  $hash->reset; # {1=>undef,3=>undef,5=>undef,7=>undef}

=cut

=method reverse

The reverse method returns a hash reference consisting of the hash's keys and
values inverted. Note, keys with undefined values will be dropped.

=signature reverse

reverse() : HashRef

=example-1 reverse

  my $hash = Data::Object::Hash->new({1..8,9,undef});

  $hash->reverse; # {8=>7,6=>5,4=>3,2=>1}

=cut

=method set

The set method returns the value of the element in the hash corresponding to
the key specified by the argument after updating it to the value of the second
argument.

=signature set

set(Str $arg1, Any $arg2) : Any

=example-1 set

  my $hash = Data::Object::Hash->new({1..8});

  $hash->set(1,10); # 10

=example-2 set

  my $hash = Data::Object::Hash->new({1..8});

  $hash->set(1,12); # 12

=example-3 set

  my $hash = Data::Object::Hash->new({1..8});

  $hash->set(1,0); # 0

=cut

=method slice

The slice method returns an array reference of the values that correspond to
the key(s) specified in the arguments.

=signature slice

slice(Str @args) : ArrayRef

=example-1 slice

  my $hash = Data::Object::Hash->new({1..8});

  $hash->slice(1,3); # [2,4]

=cut

=method sort

The sort method will throw an exception if called.

=signature sort

sort() : Any

=example-1 sort

  my $hash = Data::Object::Hash->new({1..8});

  $hash->sort;

=cut

=method tail

The tail method will throw an exception if called.

=signature tail

tail() : Any

=example-1 tail

  my $hash = Data::Object::Hash->new({1..8});

  $hash->tail;

=cut

=method unfold

The unfold method processes previously folded hash references and returns an
unfolded hash reference where the keys, which are paths (using dot-notation
where the segments correspond to nested hash keys and array indices), are used
to created nested hash and/or array references.

=signature unfold

unfold() : HashRef

=example-1 unfold

  my $hash = Data::Object::Hash->new(
    {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}
  );

  $hash->unfold; # {3=>[4,5,6],7,{8,8,9,9}}

=cut

=method values

The values method returns an array reference consisting of the values of the
elements in the hash.

=signature values

values() : ArrayRef

=example-1 values

  my $hash = Data::Object::Hash->new({1..8});

  $hash->values; # [2,4,6,8]

=cut

package main;

my $subs = testauto(__FILE__);

$subs->package;
$subs->document;
$subs->libraries;
$subs->inherits;
$subs->attributes;
$subs->routines;
$subs->functions;
$subs->types;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'clear', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

$subs->example(-1, 'count', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 2;

  $result
});

$subs->example(-1, 'defined', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'delete', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 2;

  $result
});

$subs->example(-1, 'each', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'each_key', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'each_n_values', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'each_value', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'empty', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

$subs->example(-1, 'eq', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'exists', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'filter_exclude', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {5=>6,7=>8};

  $result
});

$subs->example(-1, 'filter_include', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {1=>2,3=>4};

  $result
});

$subs->example(-1, 'fold', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9};

  $result
});

$subs->example(-1, 'ge', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'get', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 6;

  $result
});

$subs->example(-1, 'grep', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {3=>4};

  $result
});

$subs->example(-1, 'gt', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'head', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'invert', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {''=>10,2=>1,4=>3,6=>5,8=>7};

  $result
});

$subs->example(-1, 'iterator', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is ref $result, 'CODE';
  is $result->(), 2;

  $result
});

$subs->example(-1, 'join', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'keys', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply [sort @$result], [1,3,5,7];

  $result
});

$subs->example(-1, 'kvslice', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {1=>2,5=>6};

  $result
});

$subs->example(-1, 'le', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'length', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 4;

  $result
});

$subs->example(-1, 'list', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply [sort 1..8], [sort @$result];

  $result
});

$subs->example(-1, 'lookup', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {8=>9,10=>11};

  $result
});

$subs->example(-1, 'lt', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'map', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'merge', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {1=>2,3=>4,5=>6,7=>7,9=>9};

  $result
});

$subs->example(-1, 'ne', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'pairs', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [[1,2],[3,4],[5,6],[7,8]];

  $result
});

$subs->example(-1, 'reset', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {1=>undef,3=>undef,5=>undef,7=>undef};

  $result
});

$subs->example(-1, 'reverse', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {8=>7,6=>5,4=>3,2=>1};

  $result
});

$subs->example(-1, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 10;

  $result
});

$subs->example(-1, 'slice', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [2,4];

  $result
});

$subs->example(-1, 'sort', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'tail', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'unfold', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {3=>[4,5,6],7,{8,8,9,9}};

  $result
});

$subs->example(-1, 'values', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply [sort @$result], [2,4,6,8];

  $result
});

ok 1 and done_testing;
