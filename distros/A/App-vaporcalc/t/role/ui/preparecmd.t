use Test::Modern;


use List::Objects::WithUtils 'array';
use App::vaporcalc::Recipe;

{ package
    MyCmdEngine;
  use Moo; with 'App::vaporcalc::Role::UI::PrepareCmd';
}

my $cmdengine = MyCmdEngine->new;

ok $cmdengine->cmd_class_prefix eq 'App::vaporcalc::Cmd::Subject::',
  'cmd_class_prefix ok';

my $recipe = App::vaporcalc::Recipe->new(
  target_quantity => 30,
  base_nic_per_ml => 36,
  target_nic_per_ml => 12,
  target_pg => 65,
  target_vg => 35,
  flavor_percentage => 20,
);

my $help = $cmdengine->prepare_cmd(
  subject => 'help',
  recipe  => $recipe,
);

isa_ok $help, 'App::vaporcalc::Cmd::Subject::Help';
ok $help->execute, 'prepare_cmd returned executable command';

done_testing;
