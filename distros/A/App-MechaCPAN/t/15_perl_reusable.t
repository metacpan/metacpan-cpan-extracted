use strict;
use FindBin;
use Test::More;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

if ( $^O eq 'MSWin32' )
{
  plan skip_all => 'Cannot build perl on Win32';
}

if ( !eval { App::MechaCPAN::run(qw/tar --version/) } )
{
  plan skip_all => 'Skipping without a usable tar command';
}

my $pwd = cwd;
my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;
my $dir = cwd;

*App::MechaCPAN::logmsg = sub
{
  Test::More::diag(@_);
};

is(
  App::MechaCPAN::main(
    '--build-reusable-perl',
    "$FindBin::Bin/../test_dists/FakePerl-5.12.0.tar.gz"
  ),
  0,
  'Can install "relocatable perl" from a tar.gz'
);

is(
  App::MechaCPAN::main(
    '--build-reusable-perl',
    'perl',
    "$FindBin::Bin/../test_dists/FakePerl-5.12.0.tar.gz"
  ),
  0,
  'Can also give the perl command without issue'
);

chdir $pwd;
done_testing;
