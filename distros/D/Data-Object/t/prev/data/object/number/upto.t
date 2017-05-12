use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'upto';

use Scalar::Util 'refaddr';

subtest 'test the upto method' => sub {
    my $number = Data::Object::Number->new(0);
    my $upto = $number->upto(10);

    isnt refaddr($number), refaddr($upto);
    is_deeply $upto, [0,1,2,3,4,5,6,7,8,9,10];

    isa_ok $number, 'Data::Object::Number';
    isa_ok $upto, 'Data::Object::Array';
};

ok 1 and done_testing;
