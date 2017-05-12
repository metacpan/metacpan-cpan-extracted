use strict;
use warnings;
use Test::More;

use Data::Object;
use Scalar::Util 'refaddr';

can_ok 'Data::Object', 'load';
subtest 'test the load function' => sub {
    my $class1 = Data::Object::load('Memoize');
    is $class1, 'Memoize';

    eval { Data::Object::load('Dummy::ZzZzZzZ') };
    like $@, qr{ Can't locate Dummy/ZzZzZzZ.pm };
};

ok 1 and done_testing;
