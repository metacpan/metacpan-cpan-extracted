use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'mod';

use Scalar::Util 'refaddr';

subtest 'test the mod method' => sub {
    my $number = Data::Object::Number->new(12);
    my $mod = $number->mod(1);

    isnt refaddr($number), refaddr($mod);
    is $mod, 0;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $mod, 'Data::Object::Number';

    $mod = $number->mod(2);

    isnt refaddr($number), refaddr($mod);
    is $mod, 0;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $mod, 'Data::Object::Number';

    $mod = $number->mod(3);

    isnt refaddr($number), refaddr($mod);
    is $mod, 0;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $mod, 'Data::Object::Number';

    $mod = $number->mod(4);

    isnt refaddr($number), refaddr($mod);
    is $mod, 0;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $mod, 'Data::Object::Number';

    $mod = $number->mod(5);

    isnt refaddr($number), refaddr($mod);
    is $mod, 2;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $mod, 'Data::Object::Number';
};

ok 1 and done_testing;
