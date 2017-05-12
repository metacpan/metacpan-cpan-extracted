use Test::Most;

use lib 't/lib';
use FooGlobal ();

subtest 'oo' => sub {
  my $f = FooGlobal->new;
  is $f->bar, 1;
  is $f->baz, 2;
  is $f->bar(3), 3;
  is $f->baz, 4;
  is_deeply [ $f->boop ], [ 3, 4 ];
};

{
  package state1;

  use Test::Most;

  use lib 't/lib';
  use FooGlobal ':all';

  subtest 'non-oo namespace state1' => sub {
    is bar(), 5;
    is baz(), 6;
    is bar(3), 3;
    is baz(), 4;
    is_deeply [ boop() ], [ 3, 4 ];
  };
}

{
  package state2;

  use Test::Most;

  use lib 't/lib';
  use FooGlobal ':all';

  subtest 'non-oo namespace state2' => sub {
    is bar(), 3;
    is baz(), 4;
    is bar(7), 7;
    is baz(), 8;
    is_deeply [ boop() ], [ 7, 8 ];
  };
}

{
  package state3;

  use Test::Most;

  use lib 't/lib';
  use FooGlobal ':all';

  local %FooGlobal::_DEFAULT_SINGLETONS;

  subtest 'non-oo namespace state2' => sub {
    is bar(), 5;
    is baz(), 6;
    is bar(7), 7;
    is baz(), 8;
    is_deeply [ boop() ], [ 7, 8 ];
  };
}

done_testing;


