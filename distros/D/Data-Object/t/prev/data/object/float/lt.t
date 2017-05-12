use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'lt';

use Scalar::Util 'refaddr';

subtest 'test the lt method' => sub {
    my $float = Data::Object::Float->new(1.445);
    my $lt = $float->lt(2);

    isnt refaddr($float), refaddr($lt);
    is $lt, 1;

    $lt = $float->lt(1.445);

    isnt refaddr($float), refaddr($lt);
    is $lt, 0;

    isa_ok $float, 'Data::Object::Float';
    isa_ok $lt, 'Data::Object::Number';
};

ok 1 and done_testing;
