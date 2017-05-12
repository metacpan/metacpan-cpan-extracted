# -*- perl -*-

use Test::More tests => 16;
use DBI;

do "t/lib.pl";

BEGIN
{
    if ( $^O eq 'MSWin32' )
    {
        require Win32::pwent;
    }
}

my ( $username, $userid, $groupname, $groupid );

if ( $^O eq 'MSWin32' )
{
    $username  = getlogin() || Win32::LoginName() || $ENV{USERNAME};
    $userid    = Win32::pwent::getpwnam($username);
    $groupid   = ( Win32::pwent::getpwnam($username) )[3];
    $groupname = Win32::pwent::getgrgid($groupid);
}
else
{
    $userid    = $<;
    $username  = getpwuid($<);
    $groupid   = $(;
    $groupname = getgrgid($();
}

my $foundAllTables = 0;

ok( my $dbh = DBI->connect('DBI:Sys:'), 'connect' ) or diag($DBI::errstr);

ok( my $st = $dbh->prepare('SELECT table_name FROM alltables'), 'prepare alltables' ) or diag( $dbh->errstr );
ok( my $num = $st->execute(), 'execute alltables' ) or diag( $st->errstr );
while ( $row = $st->fetchrow_hashref() )
{
    ++$foundAllTables if ( $row->{table_name} eq 'alltables' );
}
ok( $foundAllTables, 'found alltables' );

ok( $st = $dbh->prepare('SELECT DISTINCT username, uid FROM pwent WHERE uid=?'), 'prepare pwent' )
  or diag( $dbh->errstr );
ok( $num = $st->execute($userid), 'execute pwent' ) or diag( $st->errstr );
while ( $row = $st->fetchrow_hashref() )
{
    cmp_ok( $userid,   '==', $row->{uid},      'uid pwent' );
    cmp_ok( $username, 'eq', $row->{username}, 'username pwent' );
}

ok( $st = $dbh->prepare('SELECT DISTINCT groupname, gid FROM grent WHERE gid=?'), 'prepare grent' )
  or diag( $dbh->errstr );
ok( $num = $st->execute( 0 + $groupid ), 'execute grent' ) or diag( $st->errstr );
while ( $row = $st->fetchrow_hashref() )
{
    cmp_ok( $groupid,   '==', $row->{gid},       'gid grent' );
    cmp_ok( $groupname, 'eq', $row->{groupname}, 'groupname grent' );
}

ok(
    $st = $dbh->prepare(
              "SELECT DISTINCT grent.groupname, grent.gid FROM grent, pwent WHERE pwent.uid=? and pwent.gid=grent.gid"),
    'prepare join'
  ) or diag( $dbh->errstr );
ok( $num = $st->execute($userid), 'execute join' ) or diag( $st->errstr );
while ( $row = $st->fetchrow_hashref() )
{
    cmp_ok( $groupid,   '==', $row->{'grent.gid'},       'gid join' );
    cmp_ok( $groupname, 'eq', $row->{'grent.groupname'}, 'groupname join' );
}
