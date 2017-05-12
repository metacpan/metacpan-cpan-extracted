use Test::Modern;


use App::vaporcalc::Cmd::Subject::Flavor;
use App::vaporcalc::Recipe;

my $recipe = App::vaporcalc::Recipe->new(
  target_quantity   => 30,
  base_nic_per_ml   => 36,
  target_nic_per_ml => 12,
  target_pg         => 65,
  target_vg         => 35,
  flavor_array => [
    +{ tag => 'foo', percentage => 20 },
  ],
);

my $cmd = App::vaporcalc::Cmd::Subject::Flavor->new(
  recipe => $recipe
);

ok $cmd->does('App::vaporcalc::Role::UI::Cmd'),
  'does Role::UI::Cmd';

ok $cmd->verb eq 'show', 'default verb ok';

my $res = $cmd->execute;
ok $res->action eq 'print', 'default verb cmd action ok';
like $res->string, qr/Flavors.+foo.+20/ms,  'default verb string';

$cmd = App::vaporcalc::Cmd::Subject::Flavor->new(
  recipe => $recipe,
  verb   => 'set',
  params => [ foo => 10 ],
);
$res = $cmd->execute;
ok $res->action eq 'recipe', 'set verb cmd action ok';
my $new = $res->recipe;
isa_ok $new, 'App::vaporcalc::Recipe';
ok $new->flavor_array->get(0)->percentage == 10,
  'set verb execute ok';


$cmd = App::vaporcalc::Cmd::Subject::Flavor->new(
  recipe => $recipe,
  verb => 'add',
  params => [ bar => 5 ],
);
$res = $cmd->execute;
ok $res->action eq 'recipe', 'add verb cmd action ok';
$new = $res->recipe;
ok $new->flavor_array->count == 2,
  'add verb execute ok';

$cmd = App::vaporcalc::Cmd::Subject::Flavor->new(
  recipe => $new,
  verb   => 'del',
  params => [ 'foo' ],
);
$res = $cmd->execute;
ok $res->action eq 'recipe', 'del verb cmd action ok';
$new = $res->recipe;
ok $new->flavor_array->count == 1,
  'del verb execute ok';

$cmd = App::vaporcalc::Cmd::Subject::Flavor->new(
    recipe => $new,
    verb   => 'clear',
);
$res = $cmd->execute;
ok $res->action eq 'recipe', 'clear verb cmd action ok';
$new = $res->recipe;
ok $new->flavor_array->count == 0,
  'clear verb execute ok';

done_testing
