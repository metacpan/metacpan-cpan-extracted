use lib 't/lib';
use Test2::Plugin::FauxHomeDir;
use Test2::Plugin::HTTPTinyFile;
use Test2::V0 -no_srand => 1;
use App::cpangitify;
use File::Glob qw( bsd_glob );
use Capture::Tiny qw( capture_merged );
use File::chdir;
use URI::file;
use Path::Class qw( file dir );
use Git::Wrapper;

$App::cpangitify::_run_cb = sub {
  my($git, @command) = @_;
  note "+ git @command";
};

my $home = dir( bsd_glob '~' );

note "home = $home";

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
    'Foo::Bar',
  );
  
  my $merged = capture_merged { $ret = App::cpangitify->main(@args) };
  is($ret, 0, "% cpangitify @args");
  note $merged;
};

my $git = Git::Wrapper->new($home->subdir('Foo-Bar')->stringify);

my @commits = $git->log;

is(
  \@commits,
  array {
    item object { call message => match(qr{^version 0\.03$}) };
    item object { call message => match(qr{^version 0\.02$}) };
    item object { call message => match(qr{^version 0\.01$}) };
  },
  'commit messages',
);

foreach my $commit (@commits)
{
  like $commit->date, qr{^Wed Oct 9 .* 2013}, "commit.date = " . $commit->date;
  is $commit->author, 'Reserved Local Account <adam@ali.as>', 'commit.author = ' . $commit->author;
}

# 0.03
my @yes = map { [ split /\// ] } qw( lib/Foo/Bar.pm lib/Foo/Bar/Baz.pm t/use.t );
my @no  = map { [ split /\// ] } qw( t/stuffit.t );
mycheck(0.03);

# 0.02
@yes = map { [ split /\// ] } qw( lib/Foo/Bar.pm lib/Foo/Bar/Baz.pm t/use.t t/stuffit.t );
@no  = map { [ split /\// ] } qw( );
mycheck(0.02);

# 0.01
@yes = map { [ split /\// ] } qw( lib/Foo/Bar.pm t/use.t );
@no  = map { [ split /\// ] } qw( t/stuffit.t lib/Foo/Bar/Baz.pm );
mycheck(0.01);

pass 'okay';

done_testing;

sub mycheck
{
  my $tag = shift;
  $git->checkout($tag);
  subtest "version $tag" => sub {
    plan tests => @yes + @no;
    
    foreach my $file (map { $home->file('Foo-Bar', @$_) } @yes)
    {
      ok -e $file, "exists $file";
    }
    
    foreach my $file (map { $home->file('Foo-Bar', @$_) } @no)
    {
      ok !-e $file, "does not exists $file";
    }
  };
}

