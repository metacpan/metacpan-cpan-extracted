use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'unique';

use Scalar::Util 'refaddr';

subtest 'test the unique method' => sub {
    my $array = Data::Object::Array->new([1,1,1,1,2,3,1]);

    my @argument = ();
    my $unique = $array->unique(@argument);

    isnt refaddr($array), refaddr($unique);
    is_deeply $unique, [1,2,3];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $unique, 'Data::Object::Array';
};

ok 1 and done_testing;
