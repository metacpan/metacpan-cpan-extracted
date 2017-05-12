use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'gt';

use Scalar::Util 'refaddr';

subtest 'test the gt method' => sub {
    my $integer = Data::Object::Number->new(1);
    my $gt = $integer->gt(0);

    isnt refaddr($integer), refaddr($gt);
    is $gt, 1;

    $gt = $integer->gt(1);

    isnt refaddr($integer), refaddr($gt);
    is $gt, 0;

    isa_ok $integer, 'Data::Object::Number';
    isa_ok $gt, 'Data::Object::Number';
};

ok 1 and done_testing;
