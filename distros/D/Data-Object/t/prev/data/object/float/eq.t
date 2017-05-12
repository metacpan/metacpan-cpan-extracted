use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'eq';

use Scalar::Util 'refaddr';

subtest 'test the eq method' => sub {
    my $float = Data::Object::Float->new(98765.98765);
    my $eq = $float->eq(98765.98765);

    isnt refaddr($float), refaddr($eq);
    is $eq, 1;

    $eq = $float->eq('98765.98765');

    isnt refaddr($float), refaddr($eq);
    is $eq, 1;

    $eq = $float->eq(987650);

    isnt refaddr($float), refaddr($eq);
    is $eq, 0;

    $eq = $float->eq('098765.98765');

    isnt refaddr($float), refaddr($eq);
    is $eq, 1;

    isa_ok $float, 'Data::Object::Float';
    isa_ok $eq, 'Data::Object::Number';
};

ok 1 and done_testing;
