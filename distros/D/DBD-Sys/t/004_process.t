# -*- perl -*-

use Test::More;    # the number of the tests to run.
use DBI;

do "t/lib.pl";

my @proved_vers = proveRequirements( [qw(Proc::ProcessTable Win32::Process::Info Win32::Process::CommandLine)] );
showRequirements( undef, $proved_vers[1] );
plan( tests => 8 );

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

my $table;

my $found = 0;

ok( my $dbh = DBI->connect('DBI:Sys:'), 'connect 1' ) or diag($DBI::errstr);

if ( $proved_vers[1]->{'Proc::ProcessTable'} )
{
    my $pt = Proc::ProcessTable->new();
    $table = $pt->table();
    my @myprocs = grep { $_->uid() == $userid } @$table;
    $table = \@myprocs;
}
elsif ( $proved_vers[1]->{'Win32::Process::Info'} )
{
    Win32::Process::Info->import( 'NT', 'WMI' );
    $table = [ Win32::Process::Info->new()->GetProcInfo() ];
}
else
{
    $table = [];
}

ok( $st = $dbh->prepare("SELECT COUNT(uid) FROM procs WHERE procs.uid=$userid"), 'prepare process' )
  or diag( $dbh->errstr );
ok( my $num = $st->execute(), 'execute process' );
SKIP:
{
    skip( "OS seems to be unsupported", 1 ) unless scalar(@$table) > 0;
    $row = $st->fetchrow_arrayref();
    ok( $row->[0], 'process found for current user' );
}

ok( $dbh = DBI->connect('DBI:Sys:'), 'connect 2' ) or diag($DBI::errstr);
ok(
    $st = $dbh->prepare(
        'SELECT username, COUNT(procs.uid) as process_ct FROM procs, pwent WHERE procs.uid = pwent.uid GROUP BY username'
    ),
    'prepare process join user'
  ) or diag( $dbh->errstr );    # how many process per user
#print $st;
ok( $num = $st->execute(), 'execute process join user' ) or diag( $st->errstr );
SKIP:
{
    skip( "OS seems to be unsupported", 1 ) unless scalar(@$table) > 0;
    $row = $st->fetchrow_arrayref();    # arrayref BECAUSE hash needs keys (eg. ColumnNames) and array just counts.
    ok( $row->[0], 'process found for every user' );
}

