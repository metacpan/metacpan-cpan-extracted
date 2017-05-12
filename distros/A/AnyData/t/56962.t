#!perl

use strict;
use warnings;

use Test::More;

eval { require DBI; require DBD::AnyData; };
plan skip_all => 'extra test for RT#56962 - needs DBI & DBD::AnyData' if ($@);

plan tests => 1;

my $file = shift;
$file ||= 't/56962.log';
my $sql = qq{
      select remotehost,count(remotehost) as crh from accesslog group by
      remotehost order by crh desc
      };
my $dbh = DBI->connect("dbi:AnyData(RaiseError=>1):");
$dbh->func( 'accesslog', 'Weblog', $file, 'ad_catalog' );
my $sth = $dbh->prepare($sql);
$sth->execute();

my $test_output = '';

while ( my @res = $sth->fetchrow_array ) {
    $test_output = $test_output . join( '|', @res ) . "\n";
}
$sth->finish();
$dbh->disconnect();

ok( $test_output eq <<'HERE', "sort test: \n" . $test_output );
192.168.208.92|68
192.168.192.148|65
192.168.192.149|63
192.168.208.93|62
192.168.192.150|42
HERE

