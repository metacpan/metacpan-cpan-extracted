use strict;
use warnings;
use Test::More;

plan skip_all => 'Missing implicit dependencies. Tests skipped.' unless eval q(
    require Data::Object::Any;
    1;
);

use Data::Object::Export 'type_any';
use Scalar::Util 'refaddr';

can_ok 'Data::Object::Export', 'type_any';

subtest 'test the type_any function' => sub {
  my $universal1 = type_any 'Test::More';
  my $universal2 = type_any 'Test::More';
  isa_ok $universal1, 'Data::Object::Any';
  isa_ok $universal2, 'Data::Object::Any';
  isnt refaddr($universal1), refaddr($universal2);
};

ok 1 and done_testing;
