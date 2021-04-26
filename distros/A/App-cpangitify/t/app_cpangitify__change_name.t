use lib 't/lib';
use Test2::V0 -no_srand => 1;
use Test2::Plugin::FauxHomeDir;
use Test2::Plugin::HTTPTinyFile;
use File::Glob qw( bsd_glob );
use App::cpangitify;
use Capture::Tiny qw( capture_merged );
use File::chdir;
use URI::file;
use Path::Class qw( file dir );

$App::cpangitify::_run_cb = sub {
  my($git, @command) = @_;
  note "+ git @command";
};

my $home = dir( bsd_glob '~' );

do {
  my $dir = $home->subdir('foo');
  $dir->mkpath(0,0700);
  my $git = Git::Wrapper->new($dir);
  $git->init;
  $git->config( '--global', 'user.name'  , 'Test User'        );
  $git->config( '--global', 'user.email' , 'test@example.com' );
};

do {
  my $uri = URI::file->new(file(__FILE__)->parent->parent->subdir('corpus')->absolute->stringify);
  $uri->host('localhost');

  local $CWD = "$home";
  my $ret;

  my @args = (
    '--backpan_index_url' => "$uri/backpan/backpan-index.txt.gz",
    '--backpan_url'       => "$uri/backpan",
    '--metacpan_url'      => "$uri/api.metacpan.org/",
    'Foo::Bar::Baz', 'Foo::Bar',
  );

  my $merged = capture_merged { $ret = App::cpangitify->main(@args) };
  is($ret, 0, "% cpangitify @args");
  note $merged;
};

my $git = Git::Wrapper->new($home->subdir('Foo-Bar-Baz')->stringify);

my @commits = $git->log;

is(
  \@commits,
  array {
    item object { call message => match(qr{^version 0\.04$}) };
    item object { call message => match(qr{^version 0\.03$}) };
    item object { call message => match(qr{^version 0\.02$}) };
    item object { call message => match(qr{^version 0\.01$}) };
  },
  'commit messages',
);

done_testing;
