use strict;
use warnings;

use Test::More;
use Data::Object::Export;

can_ok 'Data::Object::Export', 'throw';
subtest 'test the throw function' => sub {
  eval { Data::Object::Export::throw() };
  like $@, qr{An exception was thrown.*};

  eval { Data::Object::Export::throw('Sorry, Out-of-Order') };
  like $@, qr{Sorry, Out-of-Order.* };
};

ok 1 and done_testing;
