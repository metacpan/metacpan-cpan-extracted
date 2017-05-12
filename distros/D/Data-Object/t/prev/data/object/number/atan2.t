use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'atan2';

use Scalar::Util 'refaddr';

subtest 'test the atan2 method' => sub {
    my $number = Data::Object::Number->new(1);
    my $atan2 = $number->atan2(1);

    isnt refaddr($number), refaddr($atan2);
    like $atan2, qr/0.78539/;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $atan2, 'Data::Object::Float';
};

ok 1 and done_testing;
