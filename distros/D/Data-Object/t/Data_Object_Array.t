use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Array

=cut

=abstract

Array Class for Perl 5

=cut

=includes

method: all
method: any
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
method: first
method: ge
method: get
method: grep
method: gt
method: hash
method: hashify
method: head
method: invert
method: iterator
method: join
method: keyed
method: keys
method: last
method: le
method: length
method: list
method: lt
method: map
method: max
method: min
method: ne
method: none
method: nsort
method: one
method: pairs
method: pairs_array
method: pairs_hash
method: part
method: pop
method: push
method: random
method: reverse
method: rnsort
method: rotate
method: rsort
method: set
method: shift
method: size
method: slice
method: sort
method: sum
method: tail
method: unique
method: unshift
method: values

=cut

=synopsis

  package main;

  use Data::Object::Array;

  my $array = Data::Object::Array->new([1..9]);

=cut

=libraries

Data::Object::Types

=cut

=inherits

Data::Object::Kind

=cut

=integrates

Data::Object::Role::Dumpable
Data::Object::Role::Pluggable
Data::Object::Role::Throwable

=cut

=description

This package provides methods for manipulating array data.

=cut

=method all

The all method returns true if the callback returns true for all of the
elements.

=signature all

all(CodeRef $arg1, Any @args) : Num

=example-1 all

  my $array = Data::Object::Array->new([2..5]);

  $array->all(sub {
    my ($value, @args) = @_;

    $value > 1;
  });

=cut

=method any

The any method returns true if the callback returns true for any of the
elements.

=signature any

any(CodeRef $arg1, Any @args) : Num

=example-1 any

  my $array = Data::Object::Array->new([2..5]);

  $array->any(sub {
    my ($value) = @_;

    $value > 5;
  });

=cut

=method clear

The clear method is an alias to the empty method.

=signature clear

clear() : ArrayLike

=example-1 clear

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->clear;

=cut

=method count

The count method returns the number of elements within the array.

=signature count

count() : Num

=example-1 count

  my $array = Data::Object::Array->new([1..5]);

  $array->count;

=cut

=method defined

The defined method returns true if the element at the array index is defined.

=signature defined

defined() : Num

=example-1 defined

  my $array = Data::Object::Array->new;

  $array->defined;

=cut

=method delete

The delete method returns the value of the element at the index specified after
removing it from the array.

=signature delete

delete(Int $arg1) : Any

=example-1 delete

  my $array = Data::Object::Array->new([1..5]);

  $array->delete(2);

=cut

=method each

The each method executes a callback for each element in the array passing the
index and value as arguments.

=signature each

each(CodeRef $arg1, Any @args) : ArrayLike

=example-1 each

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->each(sub {
    my ($index, $value) = @_;

    [$index, $value]
  });

=cut

=method each_key

The each_key method executes a callback for each element in the array passing
the index as an argument.

=signature each_key

each_key(CodeRef $arg1, Any @args) : ArrayRef

=example-1 each_key

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->each_key(sub {
    my ($index)  = @_;

    [$index]
  });

=cut

=method each_n_values

The each_n_values method executes a callback for each element in the array
passing the routine the next B<n> values until all values have been handled.

=signature each_n_values

each_n_values(Num $arg1, CodeRef $arg2, Any @args) : ArrayRef

=example-1 each_n_values

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->each_n_values(4, sub {
    my (@values) = @_;

    # $values[1] # a
    # $values[2] # b
    # $values[3] # c
    # $values[4] # d

    [@values]
  });

=cut

=method each_value

The each_value method executes a callback for each element in the array passing
the routine the value as an argument.

=signature each_value

each_value(CodeRef $arg1, Any @args) : ArrayRef

=example-1 each_value

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->each_value(sub {
    my ($value, @args) = @_;

    [$value, @args]
  });

=cut

=method empty

The empty method drops all elements from the array.

=signature empty

empty() : ArrayLike

=example-1 empty

  my $array = Data::Object::Array->new(['a'..'g']);

  $array->empty;

=cut

=method eq

The eq method will throw an exception if called.

=signature eq

eq(Any $arg1) : Num

=example-1 eq

  my $array = Data::Object::Array->new;

  $array->eq([]);

=cut

=method exists

The exists method returns true if the element at the index specified exists,
otherwise it returns false.

=signature exists

exists(Int $arg1) : Num

=example-1 exists

  my $array = Data::Object::Array->new([1,2,3,4,5]);

  $array->exists(0);

=cut

=method first

The first method returns the value of the first element.

=signature first

first() : Any

=example-1 first

  my $array = Data::Object::Array->new([1..5]);

  $array->first;

=cut

=method ge

The ge method will throw an exception if called.

=signature ge

ge(Any $arg1) : Num

=example-1 ge

  my $array = Data::Object::Array->new;

  $array->ge([]);

=cut

=method get

The get method returns the value of the element at the index specified.

=signature get

get(Int $arg1) : Any

=example-1 get

  my $array = Data::Object::Array->new([1..5]);

  $array->get(0);

=cut

=method grep

The grep method executes a callback for each element in the array passing the
value as an argument, returning a new array reference containing the elements
for which the returned true.

=signature grep

grep(CodeRef $arg1, Any @args) : ArrayRef

=example-1 grep

  my $array = Data::Object::Array->new([1..5]);

  $array->grep(sub {
    my ($value) = @_;

    $value >= 3
  });

=cut

=method gt

The gt method will throw an exception if called.

=signature gt

gt(Any $arg1) : Num

=example-1 gt

  my $array = Data::Object::Array->new;

  $array->gt([]);

=cut

=method hash

The hash method returns a hash reference where each key and value pairs
corresponds to the index and value of each element in the array.

=signature hash

hash() : HashRef

=example-1 hash

  my $array = Data::Object::Array->new([1..5]);

  $array->hash; # {0=>1,1=>2,2=>3,3=>4,4=>5}

=cut

=method hashify

The hashify method returns a hash reference where the elements of array become
the hash keys and the corresponding values are assigned a value of 1.

=signature hashify

hashify(CodeRef $arg1, Any $arg2) : HashRef

=example-1 hashify

  my $array = Data::Object::Array->new([1..5]);

  $array->hashify;

=example-2 hashify

  my $array = Data::Object::Array->new([1..5]);

  $array->hashify(sub { my ($value) = @_; $value % 2 });

=cut

=method head

The head method returns the value of the first element in the array.

=signature head

head() : Any

=example-1 head

  my $array = Data::Object::Array->new([9,8,7,6,5]);

  $array->head; # 9

=cut

=method invert

The invert method returns an array reference containing the elements in the
array in reverse order.

=signature invert

invert() : Any

=example-1 invert

  my $array = Data::Object::Array->new([1..5]);

  $array->invert; # [5,4,3,2,1]

=cut

=method iterator

The iterator method returns a code reference which can be used to iterate over
the array. Each time the iterator is executed it will return the next element
in the array until all elements have been seen, at which point the iterator
will return an undefined value.

=signature iterator

iterator() : CodeRef

=example-1 iterator

  my $array = Data::Object::Array->new([1..5]);

  my $iterator = $array->iterator;

  # while (my $value = $iterator->next) {
  #   say $value; # 1
  # }

=cut

=method join

The join method returns a string consisting of all the elements in the array
joined by the join-string specified by the argument. Note: If the argument is
omitted, an empty string will be used as the join-string.

=signature join

join(Str $arg1) : Str

=example-1 join

  my $array = Data::Object::Array->new([1..5]);

  $array->join; # 12345

=example-2 join

  my $array = Data::Object::Array->new([1..5]);

  $array->join(', '); # 1, 2, 3, 4, 5

=cut

=method keyed

The keyed method returns a hash reference where the arguments become the keys,
and the elements of the array become the values.

=signature keyed

keyed(Str $arg1) : HashRef

=example-1 keyed

  my $array = Data::Object::Array->new([1..5]);

  $array->keyed('a'..'d'); # {a=>1,b=>2,c=>3,d=>4}

=cut

=method keys

The keys method returns an array reference consisting of the indicies of the
array.

=signature keys

keys() : ArrayRef

=example-1 keys

  my $array = Data::Object::Array->new(['a'..'d']);

  $array->keys; # [0,1,2,3]

=cut

=method last

The last method returns the value of the last element in the array.

=signature last

last() : Any

=example-1 last

  my $array = Data::Object::Array->new([1..5]);

  $array->last; # 5

=cut

=method le

The le method will throw an exception if called.

=signature le

le(Any $arg1) : Num

=example-1 le

  my $array = Data::Object::Array->new;

  $array->le([]);

=cut

=method length

The length method returns the number of elements in the array.

=signature length

length() : Num

=example-1 length

  my $array = Data::Object::Array->new([1..5]);

  $array->length; # 5

=cut

=method list

The list method returns a shallow copy of the underlying array reference as an
array reference.

=signature list

list() : (Any)

=example-1 list

  my $array = Data::Object::Array->new([1..5]);

  my @list = $array->list;

  [@list]

=cut

=method lt

The lt method will throw an exception if called.

=signature lt

lt(Any $arg1) : Num

=example-1 lt

  my $array = Data::Object::Array->new;

  $array->lt([]);

=cut

=method map

The map method iterates over each element in the array, executing the code
reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing the
elements for which the argument returns a value or non-empty list.

=signature map

map(CodeRef $arg1, Any $arg2) : ArrayRef

=example-1 map

  my $array = Data::Object::Array->new([1..5]);

  $array->map(sub {
    $_[0] + 1
  });

  # [2,3,4,5,6]

=cut

=method max

The max method returns the element in the array with the highest numerical
value. All non-numerical element are skipped during the evaluation process.

=signature max

max() : Any

=example-1 max

  my $array = Data::Object::Array->new([8,9,1,2,3,4,5]);

  $array->max; # 9

=cut

=method min

The min method returns the element in the array with the lowest numerical
value. All non-numerical element are skipped during the evaluation process.

=signature min

min() : Any

=example-1 min

  my $array = Data::Object::Array->new([8,9,1,2,3,4,5]);

  $array->min; # 1

=cut

=method ne

The ne method will throw an exception if called.

=signature ne

ne(Any $arg1) : Num

=example-1 ne

  my $array = Data::Object::Array->new;

  $array->ne([]);

=cut

=method none

The none method returns true if none of the elements in the array meet the
criteria set by the operand and rvalue.

=signature none

none(CodeRef $arg1, Any $arg2) : Num

=example-1 none

  my $array = Data::Object::Array->new([2..5]);

  $array->none(sub {
    my ($value) = @_;

    $value <= 1; # 1; true
  });

=example-2 none

  my $array = Data::Object::Array->new([2..5]);

  $array->none(sub {
    my ($value) = @_;

    $value <= 1; # 1; true
  });

=cut

=method nsort

The nsort method returns an array reference containing the values in the array
sorted numerically.

=signature nsort

nsort() : ArrayRef

=example-1 nsort

  my $array = Data::Object::Array->new([5,4,3,2,1]);

  $array->nsort; # [1,2,3,4,5]

=cut

=method one

The one method returns true if only one of the elements in the array meet the
criteria set by the operand and rvalue.

=signature one

one(CodeRef $arg1, Any $arg2) : Num

=example-1 one

  my $array = Data::Object::Array->new([2..5]);

  $array->one(sub {
    my ($value) = @_;

    $value == 5; # 1; true
  });

=example-2 one

  my $array = Data::Object::Array->new([2..5]);

  $array->one(sub {
    my ($value) = @_;

    $value == 6; # 0; false
  });

=cut

=method pairs

The pairs method is an alias to the pairs_array method.

=signature pairs

pairs() : ArrayRef

=example-1 pairs

  my $array = Data::Object::Array->new([1..5]);

  $array->pairs; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

=cut

=method pairs_array

The pairs_array method returns an array reference consisting of array
references where each sub-array reference has two elements corresponding to the
index and value of each element in the array.

=signature pairs_array

pairs_array() : ArrayRef

=example-1 pairs_array

  my $array = Data::Object::Array->new([1..5]);

  $array->pairs_array; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

=cut

=method pairs_hash

The pairs_hash method returns a hash reference where each key and value pairs
corresponds to the index and value of each element in the array.

=signature pairs_hash

pairs_hash() : HashRef

=example-1 pairs_hash

  my $array = Data::Object::Array->new([1..5]);

  $array->pairs_hash; # {0=>1,1=>2,2=>3,3=>4,4=>5}

=cut

=method part

The part method iterates over each element in the array, executing the code
reference supplied in the argument, using the result of the code reference to
partition to array into two distinct array references.

=signature part

part(CodeRef $arg1, Any $arg2) : Tuple[ArrayRef, ArrayRef]

=example-1 part

  my $array = Data::Object::Array->new([1..10]);

  $array->part(sub { my ($value) = @_; $value > 5 });

  # [[6, 7, 8, 9, 10], [1, 2, 3, 4, 5]]

=cut

=method pop

The pop method returns the last element of the array shortening it by one.
Note, this method modifies the array.

=signature pop

pop() : Any

=example-1 pop

  my $array = Data::Object::Array->new([1..5]);

  $array->pop; # 5

=cut

=method push

The push method appends the array by pushing the agruments onto it and returns
itself.

=signature push

push(Any $arg1) : Any

=example-1 push

  my $array = Data::Object::Array->new([1..5]);

  $array->push(6,7,8); # [1,2,3,4,5,6,7,8]

=cut

=method random

The random method returns a random element from the array.

=signature random

random() : Any

=example-1 random

  my $array = Data::Object::Array->new([1..5]);

  $array->random; # 4

=cut

=method reverse

The reverse method returns an array reference containing the elements in the
array in reverse order.

=signature reverse

reverse() : ArrayRef

=example-1 reverse

  my $array = Data::Object::Array->new([1..5]);

  $array->reverse; # [5,4,3,2,1]

=cut

=method rnsort

The rnsort method returns an array reference containing the values in the array
sorted numerically in reverse.

=signature rnsort

rnsort() : ArrayRef

=example-1 rnsort

  my $array = Data::Object::Array->new([5,4,3,2,1]);

  $array->rnsort; # [5,4,3,2,1]

=cut

=method rotate

The rotate method rotates the elements in the array such that first elements
becomes the last element and the second element becomes the first element each
time this method is called.

=signature rotate

rotate() : ArrayLike

=example-1 rotate

  my $array = Data::Object::Array->new([1..5]);

  $array->rotate; # [2,3,4,5,1]

=example-2 rotate

  my $array = Data::Object::Array->new([2,3,4,5,1]);

  $array->rotate; # [3,4,5,1,2]

=example-1 rotate

  my $array = Data::Object::Array->new([3,4,5,1,2]);

  $array->rotate; # [4,5,1,2,3]

=cut

=method rsort

The rsort method returns an array reference containing the values in the array
sorted alphanumerically in reverse.

=signature rsort

rsort() : ArrayRef

=example-1 rsort

  my $array = Data::Object::Array->new(['a'..'d']);

  $array->rsort; # ['d','c','b','a']

=cut

=method set

The set method returns the value of the element in the array at the index
specified by the argument after updating it to the value of the second
argument.

=signature set

set(Str $arg1, Any $arg2) : Any

=example-1 set

  my $array = Data::Object::Array->new([1..5]);

  $array->set(4,6); # 6

=cut

=method shift

The shift method returns the first element of the array shortening it by one.

=signature shift

shift() : Any

=example-1 shift

  my $array = Data::Object::Array->new([1..5]);

  $array->shift; # 1

=cut

=method size

The size method is an alias to the length method.

=signature size

size() : Num

=example-1 size

  my $array = Data::Object::Array->new([1..5]);

  $array->size; # 5

=cut

=method slice

The slice method returns a hash reference containing the elements in the array
at the index(es) specified in the arguments.

=signature slice

slice(Any @args) : HashRef

=example-1 slice

  my $array = Data::Object::Array->new([1..5]);

  $array->kvslice(2,4); # {2=>3, 4=>5}

=cut

=method sort

The sort method returns an array reference containing the values in the array
sorted alphanumerically.

=signature sort

sort() : ArrayRef

=example-1 sort

  my $array = Data::Object::Array->new(['d','c','b','a']);

  $array->sort; # ['a','b','c','d']

=cut

=method sum

The sum method returns the sum of all values for all numerical elements in the
array. All non-numerical element are skipped during the evaluation process.

=signature sum

sum() : Num

=example-1 sum

  my $array = Data::Object::Array->new([1..5]);

  $array->sum; # 15

=cut

=method tail

The tail method returns an array reference containing the second through the
last elements in the array omitting the first.

=signature tail

tail() : Any

=example-1 tail

  my $array = Data::Object::Array->new([1..5]);

  $array->tail; # [2,3,4,5]

=cut

=method unique

The unique method returns an array reference consisting of the unique elements
in the array.

=signature unique

unique() : ArrayRef

=example-1 unique

  my $array = Data::Object::Array->new([1,1,1,1,2,3,1]);

  $array->unique; # [1,2,3]

=cut

=method unshift

The unshift method prepends the array by pushing the agruments onto it and
returns itself.

=signature unshift

unshift() : Any

=example-1 unshift

  my $array = Data::Object::Array->new([1..5]);

  $array->unshift(-2,-1,0); # [-2,-1,0,1,2,3,4,5]

=cut

=method values

The values method returns an array reference consisting of the elements in the
array. This method essentially copies the content of the array into a new
container.

=signature values

values() : ArrayRef

=example-1 values

  my $array = Data::Object::Array->new([1..5]);

  $array->values; # [1,2,3,4,5]

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
  ok $result->isa('Data::Object::Array');

  $result
});

$subs->example(-1, 'all', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'any', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'clear', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'count', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 5;

  $result
});

$subs->example(-1, 'defined', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'delete', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 3;

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

  $result
});

$subs->example(-1, 'first', 'method', fun($tryable) {
  ok my $result = $tryable->result;

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

  $result
});

$subs->example(-1, 'grep', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'gt', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'hash', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {0=>1,1=>2,2=>3,3=>4,4=>5};

  $result
});

$subs->example(-1, 'hashify', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'hashify', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'head', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 9;

  $result
});

$subs->example(-1, 'invert', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [5,4,3,2,1];

  $result
});

$subs->example(-1, 'iterator', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'join', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 12345;

  $result
});

$subs->example(-1, 'keyed', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {a=>1,b=>2,c=>3,d=>4};

  $result
});

$subs->example(-1, 'keys', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [0,1,2,3];

  $result
});

$subs->example(-1, 'last', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 5;

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
  is $result, 5;

  $result
});

$subs->example(-1, 'list', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  @$result
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
  is_deeply $result, [2,3,4,5,6];

  $result
});

$subs->example(-1, 'max', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 9;

  $result
});

$subs->example(-1, 'min', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'ne', 'method', fun($tryable) {
  $tryable->default(fun($error) {
    ok $error;
  });
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'none', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'nsort', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [1,2,3,4,5];

  $result
});

$subs->example(-1, 'one', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'pairs', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [[0,1],[1,2],[2,3],[3,4],[4,5]];

  $result
});

$subs->example(-1, 'pairs_array', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [[0,1],[1,2],[2,3],[3,4],[4,5]];

  $result
});

$subs->example(-1, 'pairs_hash', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {0=>1,1=>2,2=>3,3=>4,4=>5};

  $result
});

$subs->example(-1, 'part', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [[6, 7, 8, 9, 10], [1, 2, 3, 4, 5]];

  $result
});

$subs->example(-1, 'pop', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 5;

  $result
});

$subs->example(-1, 'push', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [1,2,3,4,5,6,7,8];

  $result
});

$subs->example(-1, 'random', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result;

  $result
});

$subs->example(-1, 'reverse', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [5,4,3,2,1];

  $result
});

$subs->example(-1, 'rnsort', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [5,4,3,2,1];

  $result
});

$subs->example(-1, 'rotate', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [2,3,4,5,1];

  $result
});

$subs->example(-1, 'rsort', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['d','c','b','a'];

  $result
});

$subs->example(-1, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 6;

  $result
});

$subs->example(-1, 'shift', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'size', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 5;

  $result
});

$subs->example(-1, 'slice', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, {2=>3, 4=>5};

  $result
});

$subs->example(-1, 'sort', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['a','b','c','d'];

  $result
});

$subs->example(-1, 'sum', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 15;

  $result
});

$subs->example(-1, 'tail', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [2,3,4,5];

  $result
});

$subs->example(-1, 'unique', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [1,2,3];

  $result
});

$subs->example(-1, 'unshift', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [-2,-1,0,1,2,3,4,5];

  $result
});

$subs->example(-1, 'values', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [1,2,3,4,5];

  $result
});

ok 1 and done_testing;
