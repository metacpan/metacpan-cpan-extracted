# -*- perl -*-

use Test::More;
use Params::Util qw(_HASH);
use DBI;

do "t/lib.pl";

my @proved_vers = proveRequirements( [qw(Net::Interface Net::Ifconfig::Wrapper NetAddr::IP)] );
showRequirements( undef, $proved_vers[1] );

plan( skip_all => "Net::Interface > 1.0 or Net::Ifconfig::Wrapper >= 0.11 required for this test" )
  unless ( defined( _HASH( $proved_vers[1] ) )
      && ( defined( $proved_vers[1]->{'Net::Interface'} ) || defined( $proved_vers[1]->{'Net::Ifconfig::Wrapper'} ) ) );
plan( tests => 4 );

ok( my $dbh = DBI->connect('DBI:Sys:'),                             'connect 1' )          or diag($DBI::errstr);
ok( $st     = $dbh->prepare("SELECT COUNT(interface) FROM netint"), 'prepare netint' )     or diag( $dbh->errstr );
ok( my $num = $st->execute(),                                       'execute for netint' ) or diag( $st->errstr );
$row = $st->fetchrow_arrayref();
ok( $row->[0], 'interfaces found' );
