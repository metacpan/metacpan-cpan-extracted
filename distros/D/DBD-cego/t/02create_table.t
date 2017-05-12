use Test;
BEGIN { plan tests => 3 }
use DBI;

open(DEF, "<dbd.def ") || die "File dbd.def not found\n";
$line= <DEF>;
chop $line;
my ($host, $port,$tableset,$user,$pwd) = split(/:/, $line );
close(DEF);

my $dbh = DBI->connect("dbi:Cego:tableset=$tableset;hostname=$host;port=$port;protocol=serial;logfile=cegoDBD.log;logmode=debug", "$user", "$pwd");
ok($dbh);

$dbh->do("drop if exists table tab1;");
my $sth = $dbh->do("create table tab1 (id int, name string(20));");
ok($sth);

$dbh->disconnect;
ok($sth);
