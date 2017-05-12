use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'cos';

use Scalar::Util 'refaddr';

subtest 'test the cos method' => sub {
    my $number = Data::Object::Number->new(12);
    my $cos = $number->cos();

    isnt refaddr($number), refaddr($cos);
    like $cos, qr/0.84385/;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $cos, 'Data::Object::Float';
};

ok 1 and done_testing;
