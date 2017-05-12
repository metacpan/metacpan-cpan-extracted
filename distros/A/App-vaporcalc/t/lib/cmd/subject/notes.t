use Test::Modern;


use App::vaporcalc::Cmd::Subject::Notes;
use App::vaporcalc::Recipe;

my $recipe = App::vaporcalc::Recipe->new(
  target_quantity   => 30,
  base_nic_per_ml   => 36,
  target_nic_per_ml => 12,
  target_pg         => 65,
  target_vg         => 35,
  flavor_percentage => 20,
);

my $cmd = App::vaporcalc::Cmd::Subject::Notes->new(
  recipe => $recipe
);

ok $cmd->does('App::vaporcalc::Role::UI::Cmd'),
  'does Role::UI::Cmd';

ok $cmd->verb eq 'show', 'default verb ok';
my $res = $cmd->execute;
ok length $res->string, 'default verb returned str ok';

$cmd = App::vaporcalc::Cmd::Subject::Notes->new(
  recipe => $recipe,
  verb   => 'add',
  params => [ 'this', 'is', 'a', 'str' ],
);

my $new = $cmd->execute->recipe;
isa_ok $new, 'App::vaporcalc::Recipe';
is_deeply
  [ $new->notes->all ],
  [ 'this is a str' ],
  'add verb execute ok';

$cmd = App::vaporcalc::Cmd::Subject::Notes->new(
  recipe => $new,
  verb   => 'del',
  params => [ 0 ],
);
$new = $cmd->execute->recipe;
ok $new->notes->is_empty, 'del verb execute ok';

$cmd = App::vaporcalc::Cmd::Subject::Notes->new(
  recipe => $recipe,
  verb   => 'add',
  params => [ 'this', 'is', 'a', 'str' ],
);
$new = $cmd->execute->recipe;
$cmd = App::vaporcalc::Cmd::Subject::Notes->new(
  recipe => $new,
  verb   => 'clear',
);
$new = $cmd->execute->recipe;
ok $new->notes->is_empty, 'clear verb execute ok';


done_testing
