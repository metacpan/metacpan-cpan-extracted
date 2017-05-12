use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'lt';

use Scalar::Util 'refaddr';

subtest 'test the lt method' => sub {
    my $integer = Data::Object::Number->new(1);
    my $lt = $integer->lt(2);

    isnt refaddr($integer), refaddr($lt);
    is $lt, 1;

    $lt = $integer->lt(1);

    isnt refaddr($integer), refaddr($lt);
    is $lt, 0;

    isa_ok $integer, 'Data::Object::Number';
    isa_ok $lt, 'Data::Object::Number';
};

ok 1 and done_testing;
