use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'eq';

use Scalar::Util 'refaddr';

subtest 'test the eq method' => sub {
    my $number = Data::Object::Number->new(98765);
    my $eq = $number->eq(98765);

    isnt refaddr($number), refaddr($eq);
    is $eq, 1;

    $eq = $number->eq('98765');

    isnt refaddr($number), refaddr($eq);
    is $eq, 1;

    $eq = $number->eq(987650);

    isnt refaddr($number), refaddr($eq);
    is $eq, 0;

    $eq = $number->eq('098765');

    isnt refaddr($number), refaddr($eq);
    is $eq, 1;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $eq, 'Data::Object::Number';
};

ok 1 and done_testing;
