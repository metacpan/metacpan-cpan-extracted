use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'upto';

use Scalar::Util 'refaddr';

subtest 'test the upto method' => sub {
    my $integer = Data::Object::Number->new(0);
    my $upto = $integer->upto(10);

    isnt refaddr($integer), refaddr($upto);
    is_deeply $upto, [0,1,2,3,4,5,6,7,8,9,10];

    isa_ok $integer, 'Data::Object::Number';
    isa_ok $upto, 'Data::Object::Array';
};

ok 1 and done_testing;
