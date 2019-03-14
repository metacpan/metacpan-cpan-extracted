use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

fold

=usage

  # given {3,[4,5,6],7,{8,8,9,9}}

  $hash->fold; # {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}

=description

The fold method returns a single-level hash reference consisting of key/value
pairs whose keys are paths (using dot-notation where the segments correspond to
nested hash keys and array indices) mapped to the nested values. This method
returns a L<Data::Object::Hash> object.

=signature

fold(Str $arg1, HashRef $arg2, HashRef $arg3) : HashObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({3,[4,5,6],7,{8,8,9,9}});

is_deeply $data->fold(), {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9};

ok 1 and done_testing;
