use Test::Modern;


use App::vaporcalc::Cmd::Subject::Help;

my $cmd = App::vaporcalc::Cmd::Subject::Help->new(recipe => undef);
ok $cmd->does('App::vaporcalc::Role::UI::Cmd'),
  'does Role::UI::Cmd';

ok $cmd->verb eq 'show', 'default verb ok';

ok $cmd->execute->action eq 'print', 'default verb execute ok';

done_testing
