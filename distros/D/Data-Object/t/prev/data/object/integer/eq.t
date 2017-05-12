use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'eq';

use Scalar::Util 'refaddr';

subtest 'test the eq method' => sub {
    my $integer = Data::Object::Number->new(98765);
    my $eq = $integer->eq(98765);

    isnt refaddr($integer), refaddr($eq);
    is $eq, 1;

    $eq = $integer->eq('98765');

    isnt refaddr($integer), refaddr($eq);
    is $eq, 1;

    $eq = $integer->eq(987650);

    isnt refaddr($integer), refaddr($eq);
    is $eq, 0;

    $eq = $integer->eq('098765');

    isnt refaddr($integer), refaddr($eq);
    is $eq, 1;

    isa_ok $integer, 'Data::Object::Number';
    isa_ok $eq, 'Data::Object::Number';
};

ok 1 and done_testing;
