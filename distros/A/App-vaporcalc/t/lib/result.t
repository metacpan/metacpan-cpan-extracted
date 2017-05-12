use Test::Modern;

use App::vaporcalc::Result;

my $obj = App::vaporcalc::Result->new(
  vg  => 2,
  pg  => 2,
  nic => 2,
  flavors => +{
    foo => '2.0',
  },
);

ok $obj->total == 8, 'total ok';

my $ref = $obj->TO_JSON;
is_deeply 
  $ref,
  +{ vg => 2, pg => 2, nic => 2, flavors => +{ foo => '2.0' } },
  'TO_JSON ok';

ok $obj->does('App::vaporcalc::Role::Store'),
  'does Role::Store';

done_testing
