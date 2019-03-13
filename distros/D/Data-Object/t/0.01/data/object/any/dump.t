use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Any';
can_ok 'Data::Object::Any', 'dump';

subtest 'test the dump method' => sub {
  my $universal = Data::Object::Any->new(undef);
  is $universal->dump, 'undef';
};

ok 1 and done_testing;
