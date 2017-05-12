use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'lt';

use Scalar::Util 'refaddr';

subtest 'test the lt method' => sub {
    my $number = Data::Object::Number->new(1);
    my $lt = $number->lt(2);

    isnt refaddr($number), refaddr($lt);
    is $lt, 1;

    $lt = $number->lt(1);

    isnt refaddr($number), refaddr($lt);
    is $lt, 0;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $lt, 'Data::Object::Number';
};

ok 1 and done_testing;
