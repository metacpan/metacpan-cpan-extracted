use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Download::Git;
use Capture::Tiny qw( capture_merged );
use Path::Tiny qw( path );
use lib 't/lib';
use Repo;

my $build = alienfile_ok q{
  use alienfile;
  
  plugin 'Download::Git';
};

$build->load_requires('share');

my $example1 = example1();
note "example1 = $example1";

$build->meta_prop->{start_url} = "$example1";

subtest 'latest' => sub {

  my $error;
  my $ret;
  my $out;

  note $out = scalar capture_merged {
    $ret = eval {
      $build->download;
    };
    $error = $@;
  };
  
  is $error, '';
  diag $out if $error;
  
  note $out = scalar capture_merged {
    $ret = eval {
      $build->extract;
    };
   $error = $@;
  };
  
  is $error, '';
  diag $out if $error;

  my $dir = $ret;
  
  ok -d $dir;
  is( path($dir)->child('content.txt')->slurp, "This is version 0.03\n");

};

done_testing
