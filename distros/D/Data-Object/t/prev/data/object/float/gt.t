use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'gt';

use Scalar::Util 'refaddr';

subtest 'test the gt method' => sub {
    my $float = Data::Object::Float->new(1.99999);
    my $gt = $float->gt(0);

    isnt refaddr($float), refaddr($gt);
    is $gt, 1;

    $gt = $float->gt(1.99999);

    isnt refaddr($float), refaddr($gt);
    is $gt, 0;

    isa_ok $float, 'Data::Object::Float';
    isa_ok $gt, 'Data::Object::Number';
};

ok 1 and done_testing;
