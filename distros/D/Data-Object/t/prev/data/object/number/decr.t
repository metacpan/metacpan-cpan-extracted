use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'decr';

use Scalar::Util 'refaddr';

subtest 'test the decr method' => sub {
    my $number = Data::Object::Number->new(123456789);
    my $decr = $number->decr();

    isnt refaddr($number), refaddr($decr);
    is $decr, 123456788;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $decr, 'Data::Object::Number';
};

ok 1 and done_testing;
