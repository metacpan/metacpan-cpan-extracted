use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'ge';

use Scalar::Util 'refaddr';

subtest 'test the ge method' => sub {
    my $float = Data::Object::Float->new(1.00034);
    my $ge = $float->ge(0);

    isnt refaddr($float), refaddr($ge);
    is $ge, 1;

    $ge = $float->ge(1.00034);

    isnt refaddr($float), refaddr($ge);
    is $ge, 1;

    $ge = $float->ge(2);

    isnt refaddr($float), refaddr($ge);
    is $ge, 0;

    isa_ok $float, 'Data::Object::Float';
    isa_ok $ge, 'Data::Object::Number';
};

ok 1 and done_testing;
