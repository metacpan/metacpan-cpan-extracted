use lib 'lib';
use DBIx::RetryOverDisconnects;
use DBI::Const::GetInfoType;
use Benchmark qw/timethis timethese/;

my $mcmd = '/usr/local/etc/rc.d/mysql-server';
my $pcmd = '/usr/local/etc/rc.d/postgresql';
my ($cmd, $dsn, $user, $pass);
#select_mysql();
select_sqlite();

#start();
my $dbh = DBIx::RetryOverDisconnects->connect($dsn, $user, $pass, {
    ReconnectRetries => 3,
    ReconnectInterval => 1,
    TxnRetries => 5,
    ReconnectTimeout => 5,
});

$dbh->do("INSERT INTO aaa VALUES (".rand(1000000).", 'jopa')") for 1..100;

$dbh->do("INSERT INTO aaa VALUES (".rand(1000000).", 'jopa')") for 1..100;

=pod
print "-".$dbh->do("SELECT 1")."\n";
restart();
#stop();
my @a = $dbh->selectall_arrayref("SELECT * FROM facult");
print "-".$dbh->do("SELECT 1")."\n";
print_errors();
start();
#print "-".$dbh->do("SELECT asdf")."\n";
#print_errors();

$dbh->begin_work;
restart();
#stop();
print "-".$dbh->do("SELECT 1")."\n";
print_errors();
=cut
print "------------------end-------------\n";

sub restart {`$cmd restart`; sleep 1; }
sub stop    {`$cmd stop`;    sleep 1; }
sub start   {`$cmd start`;   sleep 1; }

sub print_errors {
    print "DSE: $DBIx::Safe::errstr ($DBIx::Safe::err)\n";
    print "DE: $DBI::errstr ($DBI::err)\n";
};

sub select_psql {
    $cmd = $pcmd;
    $dsn = "dbi:Pg:dbname=testdb;host=localhost";
    $user = 'hacnet';
    $pass = undef;
}

sub select_mysql {
    $cmd = $mcmd;
    $dsn = "dbi:mysql:database=ep;host=localhost;mysql_client_found_rows=1";
    $user = 'ep';
    $pass = 'epq';
}

sub select_sqlite {
    $dsn = "dbi:SQLite:/home/hacnet/DBIx-Safe/db.sqlite";
}
