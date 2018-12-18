use Test::More;
use App::git::ship;

my $app = App::git::ship->new(silent => $ENV{HARNESS_IS_VERBOSE} ? 0 : 1);

ok !$app->can('some_attr'), 'some_attr() does not exist';
$app->attr(some_attr => sub {123});
ok $app->can('some_attr'), 'some_attr() injected';
ok !exists $app->{some_attr}, 'some_attr does not exist';
is $app->some_attr, 123, 'some_attr() 123';
ok exists $app->{some_attr}, 'some_attr exists';

like $app->render_template('test', {x => 'repository', to_string => 1}),
  qr{^repository: \S+ \# test}, 'render';
eval { $app->can_handle_project };
like $@, qr{^\!\! can_handle_project}, 'can_handle_project() is not available';

eval { $app->abort("foo") };
like $@, qr{^\!\! foo}, 'abort foo';

eval { $app->abort("foo %s", 123) };
like $@, qr{^\!\! foo 123}, 'abort foo 123';

eval { $app->system(perl => '-e', '$!=42;die') };
like $@, qr{^\!\! 'perl -e \$!=42;die' failed: 42}, 'system() failed';

eval { $app->build };
like $@, qr{^\!\! build}, 'build() is not available';

done_testing;
