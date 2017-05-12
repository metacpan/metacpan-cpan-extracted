use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'le';

use Scalar::Util 'refaddr';

subtest 'test the le method' => sub {
    my $number = Data::Object::Number->new(1);
    my $le = $number->le(1);

    isnt refaddr($number), refaddr($le);
    is $le, 1;

    $le = $number->le(2);

    isnt refaddr($number), refaddr($le);
    is $le, 1;

    $le = $number->le(0);

    isnt refaddr($number), refaddr($le);
    is $le, 0;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $le, 'Data::Object::Number';
};

ok 1 and done_testing;
