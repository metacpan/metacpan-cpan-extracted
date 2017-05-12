use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'length';

use Scalar::Util 'refaddr';

subtest 'test the length method' => sub {
    my $string = Data::Object::String->new('longggggg');
    my $answer = $string->length;
    is $$answer, 9; # 9

    isa_ok $string, 'Data::Object::String';
    isa_ok $answer, 'Data::Object::Number';
};

ok 1 and done_testing;
