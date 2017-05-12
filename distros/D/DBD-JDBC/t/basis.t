# -*-perl-*-
#
# If DBDJDBC_URL is a BASIS url, try to connect to BASIS and read
# some data. Otherwise, skip this test.


# This test will attempt to read some data from
# <tour.all>client. If you don't have the tour database
# installed, this test will fail. When you set the DBDJDBC_URL
# environment varible, include tour_all in the database list. For
# example,
#    jdbc:opentext:basis://host:port/tour_all?host.user=u&host.password=p
# where host, port, u, and p must be replaced with the location
# of your OPIRPC service and a valid host username and password.
# If you do not wish to connect using the BASIS user user1, you
# should also set the DBDJDBC_USER and DBDJDBC_PASSWORD
# environment variables.

require "t/lib.pl";
use DBI;
use Test::More;
$| = 1;

BEGIN {
    plan skip_all => "BASIS URL not defined" 
        unless ($ENV{DBDJDBC_URL} and 
                $ENV{DBDJDBC_URL} =~ /^jdbc:opentext:basis/);
    plan tests => 9;
}

my $pid;
SKIP: {
    my $defaults = get_defaults();
    my $fatal = 0;

    $pid = start_server($defaults->{driver}, $defaults->{port});
    ok($pid, "server started") or $fatal++;
    skip "Server failed to start", 8 if $fatal;
    # Give the server time to attach to the socket before trying to connect.
    sleep(3); 

    like($ENV{DBDJDBC_URL}, qr/tour_all/i, "tour_all in URL") or do {
        diag("The URL must include 'tour_all'; remaining tests will fail"); 
        $fatal++;
    };
    skip "Missing database in url", 8 if $fatal;

    $ENV{DBDJDBC_URL} =~ s/([=;])/uc sprintf("%%%02x",ord($1))/eg;
    my $dsn = "dbi:JDBC:hostname=localhost;port=" . $defaults->{port}
        . ";url=$ENV{DBDJDBC_URL}";
    my $dbh = DBI->connect($dsn, $defaults->{user}, $defaults->{password},
                           {AutoCommit => 1, PrintError => 0, }); 
    ok($dbh, "connected") or do {
        my $msg = "";
        $msg = "Make sure your CLASSPATH includes the BASIS JDBC driver.\n"
            if ($DBI::errstr =~ /No suitable driver/);
        $msg = "Check the host and port values in your URL and ensure that "
            . "OPIRPC is running at that location.\n"
            if ($DBI::errstr =~ /Server communications error/);            
        diag("Connection error: $DBI::errstr\n$msg");
        $fatal++;
    };
    skip "Connect failed", 6 if $fatal;


    my $sth = $dbh->prepare("select id, cname from client order by id"); 
    ok ($sth, "prepare") or do {
        my $msg = "";
        $msg = "The <TOUR.ALL> database model must be available in order to "
            . "complete this test\n"
            if ($DBI::errstr =~ /database model does not exist/); 
        diag("Connection error: $DBI::errstr\n$msg");
        $fatal++;
    };
    skip "Prepare failed", 5 if $fatal;

    ok ($sth->execute(), "execute") or do {
        diag $sth->errstr;
        $fatal++; 
    }; 
    skip "Execute failed", 4 if $fatal;

    my $row = $sth->fetch(); 
    ok ($row, "fetch") or do {
        diag $sth->errstr;
        $fatal++; 
    }; 
    skip "Fetch failed", 3 if $fatal;

    like($row->[1], qr/\w+, \w+/, "read data");

    ok($sth->finish(), "finish");

    ok($dbh->disconnect(), "disconnect");
}; 

1; 

END { 
    if (defined $pid) {
        stop_server($pid);
    }
}

