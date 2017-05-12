use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'ge';

use Scalar::Util 'refaddr';

subtest 'test the ge method' => sub {
    my $integer = Data::Object::Number->new(1);
    my $ge = $integer->ge(0);

    isnt refaddr($integer), refaddr($ge);
    is $ge, 1;

    $ge = $integer->ge(1);

    isnt refaddr($integer), refaddr($ge);
    is $ge, 1;

    $ge = $integer->ge(2);

    isnt refaddr($integer), refaddr($ge);
    is $ge, 0;

    isa_ok $integer, 'Data::Object::Number';
    isa_ok $ge, 'Data::Object::Number';
};

ok 1 and done_testing;
