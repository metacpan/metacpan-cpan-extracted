use Test::Modern;


use App::vaporcalc::RecipeResultSet;

my $rset = App::vaporcalc::RecipeResultSet->new(
  recipe => +{
    target_quantity   => 10,
    base_nic_per_ml   => 100,
    target_nic_per_ml => 16,
    target_pg         => 65,
    target_vg         => 35,
    flavor_array      => [
      +{ tag => 'hpno', percentage => 20 },
    ],
  },
);

isa_ok $rset->recipe, 'App::vaporcalc::Recipe';
isa_ok $rset->result, 'App::vaporcalc::Result';

my $result = $rset->result;
ok $result->total  == 10,  '10ml total';
ok $result->flavor_total == 2,   '2ml flavor_total';
ok $result->pg     == 2.9, '2.9ml PG';
ok $result->vg     == 3.5, '3.5ml VG';
ok $result->nic    == 1.6, '1.6ml nic';
ok $result->flavors->keys->count == 1, '1 flavor listed';

use File::Temp ();
subtest 'storage' => sub {
  if ($^O eq 'MSWin32') {
    plan skip_all => 'Temp files fail on some Windows platforms'
  }
  my $fh    = File::Temp->new(UNLINK => 1);
  my $fname = $fh->filename;
  ok $rset->save($fname), 'save ok';
  my $loaded = App::vaporcalc::RecipeResultSet->load($fname);
  isa_ok $loaded, 'App::vaporcalc::RecipeResultSet';
  ok $loaded->recipe->target_nic_per_ml == 16, 'loaded recipe looks ok';
  ok $loaded->result->nic == 1.6, 'loaded result looks ok';
};


done_testing
