use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'exp';

use Scalar::Util 'refaddr';

subtest 'test the exp method' => sub {
    my $number = Data::Object::Number->new(1);
    my $exp = $number->exp();

    isnt refaddr($number), refaddr($exp);
    like $exp, qr/2.71828/;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $exp, 'Data::Object::Float';
};

ok 1 and done_testing;
