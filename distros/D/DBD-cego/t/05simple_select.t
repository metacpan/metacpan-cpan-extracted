use Test;
BEGIN { plan tests => 7 }
use DBI;

open(DEF, "<dbd.def ") || die "File dbd.def not found\n";
$line= <DEF>;
chop $line;
my ($host, $port,$tableset,$user,$pwd) = split(/:/, $line );
close(DEF);

my $dbh = DBI->connect("dbi:Cego:tableset=$tableset;hostname=$host;port=$port;protocol=serial;logfile=cegoDBD.log;logmode=debug", "$user", "$pwd");
ok($dbh);

my $sth = $dbh->prepare("select * from tab1;");
ok($sth);

ok($sth->execute, 1);

print "Query will return $sth->{NUM_OF_FIELDS} fields.\n\n";
print "Field names: @{ $sth->{NAME} }\n";
ok( @{ $sth->{NAME} }, $sth->{NUM_OF_FIELDS} );

while (($sid, $mat) = $sth->fetchrow_array) {
  print  "A=$sid B=$mat\n";
}
ok($sth);


$sth->finish;
ok($sth);

$dbh->disconnect;
ok($sth);
