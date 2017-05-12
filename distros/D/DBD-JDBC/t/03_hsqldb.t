# -*-perl-*-
#
# In all cases test with hsqldb. 


require "t/lib.pl";
use DBI;
use Test::More;
$| = 1;

BEGIN {
    $test_count = 22;
    plan tests => $test_count;
}

$ENV{DBDJDBC_URL} = "jdbc:hsqldb:file:t/hsqldb/testdb";
my $pid;
$test_builder = Test::More->builder;

SKIP: {
    my $defaults = get_defaults();
    my $fatal = 0; 
    $pid = start_server($defaults->{driver}, $defaults->{port});
    ok($pid, "server started") or $fatal++;
    skip "Server failed to start; remaining tests will fail", 
        remaining() if $fatal;
    # Give the server time to attach to the socket before trying to connect.
    sleep(3); 
    $ENV{DBDJDBC_URL} =~ s/([=;])/uc sprintf("%%%02x",ord($1))/eg;
    my $dsn = "dbi:JDBC:hostname=localhost;port=" . $defaults->{port}
        . ";url=$ENV{DBDJDBC_URL}";
    my $dbh = DBI->connect($dsn, $defaults->{user}, $defaults->{password},
                           {AutoCommit => 1, PrintError => 0, }); 
    ok($dbh, "connected") or do {
        diag("Connection error: $DBI::errstr\n");
        $fatal++;
    };
    skip "Connection failed", remaining() if $fatal;

    is($dbh->get_info(6), "DBD/JDBC.pm", "SQL_DRIVER_NAME"); 
    is($dbh->get_info(17), "hsqldb", "SQL_DBMS_NAME"); 

    my $sth = $dbh->prepare("select id, value from testtable order by id"); 
    ok($sth, "prepare") or do {
        diag("Connection error: $DBI::errstr\n");
        $fatal++;
    };
    skip "Prepare failed", remaining() if $fatal;

    ok($sth->execute(), "execute") or do {
        diag $sth->errstr;
        $fatal++; 
    }; 
    skip "Execute failed", remaining() if $fatal;

    my $row = $sth->fetch(); 
    ok($row, "fetch") or do {
        diag $sth->errstr;
        $fatal++; 
    }; 
    skip "No data in row", remaining() if $fatal; 

    is($row->[0], 1, "id is 1");
    like($row->[1], qr/value/i, "read data");
    ok($sth->finish(), "finish") or diag $sth->errstr;

    ## test jdbc_longreadall
    is($dbh->{"LongReadLen"}, 80, "default dbh->LongReadLen = 80");
    ok(!$dbh->{"LongTruncOk"}, "default dbh->LongTruncOk = false");
    is($dbh->{"jdbc_longreadall"}, 1, "default dbh->jdbc_longreadall=1");

    ## Read longvarchar with defaults (except LongReadLen is set
    ## to something smaller than the data).
    $dbh->{"LongReadLen"} = 11;
    $sth = $dbh->prepare("select text from testtable order by id"); 
    ok($sth) or diag $sth->errstr;
    $sth->execute();
    $row = $sth->fetch();
    ok($row) or diag $sth->errstr;
    ok(length $row->[0] > 11, "Read more than LongReadLen characters"); 
    $sth->finish();

    ## Read longvarchar with longreadall turned off. LongReadLen
    ## should be honored.
    $dbh->{"jdbc_longreadall"} = 0; 
    $dbh->{"LongTruncOk"} = 1; 
    is($dbh->{"jdbc_longreadall"}, 0, "dbh->jdbc_longreadall=0");
    $sth = $dbh->prepare("select text from testtable order by id"); 
    is($sth->{"jdbc_longreadall"}, 0, "inherited sth->jdbc_longreadall=0");    
    $sth->execute();
    ok($sth) or diag $sth->errstr;
    $row = $sth->fetch();
    ok($row) or diag $sth->errstr;
    is(length $row->[0], 11, "Read only LongReadLen characters"); 
    $sth->finish();

    ## Shutdown hsqldb and disconnect.
    $dbh->do("shutdown") or warn $dbh->errstr;
    ok($dbh->disconnect(), "disconnect");
}; ## end skip block

exit 1;

sub remaining {
    $test_count - $test_builder->current_test;
}


END { 
    if (defined $pid) {
        stop_server($pid);
    }
}
