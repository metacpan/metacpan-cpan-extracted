use Test;
BEGIN { plan tests => 4 }
use DBI;

open(DEF, "<dbd.def ") || die "File dbd.def not found\n";
$line= <DEF>;
chop $line;
my ($host, $port,$tableset,$user,$pwd) = split(/:/, $line );
close(DEF);

my $dbh = DBI->connect("dbi:Cego:tableset=$tableset;hostname=$host;port=$port;protocol=serial;logfile=cegoDBD.log;logmode=debug", "$user", "$pwd");
ok($dbh);

my $sth;

$sth = $dbh->do("insert into srctab values ( 3, 'alfred');");
ok($sth);

$sth = $dbh->do(":r = call copytab ( 3 );");
ok($sth);

$dbh->disconnect;
ok($dbh);
