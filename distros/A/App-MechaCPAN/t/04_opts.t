use strict;
use FindBin;
use Test::More;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

$SIG{__WARN__} = sub { };

my $pwd = cwd;
my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );

chdir $tmpdir;
my $cwd = cwd;
chdir $pwd;

# --directory
{
  is( App::MechaCPAN::main( '--diag-run', "--directory=$cwd", 'install' ), 0, 'Passing in --directory does not fail' );
  is( cwd, $pwd, 'Returned to whence it started' );

  isnt( eval { App::MechaCPAN::main( '--diag-run', "--directory=$cwd/x", 'install' ); 1; }, 1,
    'Passing in a bogus directory dies' );

  my $dist = 'test_dists/NoDeps/NoDeps-1.0.tar.gz';
  my ($name) = $dist =~ m[test_dists/(.*?)/]xms;
  is( App::MechaCPAN::main( "--directory=$cwd", 'install', "$pwd/$dist" ), 0, "Can install $dist" );
  is( cwd, $pwd, 'Returned to whence it started' );
  ok( -e "$cwd/local/lib/perl5/$name.pm", 'Library exists as expected' );
}

{
  chdir $cwd;
  is( App::MechaCPAN::get_project_dir(), "$cwd", 'Calling get_project_dir does the right thing with cwd' );

  chdir "$cwd/local";
  is( App::MechaCPAN::get_project_dir(), "$cwd", 'Calling get_project_dir inside local strips local' );

  chdir $cwd;
  $App::MechaCPAN::PROJ_DIR = "$cwd/local";
  is( App::MechaCPAN::get_project_dir(), "$cwd/local", 'Calling get_project_dir with PROJ_DIR outputs PROJ_DIR' );
}

chdir $pwd;
done_testing;
