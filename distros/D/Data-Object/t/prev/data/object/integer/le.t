use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'le';

use Scalar::Util 'refaddr';

subtest 'test the le method' => sub {
    my $integer = Data::Object::Number->new(1);
    my $le = $integer->le(1);

    isnt refaddr($integer), refaddr($le);
    is $le, 1;

    $le = $integer->le(2);

    isnt refaddr($integer), refaddr($le);
    is $le, 1;

    $le = $integer->le(0);

    isnt refaddr($integer), refaddr($le);
    is $le, 0;

    isa_ok $integer, 'Data::Object::Number';
    isa_ok $le, 'Data::Object::Number';
};

ok 1 and done_testing;
