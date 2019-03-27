use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

unfold

=usage

  # given {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}

  $hash->unfold; # {3=>[4,5,6],7,{8,8,9,9}}

=description

The unfold method processes previously folded hash references and returns an
unfolded hash reference where the keys, which are paths (using dot-notation
where the segments correspond to nested hash keys and array indices), are used
to created nested hash and/or array references. This method returns a
L<Data::Object::Hash> object.

=signature

unfold() : HashObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9});

is_deeply $data->unfold(), {3=>[4,5,6],7,{8,8,9,9}};

ok 1 and done_testing;
