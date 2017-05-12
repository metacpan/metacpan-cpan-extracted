use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'incr';

use Scalar::Util 'refaddr';

subtest 'test the incr method' => sub {
    my $number = Data::Object::Number->new(123456789);
    my $incr = $number->incr();

    isnt refaddr($number), refaddr($incr);
    is $incr, 123456790;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $incr, 'Data::Object::Number';
};

ok 1 and done_testing;
