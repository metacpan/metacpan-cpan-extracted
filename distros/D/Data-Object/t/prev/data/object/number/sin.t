use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'sin';

use Scalar::Util 'refaddr';

subtest 'test the sin method' => sub {
    my $number = Data::Object::Number->new(12345);
    my $sin = $number->sin();

    isnt refaddr($number), refaddr($sin);
    like $sin, qr/-0.99377/;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $sin, 'Data::Object::Float';
};

ok 1 and done_testing;
