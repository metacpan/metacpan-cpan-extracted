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

my $locallib = "$dir/local/lib/perl5";
my $lib      = "$dir/lib";
my $fakeperl = "$FindBin::Bin/../test_dists/FakePerl-$fake_ver.tar.gz";

my %config_items;
my %config_first;

my $_rc = \&App::MechaCPAN::Perl::_run_configure;
local *App::MechaCPAN::Perl::_run_configure = sub
{
  %config_items = ();
  @config_items{qw/des prefix applib eval other empty/} = @_;
  $_rc->(@_);
};

is( App::MechaCPAN::main( perl => $fakeperl ), 0, 'Can install "perl" from a tar.gz' );
is( $config_items{other}, undef, 'Did not have too many config options' );
is( $config_items{empty}, undef, 'Did not have too many config options' );

%config_first = %config_items;

like( $config_items{applib}, qr[lib/perl5], 'Otherlibs are being set' );
like( $config_items{applib}, qr[$locallib], 'local/lib is being set' );
unlike( $config_items{applib}, qr[$lib], 'lib is not being set when lib does not exist' );

mkdir "$dir/lib";

is( App::MechaCPAN::main( perl => $fakeperl ), 0, 'Can install "perl" from a tar.gz' );
like( $config_items{applib}, qr[$locallib], 'local/lib is being set' );
like( $config_items{applib}, qr[$lib],      'lib is being set after mkdir' );

is( App::MechaCPAN::main( perl => $fakeperl, '--skip-local' ), 0, 'Can install "perl" from a tar.gz' );
unlike( $config_items{applib}, qr[$locallib], 'local/lib is not being set' );
like( $config_items{applib}, qr[$lib], 'lib is being set' );

is( App::MechaCPAN::main( perl => $fakeperl, '--skip-lib' ), 0, 'Can install "perl" from a tar.gz' );
like( $config_items{applib}, qr[$locallib], 'local/lib is being set' );
unlike( $config_items{applib}, qr[$lib], 'lib is not being set' );

is( App::MechaCPAN::main( perl => $fakeperl, '--threads' ), 0, 'Can install "perl" from a tar.gz' );
isnt( $config_items{other}, undef, 'threads does something' );
is( $config_items{empty}, undef, 'Did not have too many config options' );

is( App::MechaCPAN::main( perl => $fakeperl, '--devel' ), 0, 'Can install "perl" from a tar.gz' );
isnt( $config_items{other}, undef, 'devel does something' );
is( $config_items{empty}, undef, 'Did not have too many config options' );

chdir $pwd;
done_testing;
