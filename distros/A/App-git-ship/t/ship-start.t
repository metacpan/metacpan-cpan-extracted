use lib '.';
use t::Util;
use App::git::ship;

t::Util->goto_workdir('ship-start');

my $app = App::git::ship->new;

eval { $app->start('foo.unknown') };
like $@, qr{Could not figure out what kind of project this is},
  'Could not figure out what kind of project this is';

$app->start;
ok -d '.git', '.git was created';
like $app->config('bugtracker'), qr{https://github.com/[^/]+/unknown/issues},
  'bugtracker is set up';
like $app->config('homepage'), qr{https://github.com/[^/]+/unknown}, 'homepage is set up';
is $app->config('license'), 'artistic_2', 'license is set up';

t::Util->test_file('.gitignore', qr{^\~\$}m, qr{^\*\.bak}m, qr{^\*\.old}m, qr{^\*\.swp}m,
  qr{^/local}m,);

done_testing;
