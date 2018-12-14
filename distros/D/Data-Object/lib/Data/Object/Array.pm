# ABSTRACT: Array Object for Perl 5
package Data::Object::Array;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Class;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

with 'Data::Object::Role::Array';

our $VERSION = '0.60'; # VERSION

method new ($class: @args) {

  my $arg  = @args > 1 ? [@args] : $args[0];
  my $role = 'Data::Object::Role::Type';

  $arg = $arg->data
    if Scalar::Util::blessed($arg)
    and $arg->can('does')
    and $arg->does($role);

  Data::Object::throw('Type Instantiation Error: Not an ArrayRef')
    unless ref($arg) eq 'ARRAY';

  return bless $arg, $class;

}

our @METHODS = @{__PACKAGE__->methods};

my $exclude = qr/^data|detract|new$/;

around [grep { !/$exclude/ } @METHODS] => fun($orig, $self, @args) {

  my $results = $self->$orig(@args);

  return Data::Object::deduce_deep($results);

};

around 'list' => fun($orig, $self, @args) {

  my $results = $self->$orig(@args);

  return wantarray ? (@$results) : $results;

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Array - Array Object for Perl 5

=head1 VERSION

version 0.60

=head1 SYNOPSIS

  use Data::Object::Array;

  my $array = Data::Object::Array->new([1..9]);

=head1 DESCRIPTION

Data::Object::Array provides routines for operating on Perl 5 array
references. Array methods work on array references. Users of these methods
should be aware of the methods that modify the array reference itself as opposed
to returning a new array reference. Unless stated, it may be safe to assume that
the following methods copy, modify and return new array references based on
their function.

=head1 COMPOSITION

This package inherits all functionality from the L<Data::Object::Role::Array>
role and implements proxy methods as documented herewith.

=head1 CODIFICATION

Certain methods provided by the this module support codification, a process
which converts a string argument into a code reference which can be used to
supply a callback to the method called. A codified string can access its
arguments by using variable names which correspond to letters in the alphabet
which represent the position in the argument list. For example:

  $array->example('$a + $b * $c', 100);

  # if the example method does not supply any arguments automatically then
  # the variable $a would be assigned the user-supplied value of 100,
  # however, if the example method supplies two arguments automatically then
  # those arugments would be assigned to the variables $a and $b whereas $c
  # would be assigned the user-supplied value of 100

  # e.g.

  $array->each('the value at $index is $value');

  # or

  $array->each_n_values(4, 'the value at $index0 is $value0');

  # etc

Any place a codified string is accepted, a coderef or L<Data::Object::Code>
object is also valid. Arguments are passed through the usual C<@_> list.

=head1 METHODS

=head2 all

  # given [2..5]

  $array->all('$value > 1'); # 1; true
  $array->all('$value > 3'); # 0; false

The all method returns true if all of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=head2 any

  # given [2..5]

  $array->any('$value > 5'); # 0; false
  $array->any('$value > 3'); # 1; true

The any method returns true if any of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=head2 clear

  # given ['a'..'g']

  $array->clear; # []

The clear method is an alias to the empty method. This method returns a
L<Data::Object::Undef> object. This method is an alias to the empty method.
Note: This method modifies the array.

=head2 count

  # given [1..5]

  $array->count; # 5

The count method returns the number of elements within the array. This method
returns a L<Data::Object::Number> object.

=head2 data

  # given $array

  $array->data; # original value

The data method returns the original and underlying value contained by the
object. This method is an alias to the detract method.

=head2 defined

  # given [1,2,undef,4,5]

  $array->defined(2); # 0; false
  $array->defined(1); # 1; true

The defined method returns true if the element within the array at the index
specified by the argument meets the criteria for being defined, otherwise it
returns false. This method returns a L<Data::Object::Number> object.

=head2 delete

  # given [1..5]

  $array->delete(2); # 3

The delete method returns the value of the element within the array at the
index specified by the argument after removing it from the array. This method
returns a data type object to be determined after execution. Note: This method
modifies the array.

=head2 detract

  # given $array

  $array->detract; # original value

The detract method returns the original and underlying value contained by the
object.

=head2 dump

  # given [1..5]

  $array->dump; # '[1,2,3,4,5]'

The dump method returns returns a string representation of the object.
This method returns a L<Data::Object::String> object.

=head2 each

  # given ['a'..'g']

  $array->each(sub{
      my $index = shift; # 0
      my $value = shift; # a
      ...
  });

The each method iterates over each element in the array, executing the code
reference supplied in the argument, passing the routine the index and value at
the current position in the loop. This method supports codification, i.e, takes
an argument which can be a codifiable string, a code reference, or a code data
type object. This method returns a L<Data::Object::Array> object.

=head2 each_key

  # given ['a'..'g']

  $array->each_key(sub{
      my $index = shift; # 0
      ...
  });

The each_key method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the index at the
current position in the loop. This method supports codification, i.e, takes an
argument which can be a codifiable string, a code reference, or a code data type
object. This method returns a L<Data::Object::Array> object.

=head2 each_n_values

  # given ['a'..'g']

  $array->each_n_values(4, sub{
      my $value_1 = shift; # a
      my $value_2 = shift; # b
      my $value_3 = shift; # c
      my $value_4 = shift; # d
      ...
  });

The each_n_values method iterates over each element in the array, executing
the code reference supplied in the argument, passing the routine the next n
values until all values have been seen. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Array> object.

=head2 each_value

  # given ['a'..'g']

  $array->each_value(sub{
      my $value = shift; # a
      ...
  });

The each_value method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop. This method supports codification, i.e, takes an
argument which can be a codifiable string, a code reference, or a code data type
object. This method returns a L<Data::Object::Array> object.

=head2 empty

  # given ['a'..'g']

  $array->empty; # []

The empty method drops all elements from the array. This method returns a
L<Data::Object::Array> object. Note: This method modifies the array.

=head2 eq

  # given $array

  $array->eq; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 exists

  # given [1,2,3,4,5]

  $array->exists(5); # 0; false
  $array->exists(0); # 1; true

The exists method returns true if the element within the array at the index
specified by the argument exists, otherwise it returns false. This method
returns a L<Data::Object::Number> object.

=head2 first

  # given [1..5]

  $array->first; # 1

The first method returns the value of the first element in the array. This
method returns a data type object to be determined after execution.

=head2 ge

  # given $array

  $array->ge; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 get

  # given [1..5]

  $array->get(0); # 1;

The get method returns the value of the element in the array at the index
specified by the argument. This method returns a data type object to be
determined after execution.

=head2 grep

  # given [1..5]

  $array->grep(sub{
      shift >= 3
  });

  # [3,4,5]

The grep method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing
the elements for which the argument evaluated true. This method supports
codification, i.e, takes an argument which can be a codifiable string, a code
reference, or a code data type object. This method returns a
L<Data::Object::Array> object.

=head2 gt

  # given $array

  $array->gt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 hash

  # given [1..5]

  $array->hash; # {0=>1,1=>2,2=>3,3=>4,4=>5}

The hash method returns a hash reference where each key and value pairs
corresponds to the index and value of each element in the array. This method
returns a L<Data::Object::Hash> object.

=head2 hashify

  # given [1..5]

  $array->hashify; # {1=>1,2=>1,3=>1,4=>1,5=>1}
  $array->hashify(sub { shift % 2 }); # {1=>1,2=>0,3=>1,4=>0,5=>1}

The hashify method returns a hash reference where the elements of array become
the hash keys and the corresponding values are assigned a value of 1. This
method supports codification, i.e, takes an argument which can be a codifiable
string, a code reference, or a code data type object. Note, undefined elements
will be dropped. This method returns a L<Data::Object::Hash> object.

=head2 head

  # given [9,8,7,6,5]

  my $head = $array->head; # 9

The head method returns the value of the first element in the array. This
method returns a data type object to be determined after execution.

=head2 invert

  # given [1..5]

  $array->invert; # [5,4,3,2,1]

The invert method returns an array reference containing the elements in the
array in reverse order. This method returns a L<Data::Object::Array> object.

=head2 iterator

  # given [1..5]

  my $iterator = $array->iterator;
  while (my $value = $iterator->next) {
      say $value; # 1
  }

The iterator method returns a code reference which can be used to iterate over
the array. Each time the iterator is executed it will return the next element
in the array until all elements have been seen, at which point the iterator
will return an undefined value. This method returns a L<Data::Object::Code>
object.

=head2 join

  # given [1..5]

  $array->join; # 12345
  $array->join(', '); # 1, 2, 3, 4, 5

The join method returns a string consisting of all the elements in the array
joined by the join-string specified by the argument. Note: If the argument is
omitted, an empty string will be used as the join-string. This method returns a
L<Data::Object::String> object.

=head2 keyed

  # given [1..5]

  $array->keyed('a'..'d'); # {a=>1,b=>2,c=>3,d=>4}

The keyed method returns a hash reference where the arguments become the keys,
and the elements of the array become the values. This method returns a
L<Data::Object::Hash> object.

=head2 keys

  # given ['a'..'d']

  $array->keys; # [0,1,2,3]

The keys method returns an array reference consisting of the indicies of the
array. This method returns a L<Data::Object::Array> object.

=head2 last

  # given [1..5]

  $array->last; # 5

The last method returns the value of the last element in the array. This method
returns a data type object to be determined after execution.

=head2 le

  # given $array

  $array->le; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 length

  # given [1..5]

  $array->length; # 5

The length method returns the number of elements in the array. This method
returns a L<Data::Object::Number> object.

=head2 list

  # given $array

  my $list = $array->list;

The list method returns a shallow copy of the underlying array reference as an
array reference. This method return a L<Data::Object::Array> object.

=head2 lt

  # given $array

  $array->lt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 map

  # given [1..5]

  $array->map(sub{
      shift + 1
  });

  # [2,3,4,5,6]

The map method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing
the elements for which the argument returns a value or non-empty list. This
method returns a L<Data::Object::Array> object.

=head2 max

  # given [8,9,1,2,3,4,5]

  $array->max; # 9

The max method returns the element in the array with the highest numerical
value. All non-numerical element are skipped during the evaluation process. This
method returns a L<Data::Object::Number> object.

=head2 methods

  # given $array

  $array->methods;

The methods method returns the list of methods attached to object. This method
returns a L<Data::Object::Array> object.

=head2 min

  # given [8,9,1,2,3,4,5]

  $array->min; # 1

The min method returns the element in the array with the lowest numerical
value. All non-numerical element are skipped during the evaluation process. This
method returns a L<Data::Object::Number> object.

=head2 ne

  # given $array

  $array->ne; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 new

  # given 1..9

  my $array = Data::Object::Array->new(1..9);
  my $array = Data::Object::Array->new([1..9]);

The new method expects a list or array reference and returns a new class
instance.

=head2 none

  # given [2..5]

  $array->none('$value <= 1'); # 1; true
  $array->none('$value <= 2'); # 0; false

The none method returns true if none of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=head2 nsort

  # given [5,4,3,2,1]

  $array->nsort; # [1,2,3,4,5]

The nsort method returns an array reference containing the values in the array
sorted numerically. This method returns a L<Data::Object::Array> object.

=head2 one

  # given [2..5]

  $array->one('$value == 5'); # 1; true
  $array->one('$value == 6'); # 0; false

The one method returns true if only one of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=head2 pairs

  # given [1..5]

  $array->pairs; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

The pairs method is an alias to the pairs_array method. This method returns a
L<Data::Object::Array> object. This method is an alias to the pairs_array
method.

=head2 pairs_array

  # given [1..5]

  $array->pairs_array; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

The pairs_array method returns an array reference consisting of array references
where each sub-array reference has two elements corresponding to the index and
value of each element in the array. This method returns a L<Data::Object::Array>
object.

=head2 pairs_hash

  # given [1..5]

  $array->pairs_hash; # {0=>1,1=>2,2=>3,3=>4,4=>5}

The pairs_hash method returns a hash reference where each key and value pairs
corresponds to the index and value of each element in the array. This method
returns a L<Data::Object::Hash> object.

=head2 part

  # given [1..10]

  $array->part(sub { shift > 5 }); # [[6, 7, 8, 9, 10], [1, 2, 3, 4, 5]]

The part method iterates over each element in the array, executing the
code reference supplied in the argument, using the result of the code reference
to partition to array into two distinct array references. This method returns
an array reference containing exactly two array references. This method supports
codification, i.e, takes an argument which can be a codifiable string, a code
reference, or a code data type object. This method returns a
L<Data::Object::Array> object.

=head2 pop

  # given [1..5]

  $array->pop; # 5

The pop method returns the last element of the array shortening it by one. Note,
this method modifies the array. This method returns a data type object to be
determined after execution. Note: This method modifies the array.

=head2 print

  # given [1..5]

  $array->print; # '[1,2,3,4,5]'

The print method outputs the value represented by the object to STDOUT and
returns true. This method returns a L<Data::Object::Number> object.

=head2 push

  # given [1..5]

  $array->push(6,7,8); # [1,2,3,4,5,6,7,8]

The push method appends the array by pushing the agruments onto it and returns
itself. This method returns a data type object to be determined after execution.
Note: This method modifies the array.

=head2 random

  # given [1..5]

  $array->random; # 4

The random method returns a random element from the array. This method returns a
data type object to be determined after execution.

=head2 reverse

  # given [1..5]

  $array->reverse; # [5,4,3,2,1]

The reverse method returns an array reference containing the elements in the
array in reverse order. This method returns a L<Data::Object::Array> object.

=head2 rnsort

  # given [5,4,3,2,1]

  $array->rnsort; # [5,4,3,2,1]

The rnsort method returns an array reference containing the values in the
array sorted numerically in reverse. This method returns a
L<Data::Object::Array> object.

=head2 roles

  # given $array

  $array->roles;

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=head2 rotate

  # given [1..5]

  $array->rotate; # [2,3,4,5,1]
  $array->rotate; # [3,4,5,1,2]
  $array->rotate; # [4,5,1,2,3]

The rotate method rotates the elements in the array such that first elements
becomes the last element and the second element becomes the first element each
time this method is called. This method returns a L<Data::Object::Array> object.
Note: This method modifies the array.

=head2 rsort

  # given ['a'..'d']

  $array->rsort; # ['d','c','b','a']

The rsort method returns an array reference containing the values in the array
sorted alphanumerically in reverse. This method returns a L<Data::Object::Array>
object.

=head2 say

  # given [1..5]

  $array->say; # '[1,2,3,4,5]\n'

The say method outputs the value represented by the object appended with a
newline to STDOUT and returns true. This method returns a L<Data::Object::Number>
object.

=head2 set

  # given [1..5]

  $array->set(4,6); # [1,2,3,4,6]

The set method returns the value of the element in the array at the index
specified by the argument after updating it to the value of the second argument.
This method returns a data type object to be determined after execution. Note:
This method modifies the array.

=head2 shift

  # given [1..5]

  $array->shift; # 1

The shift method returns the first element of the array shortening it by one.
This method returns a data type object to be determined after execution. Note:
This method modifies the array.

=head2 size

  # given [1..5]

  $array->size; # 5

The size method is an alias to the length method. This method returns a
L<Data::Object::Number> object. This method is an alias to the length method.

=head2 slice

  # given [1..5]

  $array->slice(2,4); # [3,5]

The slice method returns an array reference containing the elements in the
array at the index(es) specified in the arguments. This method returns a
L<Data::Object::Array> object.

=head2 sort

  # given ['d','c','b','a']

  $array->sort; # ['a','b','c','d']

The sort method returns an array reference containing the values in the array
sorted alphanumerically. This method returns a L<Data::Object::Array> object.

=head2 sum

  # given [1..5]

  $array->sum; # 15

The sum method returns the sum of all values for all numerical elements in the
array. All non-numerical element are skipped during the evaluation process. This
method returns a L<Data::Object::Number> object.

=head2 tail

  # given [1..5]

  $array->tail; # [2,3,4,5]

The tail method returns an array reference containing the second through the
last elements in the array omitting the first. This method returns a
L<Data::Object::Array> object.

=head2 throw

  # given $array

  $array->throw;

The throw method terminates the program using the core die keyword, passing the
object to the L<Data::Object::Exception> class as the named parameter C<object>.
If captured this method returns a L<Data::Object::Exception> object.

=head2 type

  # given $array

  $array->type; # ARRAY

The type method returns a string representing the internal data type object name.
This method returns a L<Data::Object::String> object.

=head2 unique

  # given [1,1,1,1,2,3,1]

  $array->unique; # [1,2,3]

The unique method returns an array reference consisting of the unique elements
in the array. This method returns a L<Data::Object::Array> object.

=head2 unshift

  # given [1..5]

  $array->unshift(-2,-1,0); # [-2,-1,0,1,2,3,4,5]

The unshift method prepends the array by pushing the agruments onto it and
returns itself. This method returns a data type object to be determined after
execution. Note: This method modifies the array.

=head2 values

  # given [1..5]

  $array->values; # [1,2,3,4,5]

The values method returns an array reference consisting of the elements in the
array. This method essentially copies the content of the array into a new
container. This method returns a L<Data::Object::Array> object.

=head1 ROLES

This package is comprised of the following roles.

=over 4

=item *

L<Data::Object::Role::Collection>

=item *

L<Data::Object::Role::Comparison>

=item *

L<Data::Object::Role::Defined>

=item *

L<Data::Object::Role::Detract>

=item *

L<Data::Object::Role::Dumper>

=item *

L<Data::Object::Role::Item>

=item *

L<Data::Object::Role::List>

=item *

L<Data::Object::Role::Output>

=item *

L<Data::Object::Role::Throwable>

=item *

L<Data::Object::Role::Type>

=back

=head1 SEE ALSO

=over 4

=item *

L<Data::Object::Array>

=item *

L<Data::Object::Class>

=item *

L<Data::Object::Class::Syntax>

=item *

L<Data::Object::Code>

=item *

L<Data::Object::Float>

=item *

L<Data::Object::Hash>

=item *

L<Data::Object::Integer>

=item *

L<Data::Object::Number>

=item *

L<Data::Object::Role>

=item *

L<Data::Object::Role::Syntax>

=item *

L<Data::Object::Regexp>

=item *

L<Data::Object::Scalar>

=item *

L<Data::Object::String>

=item *

L<Data::Object::Undef>

=item *

L<Data::Object::Universal>

=item *

L<Data::Object::Autobox>

=item *

L<Data::Object::Immutable>

=item *

L<Data::Object::Library>

=item *

L<Data::Object::Prototype>

=item *

L<Data::Object::Signatures>

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
