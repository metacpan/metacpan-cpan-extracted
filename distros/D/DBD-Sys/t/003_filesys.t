# -*- perl -*-

use Test::More tests => 10;    # the number of the tests to run.
use FindBin qw($RealBin);     # class for getting the pathname.
use DBI;

do "t/lib.pl";

my @proved_vers = proveRequirements( [qw(Sys::Filesystem Filesys::DfPortable)] );
showRequirements( undef, $proved_vers[1] );
my $haveSysFilesystem     = $proved_vers[1]->{'Sys::Filesystem'};
my $haveFilesysDfPortable = $proved_vers[1]->{'Filesys::DfPortable'};

my $mountpt = '';

ok( my $dbh = DBI->connect('DBI:Sys:sys_filesysdf_blocksize=1024'), 'connect' ) or diag($DBI::errstr);
SKIP:
{
    skip( 'Sys::Filesystem required for table filesystems', 3 ) unless ($haveSysFilesystem);
    ok( $st = $dbh->prepare('SELECT DISTINCT mountpoint, label, device FROM filesystems ORDER BY mountpoint'),
        'prepare filesystems' )
      or diag( $dbh->errstr );
    ok( $num = $st->execute(), 'execute filesystems' ) or diag( $st->errstr );

    my $found = 0;

    while ( $row = $st->fetchrow_hashref() )
    {
        if ( 0 == index( $RealBin, $row->{mountpoint} ) )
        {
            ++$found;
            $mountpt = $row->{mountpoint};
        }
    }
    ok( $found, 'test mountpoint found' );
}

SKIP:
{
    skip( 'Sys::Filesystem and Filesys::DfPortable required for table filesysdf', 3 )
      unless ( $haveSysFilesystem and $haveFilesysDfPortable );
    ok(
        $st = $dbh->prepare(
            "SELECT DISTINCT mountpoint, blocks, bfree, bused FROM filesysdf WHERE mountpoint = '$mountpt' ORDER BY mountpoint"
        ),
        'prepare filesysdf'
      ) or diag( $dbh->errstr );    # " instead of ' because $mountpoint needs to be evaluated!
    ok( $num = $st->execute(), 'execute filesysdf' ) or diag( $st->errstr );

    while ( $row = $st->fetchrow_hashref() )
    {
        cmp_ok( $row->{bfree} + $row->{bused},
                '==', $row->{blocks}, 'free blocks + used blocks = total blocks in filesysdf' );
    }
}

SKIP:
{
    skip( 'Sys::Filesystem and Filesys::DfPortable required for table filesysdf', 3 )
      unless ( $haveSysFilesystem and $haveFilesysDfPortable );
    $dbh->{sys_filesysdf_blocksize} = 1;
    ok(
        $st = $dbh->prepare(
            "SELECT DISTINCT mountpoint, blocks, bfree, bused FROM filesysdf WHERE mountpoint = '$mountpt' ORDER BY mountpoint"
        ),
        'prepare filesysdf (blocksize=1)'
      ) or diag( $dbh->errstr );    # " instead of ' because $mountpoint needs to be evaluated!
    ok( $num = $st->execute(), 'execute filesysdf (blocksize=1)' ) or diag( $st->errstr );

    while ( $row = $st->fetchrow_hashref() )
    {
        cmp_ok( $row->{bfree} + $row->{bused},
                '==', $row->{blocks}, 'free blocks + used blocks = total blocks in filesysdf (blocksize=1)' );
    }
}
