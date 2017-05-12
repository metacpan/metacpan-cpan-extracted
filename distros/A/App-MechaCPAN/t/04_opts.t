use strict;
use FindBin;
use Test::More;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

$SIG{__WARN__} = sub { };

my $pwd = cwd;
my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );

# --directory
{
  is( App::MechaCPAN::main( '--diag-run', "--directory=$tmpdir", 'install' ), 0, 'Passing in --directory does not fail' );
  is( cwd, $pwd, 'Returned to whence it started' );

  isnt( eval { App::MechaCPAN::main( '--diag-run', "--directory=$tmpdir/x", 'install' ); 1; }, 1, 'Passing in a bogus directory dies' );

  my $dist = 'test_dists/NoDeps/NoDeps-1.0.tar.gz';
  my ($name) = $dist =~ m[test_dists/(.*?)/]xms;
  is( App::MechaCPAN::main( "--directory=$tmpdir", 'install', "$pwd/$dist" ), 0, "Can install $dist" );
  is( cwd, $pwd, 'Returned to whence it started' );
  ok( -e "$tmpdir/local/lib/perl5/$name.pm", 'Library exists as expected' );
}

chdir $pwd;
done_testing;
