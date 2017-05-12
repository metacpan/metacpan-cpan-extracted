use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'hex';

use Scalar::Util 'refaddr';

subtest 'test the hex method' => sub {
    my $number = Data::Object::Number->new(175);
    my $hex = $number->hex();

    isnt refaddr($number), refaddr($hex);
    is $hex, '0xaf';

    isa_ok $number, 'Data::Object::Number';
    isa_ok $hex, 'Data::Object::String';
};

ok 1 and done_testing;
