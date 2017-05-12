use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';
can_ok 'Data::Object::Float', 'ne';

use Scalar::Util 'refaddr';

subtest 'test the ne method' => sub {
    my $float = Data::Object::Float->new(1.01);
    my $ne = $float->ne(2);

    isnt refaddr($float), refaddr($ne);
    is $ne, 1;

    $ne = $float->ne(1.01);

    isnt refaddr($float), refaddr($ne);
    is $ne, 0;

    isa_ok $float, 'Data::Object::Float';
    isa_ok $ne, 'Data::Object::Number';
};

ok 1 and done_testing;
