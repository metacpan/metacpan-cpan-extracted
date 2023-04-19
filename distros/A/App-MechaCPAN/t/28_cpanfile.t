use strict;
use FindBin;
use File::Copy;
use Test::More;
use Cwd qw/cwd/;
use File::Temp qw/tempdir tempfile/;

require q[./t/helper.pm];

my $pwd = cwd;

my $tmpdir
    = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX",
  CLEANUP => 1 );
chdir $tmpdir;
my $dir = cwd;

my ( $fh, $cpanfile ) = tempfile( "cpanfile.XXXXXXXX", DIR => $tmpdir );

my @resolvd;
my @pkgs = qw/Try::Tiny Test::More/;

$fh->say("requires '$_';") foreach @pkgs;
$fh->seek( 0, 0 );

*App::MechaCPAN::Install::_resolve = sub
{
  my $target = shift;
  push @resolvd, $target->{src_name};
  return;
};

# Check that it will handle with a filname
@resolvd = ();
is(
  App::MechaCPAN::main( 'install', { 'skip-perl' => 1 }, $cpanfile ), 0,
  "Can run install"
);
is( cwd, $dir, 'Returned to whence it started' );
is_deeply( [ sort @resolvd ], [ sort @pkgs ],
  'All packages were from cpanfile' );

# Check that it will handle with a filehandle that is text-like
@resolvd = ();
is(
  App::MechaCPAN::main( 'install', { 'skip-perl' => 1 }, $fh ), 0,
  "Can run install"
);
is( cwd, $dir, 'Returned to whence it started' );
is_deeply( [ sort @resolvd ], [ sort @pkgs ],
  'All packages were from cpanfile' );

# Check that we can use the default cpanfile file search
File::Copy::move( $cpanfile, 'cpanfile' );
@resolvd = ();
is(
  App::MechaCPAN::main( 'install', { 'skip-perl' => 1 }, $tmpdir ), 0,
  "Can run install"
);
is( cwd, $dir, 'Returned to whence it started' );
is_deeply( [ sort @resolvd ], [ sort @pkgs ],
  'All packages were from cpanfile' );

# Check that we can use the default cpanfile directory search
@resolvd = ();
is(
  App::MechaCPAN::main( 'install', { 'skip-perl' => 1 }, ), 0,
  "Can run install"
);
is( cwd, $dir, 'Returned to whence it started' );
is_deeply( [ sort @resolvd ], [ sort @pkgs ],
  'All packages were from cpanfile' );
chdir $pwd;
done_testing;
