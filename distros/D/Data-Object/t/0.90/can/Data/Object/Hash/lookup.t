use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lookup

=usage

  # given {1..3,{4,{5,6,7,{8,9,10,11}}}}

  $hash->lookup('3.4.7'); # {8=>9,10=>11}
  $hash->lookup('3.4'); # {5=>6,7=>{8=>9,10=>11}}
  $hash->lookup(1); # 2

=description

The lookup method returns the value of the element in the hash whose key
corresponds to the key specified in the argument. The key can be a string which
references (using dot-notation) nested keys within the hash. This method will
return undefined if the value is undef or the location expressed in the argument
can not be resolved. Please note, keys containing dots (periods) are not
handled. This method returns a data type object to be determined after
execution.

=signature

lookup(Str $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..3,{4,{5,6,7,{8,9,10,11}}}});

is_deeply $data->lookup('3.4.7'), {8=>9,10=>11};

is_deeply $data->lookup('3.4'), {5=>6,7=>{8=>9,10=>11}};

is_deeply $data->lookup(1), 2;

ok 1 and done_testing;
