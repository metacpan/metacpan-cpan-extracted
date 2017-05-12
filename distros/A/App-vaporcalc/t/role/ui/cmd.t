use Test::Modern;

{ package
    MyCmd;
  use Moo; with 'App::vaporcalc::Role::UI::Cmd';
  sub _subject { 'mycmd' }
  has '+verb' => (
    builder => sub { 'view' },
  );
  sub _action_view { [ "foo" ] }
}

my $cmd = MyCmd->new(
  params => [ 1, 2, 3 ],
  recipe => +{
    target_quantity   => 30,
    base_nic_per_ml   => 36,
    target_nic_per_ml => 12,
    target_pg         => 65,
    target_vg         => 35,
    flavor_percentage => 20,
  },
);

ok $cmd->_subject eq 'mycmd', '_subject ok';
ok $cmd->verb eq 'view', 'default verb override ok';
isa_ok $cmd->recipe, 'App::vaporcalc::Recipe', 'recipe ok';
is_deeply
  [ $cmd->params->all ],
  [ 1, 2, 3 ],
  'params ok';

my $res = $cmd->execute;
is_deeply $res, [ 'foo' ], 'execute ok';

my $new_recipe = $cmd->munge_recipe(target_pg => 50, target_vg => 50);
ok $new_recipe->target_vg == 50 && $new_recipe->target_quantity == 30,
  'munge_recipe ok';

{
  my $died = exception {; $cmd->throw_exception('foo') };
  isa_ok $died, 'App::vaporcalc::Exception';
  ok $died->message eq 'foo', 'throw_exception ok';
}
{
  my $died = exception {; MyCmd->new };
  ok $died, 'missing recipe dies ok';
}

done_testing
