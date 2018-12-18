use lib '.';
use t::Util;
use App::git::ship;

my $git_ship = File::Spec->catfile(Cwd::getcwd, 'bin', 'git-ship');
my $git_ship_lib = File::Spec->catfile(Cwd::getcwd, 'lib');
t::Util->goto_workdir('perl-start', 0);

my $username = getpwuid $<;
my $workdir  = Cwd::getcwd;

my $app = App::git::ship->new;
$app = $app->start('Perl/Start.pm', 0);

isa_ok($app, 'App::git::ship::perl');
isnt $workdir, Cwd::getcwd, 'chdir after start()';
ok -d '.git', '.git was created';
ok -e $app->config('main_module_path'), 'main module was touched';

is $app->config('main_module_path'), File::Spec->catfile(qw(lib Perl Start.pm)),
  'main_module_path is set';
is $app->config('bugtracker'), "https://github.com/$username/perl-start/issues",
  'bugtracker is set up';
is $app->config('homepage'), "https://github.com/$username/perl-start", 'homepage is set up';
is $app->config('license'), 'artistic_2', 'license is set up';

t::Util->test_file(
  '.gitignore',  qr{^\~\$}m,        qr{^\*\.bak}m,   qr{^\*\.old}m,
  qr{^\*\.swp}m, qr{^/blib}m,       qr{^/cover_db}m, qr{^/inc}m,
  qr{^/local}m,  qr{^/pm_to_blib}m, qr{^/Makefile}m, qr{^/MANIFEST}m,
  qr{^/MYMETA}m,
);

t::Util->test_file(
  '.travis.yml',
  qr{language: perl},
  qr{sudo: false},
  qr{cpanm -n --installdeps --with-develop},
  qr{email: false},
);

# same as for ship-start
t::Util->test_file('cpanfile', qr{test_requires "Test::More" => "0\.88"});
t::Util->test_file('Changes',  qr{^Revision history for perl distribution Perl-Start});

t::Util->test_file(
  'MANIFEST.SKIP', qr{\#\!start included .*MANIFEST\.SKIP},
  qr{pm_to_blib},    # from included MANIFEST.SKIP file
  qr{^\\\.swp\$}m, qr{^\^local}m, qr{^\^MANIFEST\\\.SKIP}m, qr{^\^README\\\.pod}m,
);

t::Util->test_file(
  File::Spec->catfile(qw(t 00-basic.t )), qr{ok eval "use \$module; 1"},
  qr{Test::Pod::pod_file_ok\(\$file\)},   qr{Test::Pod::Coverage::pod_coverage_ok\(\$module},
);

$app = App::git::ship::perl->new;
unlink $_ for qw(MANIFEST.SKIP .gitignore);
$app->start;
ok -e 'MANIFEST.SKIP', 'MANIFEST.SKIP was regenerated';
ok -e '.gitignore',    '.gitignore was regenerated';

$app = App::git::ship->new;
unlink $_ for qw(MANIFEST.SKIP .gitignore);

#system "find . -type f|grep -v git|sort";
$app->start('lib/Perl/Start.pm');
ok -e 'MANIFEST.SKIP', 'MANIFEST.SKIP was regenerated when start autodetect project type';

#system "find . -type f|grep -v git|sort";

done_testing;
