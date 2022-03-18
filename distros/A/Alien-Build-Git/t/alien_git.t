use Test2::V0 -no_srand => 1;
use Test::Alien;
use Test::Alien::Build;
use Alien::git;
use lib 't/lib';
use Repo;
use Capture::Tiny qw( capture_merged );
use Path::Tiny qw( path );

alien_ok 'Alien::git';

isnt( Alien::git->version, 'unknown', 'version is not unknown' );

my $exe = Alien::git->exe;

my $run = run_ok([$exe, '--version'])
  ->success;

if(Alien::git->version eq 'unknown')
{
  $run->diag;
}
else
{
  $run->note;
}

helper_ok 'git';

interpolate_template_is '%{git}', Alien::git->exe;

my $example1 = example1();

my $build = alienfile_ok qq{
  use alienfile;

  probe sub { 'share' };

  share {
    requires 'Alien::git';
    download [ [ '%{git}', 'clone', '$example1' ] ];
  };
};

my $error;
note scalar capture_merged {
  eval {
    $build->load_requires($build->install_type);
    $build->download;
  };
  $error = $@;
};

is $error, '', 'do not throw error';

is(
  path($build->install_prop->{download})->child('content.txt')->slurp,
  "This is version 0.03\n",
);

done_testing
