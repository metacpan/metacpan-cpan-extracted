use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'pow';

use Scalar::Util 'refaddr';

subtest 'test the pow method' => sub {
    my $number = Data::Object::Number->new(12345);
    my $pow = $number->pow(3);

    isnt refaddr($number), refaddr($pow);
    is $pow, 1881365963625;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $pow, 'Data::Object::Number';
};

ok 1 and done_testing;
