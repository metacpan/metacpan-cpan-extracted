use strict;
use warnings;

use Test::More;
use Data::Object;

can_ok 'Data::Object', 'throw';
subtest 'test the throw function' => sub {
    eval { Data::Object::throw() };
    like $@, qr{An exception \(Data::Object::Exception\).*};

    eval { Data::Object::throw('Sorry, Out-of-Order')};
    like $@, qr{Sorry, Out-of-Order.* };
};

ok 1 and done_testing;
