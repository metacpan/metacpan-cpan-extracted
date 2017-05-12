use Test;
use DBI qw(:sql_types);

BEGIN { plan tests => 4 }
use DBI;

open(DEF, "<dbd.def ") || die "File dbd.def not found\n";
$line= <DEF>;
chop $line;
my ($host, $port,$tableset,$user,$pwd) = split(/:/, $line );
close(DEF);

my $dbh = DBI->connect("dbi:Cego:tableset=$tableset;hostname=$host;port=$port;protocol=serial;logfile=cegoDBD.log;logmode=debug", "$user", "$pwd", { AutoCommit => 0} );
ok($dbh);

my $sth = $dbh->prepare("insert into tab1 values ( ? , ? );");
ok($sth);

$sth->bind_param(1, 44, SQL_INTEGER);
$sth->bind_param(2, 'ttt', SQL_VARCHAR );

$sth->execute;
$sth->execute;
$sth->execute;
$sth->execute;
$sth->execute;
$sth->execute;
$sth->execute;
$sth->execute;
$sth->execute;


# $dbh->rollback;

$sth->finish;



ok($sth);

$dbh->disconnect;
ok($sth);
