use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'join';

use Scalar::Util 'refaddr';

subtest 'test the join method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $join = $array->join(@argument);

    isnt refaddr($array), refaddr($join);
    is $join, 12345;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $join, 'Data::Object::Number';
};

ok 1 and done_testing;
