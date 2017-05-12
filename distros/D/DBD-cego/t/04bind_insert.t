use Test;
use DBI qw(:sql_types);

BEGIN { plan tests => 6 }
use DBI;

open(DEF, "<dbd.def ") || die "File dbd.def not found\n";
$line= <DEF>;
chop $line;
my ($host, $port,$tableset,$user,$pwd) = split(/:/, $line );
close(DEF);

my $dbh = DBI->connect("dbi:Cego:tableset=$tableset;hostname=$host;port=$port;protocol=serial;logfile=cegoDBD.log;logmode=debug", "$user", "$pwd");
ok($dbh);

my $sth = $dbh->prepare("insert into tab1 values ( ? , ? );");
ok($sth);

$sth->bind_param(1, 55, SQL_INTEGER);
$sth->bind_param(2, 'udo', SQL_VARCHAR );
$sth->execute;
ok($sth);

$sth->bind_param(1, 66, SQL_INTEGER);
$sth->bind_param(2, undef, SQL_VARCHAR );
ok($sth);

$sth->finish();
ok($sth);

$dbh->{AutoCommit} = 1;
$dbh->disconnect;
ok($sth);
