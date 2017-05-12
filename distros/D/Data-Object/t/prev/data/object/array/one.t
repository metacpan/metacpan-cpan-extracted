use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'one';

use Scalar::Util 'refaddr';

subtest 'test the one method' => sub {
    my $array = Data::Object::Array->new([2..5,7,7]);

    my @argument = (sub { shift() == 5 });
    my $one = $array->one(@argument);

    isnt refaddr($array), refaddr($one);
    is $one, 1;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $one, 'Data::Object::Number';
};

ok 1 and done_testing;
