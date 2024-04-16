use warnings;
use strict;
use Log::Log4perl qw(:easy);
use Config;

Log::Log4perl->easy_init($ERROR);

use File::Temp qw(tempfile tempdir);

my $TARDIR = "data";
$TARDIR = "t/$TARDIR" unless -d $TARDIR;

use Test::More tests => 4;
BEGIN { use_ok('Archive::Tar::Wrapper') }

my $arch = Archive::Tar::Wrapper->new();

my $tempdir = tempdir( CLEANUP => 1 );
my ( $fh, $tarfile ) = tempfile( UNLINK => 1 );

# to get predictable results regardless of local umask settings
umask 0002;

my $foodir  = "$tempdir/foo";
my $foofile = "$foodir/foofile";

mkdir "$foodir";
chmod 0710, $foodir;

open(my $fh2, '>', $foofile) or die "Cannot open $foofile ($!)";
print $fh2 "blech\n";
close($fh2);

ok( $arch->add( "foo/foofile", $foofile ), "adding file" );

# Make a tarball
ok( $arch->write($tarfile), "Tarring up" );

SKIP: {
    skip 'Permissions are too different on Microsoft Windows', 1 if ($Config{osname} eq 'MSWin32' || $Config{osname} eq 'msys');
    my $tarread = Archive::Tar::Wrapper->new();
    $tarread->read($tarfile);
    my $loc = $tarread->locate("foo");
    my $mode = ( stat $loc )[2] & 07777;
    is $mode, 0710, "check dir mode";
}
