use strict;
use FindBin;
use Test::More;
use Config;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $pwd = cwd;
foreach my $dist ( sort glob("$FindBin::Bin/../test_dists/*/*.tar.gz") )
{
  next
    if $dist =~ m/Fail/xms;

  chdir $pwd;
  my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
  chdir $tmpdir;
  my $dir = cwd;

  my ($name) = $dist =~ m[test_dists/(.*?)/]xms;
  is( App::MechaCPAN::main( 'install', $dist ), 0, "Can install $dist" );
  is( cwd, $dir, 'Returned to whence it started' );
  ok( -e "$dir/local/lib/perl5/$name.pm", 'Library exists as expected' );
}

chdir $pwd;
done_testing;
