use 5.020;
use Test2::V0 -no_srand => 1;
use Alien::Build::Plugin::Extract::Libarchive;
use Test::Alien::Build;
use Path::Tiny qw( path );

our $tarball = path("corpus/example-1.2.3.tar")->absolute->stringify;
note "tarball test on $tarball";

alienfile_ok q{
  use alienfile;
  probe sub { 'share' };
  share {
    start_url $main::tarball;
    plugin 'Fetch::Local';
    plugin 'Extract::Libarchive';
  };
};

my $dir = alien_extract_ok;

ok -f "$dir/configure";
ok -f "$dir/foo.c";

done_testing;
