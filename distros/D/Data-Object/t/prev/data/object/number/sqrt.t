use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'sqrt';

use Scalar::Util 'refaddr';

subtest 'test the sqrt method' => sub {
    my $number = Data::Object::Number->new(12345);
    my $sqrt = $number->sqrt();

    isnt refaddr($number), refaddr($sqrt);
    like $sqrt, qr/111.10805/;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $sqrt, 'Data::Object::Float';
};

ok 1 and done_testing;
