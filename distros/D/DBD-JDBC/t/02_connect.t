# -*-perl-*-
#
# Try to start the server, connect, and disconnect.  


require "t/lib.pl";
use DBI;
use Test::More;
$| = 1;

BEGIN {
    plan tests => 5;
}

$ENV{DBDJDBC_URL} = "jdbc:hsqldb:file:t/hsqldb/testdb";
my $pid; 
SKIP: {
    my $fatal = 0;

    my $defaults = get_defaults();
    ok($defaults && $defaults->{driver}) or $fatal++; 
    skip "No driver configuration found for $ENV{DBDJDBC_URL}", 4 if $fatal;

    $pid = start_server($defaults->{driver}, $defaults->{port});
    ok($pid, "server started") or do {
        diag("Server failed to start; remaining tests will fail"); 
        $fatal++;
    };
    skip "Server failed", 3 if $fatal;

    # Give the server time to start listening to the socket before
    # trying to connect.
    sleep(3); 

    $ENV{DBDJDBC_URL} =~ s/([=;])/uc sprintf("%%%02x",ord($1))/eg;
    my $dsn = "dbi:JDBC:hostname=localhost;port=" . $defaults->{port} . 
        ";url=$ENV{DBDJDBC_URL}";
    my $dbh = DBI->connect($dsn, $defaults->{user}, $defaults->{password},
                           {AutoCommit => 1, PrintError => 0, }); 
    ok($dbh, "connected") or do {
        my $msg = "Connection error: $DBI::errstr\n";
        $msg .= "Make sure your CLASSPATH includes your JDBC driver.\n"
            if ($DBI::errstr =~ /No suitable driver/);
        diag($msg);
        $fatal++;
    };
    skip "Connect failed", 2 if $fatal;

    # Required for hsqldb shutdown.
    $dbh->do("shutdown") or warn $dbh->errstr;

    ok($dbh->disconnect(), "disconnected") or diag $DBI::errstr;

    ok(stop_server($pid), "stop server") 
        or diag "Server may not have been stopped\n";
};


# Catch unexpected errors and kill the server anyway.
END { if ($pid) { stop_server($pid); } }
