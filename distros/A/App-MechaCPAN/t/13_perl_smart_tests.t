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

my $fake_ver = '5.12.0';

my $pwd = cwd;
my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;
my $dir = cwd;

my %state_rans;

my $_rc = \&App::MechaCPAN::Perl::_run_configure;
local *App::MechaCPAN::Perl::_run_configure = sub { $state_rans{configure} = [@_]; $_rc->(@_); };
my $_rm = \&App::MechaCPAN::Perl::_run_make;
local *App::MechaCPAN::Perl::_run_make = sub { $state_rans{ $_[0] } = 1; $_rm->(@_); };

is(
  App::MechaCPAN::main( 'perl', "$FindBin::Bin/../test_dists/FakePerl-$fake_ver.tar.gz" ),
  0,
  'Can install "perl" from a tar.gz'
);

is( $state_rans{test_harness}, 1, 'Tests were ran by default' );

%state_rans = ();
is(
  App::MechaCPAN::main( 'perl', { 'smart-tests' => 1 }, "$FindBin::Bin/../test_dists/FakePerl-$fake_ver.tar.gz" ),
  0,
  'Can run with "smart-tests"',
);

is( $state_rans{test_harness}, 1, 'Tests were ran by with no perl-version' );

{
  open my $fh, '>', '.perl-version';
  print $fh '5.10.0';
}
%state_rans = ();
is(
  App::MechaCPAN::main( 'perl', { 'smart-tests' => 1 }, "$FindBin::Bin/../test_dists/FakePerl-$fake_ver.tar.gz" ),
  0,
  'Can run with "smart-tests"',
);

is( $state_rans{test_harness}, 1, 'Tests were ran by with a different perl-version' );

{
  open my $fh, '>', '.perl-version';
  print $fh "$fake_ver";
}
%state_rans = ();
is(
  App::MechaCPAN::main( 'perl', { 'smart-tests' => 1 }, "$FindBin::Bin/../test_dists/FakePerl-$fake_ver.tar.gz" ),
  0,
  'Can run with "smart-tests"',
);

is( $state_rans{test_harness}, undef, 'Tests were not ran with a good perl-version' );

chdir $pwd;
done_testing;
