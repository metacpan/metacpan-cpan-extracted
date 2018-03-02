use strict;
use FindBin;
use Test::More;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $has_git = &App::MechaCPAN::has_git;
local $ENV{GIT_SSL_NO_VERIFY}='true';

# Notes:
#  * we don't test with git or ssh since those require some kind of login
#  * File::Remove is included to make sure that it's not confused with file://
foreach my $src (
  qw[
  test_dists/NoDeps/NoDeps-1.0.tar.gz
  authors/id/E/ET/ETHER/Try-Tiny-0.24.tar.gz
  E/ET/ETHER/Try-Tiny-0.24.tar.gz
  ETHER/Try-Tiny-0.24.tar.gz
  https://github.com/p5sagit/Try-Tiny.git
  https://github.com/p5sagit/Try-Tiny.git@v0.24
  https://github.com/p5sagit/Try-Tiny/archive/v0.24.zip
  Try::Tiny
  Try::Tiny@0.24
  Try::Tiny~0.24
  Try::Tiny~<0.24
  File::Remove
  ],
  [qw/Try::Tiny 0.24/],
  [qw/Try::Tiny <0.24/],
  )
{
SKIP:
  {
    if ( $src =~ m/[.]git/xms && !$has_git )
    {
      skip "git not available", 1;
    }

    local $App::MechaCPAN::Install::dest_dir
      = tempdir( TEMPLATE => File::Spec->tmpdir . '/mechacpan_XXXXXXXX',
      CLEANUP => 1 );

    my $target = App::MechaCPAN::Install::_create_target( $src, {} );
    local $@;
    my $tgz = eval { App::MechaCPAN::Install::_get_targz($target) };
    diag("Error: '$@'")
      if $@;
    ok( -s $tgz, "Got '$src'" );
  }
}

done_testing;
