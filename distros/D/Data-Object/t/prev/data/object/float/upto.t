use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'upto';

use Scalar::Util 'refaddr';

subtest 'test the upto method' => sub {
    my $float = Data::Object::Float->new(1.25);
    my $upto = $float->upto(10);

    isnt refaddr($float), refaddr($upto);
    is_deeply $upto, [1,2,3,4,5,6,7,8,9,10];

    isa_ok $float, 'Data::Object::Float';
    isa_ok $upto, 'Data::Object::Array';
};

ok 1 and done_testing;
