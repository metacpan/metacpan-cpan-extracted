use DBI;
use DBIx::NamedDSN;
use Test;

BEGIN {
    plan tests=>5;
}

print "DBI test connection: ";
$dsn=readline(STDIN);
chomp $dsn;

print "Test username: ";
$user=readline(STDIN);
chomp $user;

print "Test password: ";
$passwd=readline(STDIN);
chomp $passwd;

ok($dbh=DBIx::NamedDSN->connect($dsn,$user,$passwd));
ok(ref $dbh eq "DBI::db");
ok($dbh->connection_string);
ok($dbh->ndsn_identifier);
