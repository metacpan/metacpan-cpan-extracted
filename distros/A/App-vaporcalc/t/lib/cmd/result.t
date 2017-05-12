use Test::Modern;


use App::vaporcalc::Cmd::Result;

my $res = App::vaporcalc::Cmd::Result->new;
cmp_ok $res->action, 'eq', 'print',
  'default action ok';
cmp_ok $res->string, 'eq', '',
  'default string ok';
cmp_ok $res->prompt, 'eq', '(undef)',
  'default prompt ok';
cmp_ok $res->prompt_default_ans, 'eq', '',
  'default prompt_default_ans ok';
ok !$res->prompt_callback->(),
  'default prompt_callback ok';
ok !$res->run_prompt_callback,
  'run_prompt_callback without prompt_callback ok';

$res = App::vaporcalc::Cmd::Result->new(
  action => 'next',
);
cmp_ok $res->action, 'eq', 'next',
  'action eq next ok';

$res = App::vaporcalc::Cmd::Result->new(
  action => 'last',
);
cmp_ok $res->action, 'eq', 'last',
  'action eq last ok';

# prompt, with cb and no default answer
my %t;
$res = App::vaporcalc::Cmd::Result->new(
  prompt => 'foo',
  prompt_callback => sub {
    my ($ans) = @_;
    $t{$ans}++;
    $t{$_}++;
  },
);
cmp_ok $res->prompt, 'eq', 'foo',
  'prompt ok';
cmp_ok $res->action, 'eq', 'prompt',
  'action eq prompt ok';
$res->run_prompt_callback("bar\n");
cmp_ok $t{bar}, '==', 2, 
  'run_prompt_callback ok';
%t = ();

# prompt, with cb and default answer
$res = App::vaporcalc::Cmd::Result->new(
  prompt => 'foo',
  prompt_default_ans => 'bar',
  prompt_callback => sub {
    my ($ans) = @_;
    $t{$ans}++;
    $t{$_}++;
  },
);
cmp_ok $res->prompt_default_ans, 'eq', 'bar',
  'prompt_default_ans ok';
$res->run_prompt_callback;
$res->run_prompt_callback("baz");
is_deeply \%t,
  +{ bar => 2, baz => 2 },
  'run_prompt_callback with prompt_default_ans ok';

# recipe attached
my $recipe = bless +{}, 'App::vaporcalc::Recipe';
$res = App::vaporcalc::Cmd::Result->new(
  recipe => $recipe,
);
ok $recipe == $res->recipe, 'recipe ok';
cmp_ok $res->action, 'eq', 'recipe',
  'action eq recipe ok';

# resultset attached
$recipe = bless +{}, 'App::vaporcalc::RecipeResultSet';
$res = App::vaporcalc::Cmd::Result->new(
  resultset => $recipe,
);
ok $recipe == $res->resultset, 'resultset ok';
cmp_ok $res->action, 'eq', 'display',
  'action eq display ok';

done_testing
