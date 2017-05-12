# -*- perl -*-

use Test::More;
use Params::Util qw(_HASH);
use Config;
use DBI;

do "t/lib.pl";

my @proved_vers = proveRequirements( [qw(Unix::Lsof)] );
showRequirements( undef, $proved_vers[1] );

plan( skip_all => "Unix::Lsof required for this test" ) unless ( defined( _HASH( $proved_vers[1] ) ) );

ok( my $dbh = DBI->connect('DBI:Sys:'), 'connect 1' ) or diag($DBI::errstr);
ok( $dbh->{sys_openfiles_pids} = $$, 'restrict open files to current process' ) or diag( $dbh->errstr );
ok( $st = $dbh->prepare("SELECT filename FROM openfiles"), 'prepare openfiles' ) or diag( $dbh->errstr );
ok( my $num = $st->execute(), 'execute openfiles' ) or diag( $st->errstr );
my $found = 0;
while ( $row = $st->fetchrow_arrayref() )
{
    ok( $row->[0], 'open files found' );
    (0 == index($row->[0], $Config{perlpath})) and ++$found;
}
ok( $found, "Found $Config{perlpath} in openfiles" );

done_testing;
