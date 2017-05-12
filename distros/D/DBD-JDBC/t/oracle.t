# -*-perl-*-
#
# If DBDJDBC_URL is an Oracle url, try to connect to Oracle and read
# some data. Otherwise, skip this test.

# This test will attempt to connect to Oracle and read from
# user_tables. Set DBDJDBC_URL to a valid Oracle JDBC url. For
# example,
#     jdbc:oracle:thin:@host:port:sid
#
# If you do not wish to use the user/password pair scott/tiger,
# set the DBDJDBC_USER and DBDJDBC_PASSWORD environment
# variables. If you wish to use the Oracle OCI JDBC driver, you
# will probably need to set various Oracle environment variables
# and LD_LIBRARY_PATH (or equivalent) in order to load the
# driver.

unless ($ENV{DBDJDBC_URL} and $ENV{DBDJDBC_URL} =~ /^jdbc:oracle/) {
    print "1..0 # Skipped: Oracle URL not defined\n";
    exit 0;
}


require "t/lib.pl";
use DBI;

$| = 1;

print "1..$tests\n";

my $defaults = get_defaults();

my $pid = start_server($defaults->{driver}, $defaults->{port});
if ($pid) {
    print "ok 1\n";
} else {
    warn "Failed to start server; aborting\n";
    print "not ok 1\n";
    exit 0;
}


# Give the server time to start listening to the socket before
# trying to connect.

sleep(3); 


$ENV{DBDJDBC_URL} =~ s/([=;])/uc sprintf("%%%02x",ord($1))/eg;
my $dsn = "dbi:JDBC:hostname=localhost;port=" . $defaults->{port}
        . ";url=$ENV{DBDJDBC_URL}";
my $dbh; 
if (!($dbh = DBI->connect($dsn, $defaults->{user}, $defaults->{password},
                       {AutoCommit => 1, PrintError => 0, }))) {
    warn "Connection error: $DBI::errstr\n";
    warn "Make sure your CLASSPATH includes the Oracle JDBC driver.\n"
        if ($DBI::errstr =~ /No suitable driver/);
    print "not ok 2\n";
    exit 0;
};

print "ok 2\n";

my $sth = $dbh->prepare("select * from user_tables"); 
if ($sth) {
    print "ok 3\n";
} else {
    warn "$DBI::errstr\n";
    print "not ok 3\n";
    exit 0;
}

if ($sth->execute()) {
    print "ok 4\n";
} else {
    warn "$DBI::errstr\n";
    print "not ok 4\n";
}

my $num_fields;
if ($num_fields = $sth->{NUM_OF_FIELDS}) {
    print "ok 5\n";
} else {
    warn "$DBI::errstr\n";
    print "not ok 5\n";
}

my $row;
if ($row = $sth->fetch()) {
    if ($num_fields == scalar(@$row)) {
        print "ok 6\n";
    }
    else {
        warn "Row size returned by fetch doesn't match NUM_OF_FIELDS\n";
        print "not ok 6\n"; 
    }
} else {
    if ($DBI::errstr) {
        warn "$DBI::errstr\n";
        print "not ok 6\n";
    } else {
        warn "No data found in user_tables\n";
        print "ok 6\n";
    }
}

if ($sth->finish()) {
    print "ok 7\n";
} else {
    print "not ok 7\n";
}


if ($dbh->disconnect()) {
    print "ok 8\n";
} else {
    print "not ok 8\n";
}

exit 0;

BEGIN { $tests = 8 }

END { 
    if (defined $pid) {
        stop_server($pid);
    }
}
