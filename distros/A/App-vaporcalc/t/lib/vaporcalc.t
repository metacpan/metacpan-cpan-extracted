use Test::Modern;


use App::vaporcalc;

my $ret = vcalc(
  target_quantity   => 10,
  base_nic_per_ml   => 100,
  target_nic_per_ml => 16,
  target_pg         => 65,
  target_vg         => 35,
  flavor_array      => [
    +{ tag => 'Banana', percentage => 3, type => 'PG' },
  ],
);

my $result = $ret->result;
my $recipe = $ret->recipe;
isa_ok $ret, 'App::vaporcalc::RecipeResultSet';
isa_ok $result, 'App::vaporcalc::Result';
isa_ok $recipe, 'App::vaporcalc::Recipe';

done_testing
