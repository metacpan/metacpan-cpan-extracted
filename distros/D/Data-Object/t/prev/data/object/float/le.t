use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'le';

use Scalar::Util 'refaddr';

subtest 'test the le method' => sub {
    my $float = Data::Object::Float->new(1.50);
    my $le = $float->le(1.50);

    isnt refaddr($float), refaddr($le);
    is $le, 1;

    $le = $float->le(2.00);

    isnt refaddr($float), refaddr($le);
    is $le, 1;

    $le = $float->le(0);

    isnt refaddr($float), refaddr($le);
    is $le, 0;

    isa_ok $float, 'Data::Object::Float';
    isa_ok $le, 'Data::Object::Number';
};

ok 1 and done_testing;
