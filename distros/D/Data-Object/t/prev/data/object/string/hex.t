use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'hex';

use Scalar::Util 'refaddr';

subtest 'test the hex method' => sub {
    my $string = Data::Object::String->new('0xaf');
    my $hexed = $string->hex;
    is "$$hexed", "175"; # 175
    isa_ok $string, 'Data::Object::String';
    isa_ok $hexed, 'Data::Object::Number';
};

ok 1 and done_testing;
