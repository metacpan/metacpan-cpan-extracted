use Test::Modern;


use File::Temp ();

use App::vaporcalc::Recipe;

my %defaults = (
  target_quantity   => 30,
  base_nic_per_ml   => 36,
  target_nic_per_ml => 12,
  target_pg         => 65,
  target_vg         => 35,
  flavor_array      => [
    +{ tag => 'hpno', percentage => 20 }
  ],
);

my $recipe = App::vaporcalc::Recipe->new(%defaults);

ok $recipe->flavor_array->has_any(sub { $_->isa('App::vaporcalc::Flavor') }),
  'flavor_array autovivication ok';
ok $recipe->notes->count == 0,   'notes default ok';

## TO_JSON
my $hash = $recipe->TO_JSON;
is_deeply 
  $hash,
  +{
    target_quantity   => 30,
    base_nic_per_ml   => 36,
    base_nic_type     => 'PG',
    target_nic_per_ml => 12,
    target_pg         => 65,
    target_vg         => 35,
    notes             => [],
    flavor_array      => [
      +{ tag => 'hpno', percentage => 20, type => 'PG' },
    ],
  },
  'TO_JSON ok'
    or diag explain $hash;

## Role::Store
subtest 'storage' => sub {
  if ($^O eq 'MSWin32') {
    plan skip_all => 'Temp files fail on some Windows platforms';
  }
  # save
  my $fh = File::Temp->new( UNLINK => 1 );
  my $fname = $fh->filename;
  ok $recipe->save($fname), 'save ok';
  # load
  my $loaded = App::vaporcalc::Recipe->load($fname);
  isa_ok $loaded, 'App::vaporcalc::Recipe';
  for my $key (keys %defaults) {
    next if $key eq 'flavor_array';
    ok $loaded->$key eq $defaults{$key}, "$key loaded ok"
  }
};

## Role::Calc
# calc
my $result = $recipe->calc;
ok $result->flavor_total == 6,  '6ml flavor_total'
  or diag explain $result;
ok $result->total  == 30, '30ml total';

ok $result->flavors->keys->count == 1, '1 flavor listed';
ok $result->pg  == 3.5,   '3.5ml pg';
ok $result->vg  == 10.5,  '10.5ml vg';
ok $result->nic == 10,    '10ml nic';

## exceptions
# PG + VG != 100%
my %badratio = %defaults;
$badratio{target_pg} = 30; $badratio{target_vg} = 40;
like exception {; App::vaporcalc::Recipe->new(%badratio) },
  qr/target_vg/, 
  'bad PG-VG ratio dies';

done_testing
