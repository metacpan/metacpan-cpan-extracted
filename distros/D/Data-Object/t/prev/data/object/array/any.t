use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'any';

use Scalar::Util 'refaddr';

subtest 'test the any method - natural' => sub {
    my $array = Data::Object::Array->new([2..5]);
    my $any = $array->any(sub { shift > 5 });

    isnt refaddr($array), refaddr($any);
    is $any, 0;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $any, 'Data::Object::Number';
};

subtest 'test the any method - codified' => sub {
    my $array = Data::Object::Array->new([2..5]);
    my $any = $array->any('$a > 5 ');

    isnt refaddr($array), refaddr($any);
    is $any, 0;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $any, 'Data::Object::Number';
};

subtest 'test the any method - codified with refs' => sub {
    my $array = Data::Object::Array->new([2..5]);
    my $any = $array->any('$value > 5 ');

    isnt refaddr($array), refaddr($any);
    is $any, 0;

    isa_ok $array, 'Data::Object::Array';
    isa_ok $any, 'Data::Object::Number';
};

ok 1 and done_testing;
