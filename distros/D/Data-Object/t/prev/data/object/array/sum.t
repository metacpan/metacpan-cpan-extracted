use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'sum';

use Scalar::Util 'refaddr';

subtest 'test the sum method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $sum = $array->sum(@argument);

    isnt refaddr($array), refaddr($sum);
    is $sum, 15;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $sum, 'Data::Object::Number';
};

ok 1 and done_testing;
