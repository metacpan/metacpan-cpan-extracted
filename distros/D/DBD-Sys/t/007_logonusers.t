# -*- perl -*-

use Test::More;
use Params::Util qw(_HASH);
use DBI;

do "t/lib.pl";

my @proved_vers = proveRequirements( [qw(Sys::Utmp)] );
showRequirements( undef, $proved_vers[1] );

plan( skip_all => "Sys::Utmp required for this test" ) unless ( defined( _HASH( $proved_vers[1] ) ) );
plan( tests => 4 );

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

ok( my $dbh = DBI->connect('DBI:Sys:'),                                      'connect 1' )      or diag($DBI::errstr);
ok( $st     = $dbh->prepare("SELECT COUNT(*) FROM logins WHERE username=?"), 'prepare logins' ) or diag( $dbh->errstr );
ok( my $num = $st->execute($username),                                       'execute logins' ) or diag( $st->errstr );
$row = $st->fetchrow_arrayref();
ok( $row->[0], 'login found' );
