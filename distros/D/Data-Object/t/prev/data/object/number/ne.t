use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'ne';

use Scalar::Util 'refaddr';

subtest 'test the ne method' => sub {
    my $number = Data::Object::Number->new(1);
    my $ne = $number->ne(2);

    isnt refaddr($number), refaddr($ne);
    is $ne, 1;

    $ne = $number->ne(1);

    isnt refaddr($number), refaddr($ne);
    is $ne, 0;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $ne, 'Data::Object::Number';
};

ok 1 and done_testing;
