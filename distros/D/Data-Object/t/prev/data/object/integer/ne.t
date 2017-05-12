use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'ne';

use Scalar::Util 'refaddr';

subtest 'test the ne method' => sub {
    my $integer = Data::Object::Number->new(1);
    my $ne = $integer->ne(2);

    isnt refaddr($integer), refaddr($ne);
    is $ne, 1;

    $ne = $integer->ne(1);

    isnt refaddr($integer), refaddr($ne);
    is $ne, 0;

    isa_ok $integer, 'Data::Object::Number';
    isa_ok $ne, 'Data::Object::Number';
};

ok 1 and done_testing;
