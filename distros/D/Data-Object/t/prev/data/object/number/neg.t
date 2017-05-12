use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'neg';

use Scalar::Util 'refaddr';

subtest 'test the neg method' => sub {
    my $number = Data::Object::Number->new(12345);
    my $neg = $number->neg();

    isnt refaddr($number), refaddr($neg);
    is $neg, -12345;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $neg, 'Data::Object::Integer';
};

ok 1 and done_testing;
