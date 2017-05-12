use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'last';

use Scalar::Util 'refaddr';

subtest 'test the last method' => sub {
    my $array = Data::Object::Array->new([1..5]);

    my @argument = ();
    my $last = $array->last(@argument);

    isnt refaddr($array), refaddr($last);
    is $last, 5;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $last, 'Data::Object::Number';
};

ok 1 and done_testing;
