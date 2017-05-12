use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'int';

use Scalar::Util 'refaddr';

subtest 'test the int method' => sub {
    my $number = Data::Object::Number->new(12.5);
    my $int = $number->int();

    isnt refaddr($number), refaddr($int);
    is $int, 12;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $int, 'Data::Object::Number';
};

ok 1 and done_testing;
