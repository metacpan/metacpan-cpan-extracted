use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

keyed

=usage

  # given [1..5]

  $array->keyed('a'..'d'); # {a=>1,b=>2,c=>3,d=>4}

=description

The keyed method returns a hash reference where the arguments become the keys,
and the elements of the array become the values. This method returns a
L<Data::Object::Hash> object.

=signature

keyed(Str $arg1) : HashObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->keyed('a'..'d'), {a=>1,b=>2,c=>3,d=>4};

ok 1 and done_testing;
