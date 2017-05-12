use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'gt';

use Scalar::Util 'refaddr';

subtest 'test the gt method' => sub {
    my $number = Data::Object::Number->new(1);
    my $gt = $number->gt(0);

    isnt refaddr($number), refaddr($gt);
    is $gt, 1;

    $gt = $number->gt(1);

    isnt refaddr($number), refaddr($gt);
    is $gt, 0;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $gt, 'Data::Object::Number';
};

ok 1 and done_testing;
