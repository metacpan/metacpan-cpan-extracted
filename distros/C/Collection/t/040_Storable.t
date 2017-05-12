#$Id$

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Object-Collection.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;

#use Test::More;
use Data::Dumper;

use_ok('Collection');
use_ok('Collection::Storable');
use_ok( 'File::Temp', qw/ tempfile tempdir / );
ok !( new Collection::Storable:: ), 'empty params';
my $tmp_dir = tempdir();
ok -e $tmp_dir, "check tmp dir $tmp_dir";
ok my $coll = ( new Collection::Storable:: $tmp_dir), 'create';
is_deeply $coll->key2path( 1, 2 ),
  {
    '1' => 1,
    '2' => 2
  },
  'convert keys to path';

ok !$coll->fetch_one(1), 'get non_exists';
is_deeply(
    $coll->create( 1 => { 2 => 2 } ),
    { '1' => { '2' => 2 } },
    'check set'
);
$coll->delete( 1, 2, 3 );
ok !$coll->fetch_one(1), 'check delete';

is_deeply(
    $coll->create( 1 => { 2 => 2 }, 3 => { 4 => 4 } ),
    {
        '1' => { '2' => 2 },
        '3' => { '4' => 4 }
    },
    'check create'
);
ok my $t3 = $coll->fetch_one(3), 'get key 3';
isa_ok tied %$t3, 'Collection::Utl::ActiveRecord', 'check is ActiveRecord';
$t3->{5} = 5;
ok( ( tied %$t3 )->_changed(), 'check changed' );
$coll->store;
$coll->release;
ok my $t3_ = $coll->fetch(3), 'get key 3';
is_deeply $t3_,
  {
    '3' => {
        '4' => 4,
        '5' => 5
    }
  },
  'check store';

is_deeply [ sort @{ $coll->list_ids }], [ '1', '3' ], 'check list_ids';

