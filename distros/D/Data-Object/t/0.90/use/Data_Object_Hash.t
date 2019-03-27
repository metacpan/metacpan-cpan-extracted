use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Hash

=abstract

Data-Object Hash Class

=synopsis

  use Data::Object::Hash;

  my $hash = Data::Object::Hash->new({1..4});

=description

Data::Object::Hash provides routines for operating on Perl 5 hash
references. Hash methods work on hash references. Users of these methods should
be aware of the methods that modify the array reference itself as opposed to
returning a new array reference. Unless stated, it may be safe to assume that
the following methods copy, modify and return new hash references based on their
function.

=composition

This package inherits all functionality from the L<Data::Object::Role::Hash>
role and implements proxy methods as documented herewith.

=codification

Certain methods provided by the this module support codification, a process
which converts a string argument into a code reference which can be used to
supply a callback to the method called. A codified string can access its
arguments by using variable names which correspond to letters in the alphabet
which represent the position in the argument list. For example:

  $hash->example('$a + $b * $c', 100);

  # if the example method does not supply any arguments automatically then
  # the variable $a would be assigned the user-supplied value of 100,
  # however, if the example method supplies two arguments automatically then
  # those arugments would be assigned to the variables $a and $b whereas $c
  # would be assigned the user-supplied value of 100

  # e.g.

  $hash->each('the value at $key is $value');

  # or

  $hash->each_n_values(4, 'the value at $key0 is $value0');

  # etc

Any place a codified string is accepted, a coderef or L<Data::Object::Code>
object is also valid. Arguments are passed through the usual C<@_> list.

=cut

use_ok "Data::Object::Hash";

ok 1 and done_testing;
