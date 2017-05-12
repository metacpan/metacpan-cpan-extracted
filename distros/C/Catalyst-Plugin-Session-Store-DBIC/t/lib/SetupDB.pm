package SetupDB;

use strict;
use warnings;

# Create the database
my $db_file = $TestApp::DB_FILE;
unlink $db_file if -e $db_file;

my $dbh = DBI->connect("dbi:SQLite:$db_file") or die $DBI::errstr;
my $sql = q{
    CREATE TABLE sessions (
        id      CHAR(72) PRIMARY KEY,
        data    TEXT,
        expires INTEGER
    );
};
$dbh->do($_) for split /;/, $sql;
$dbh->disconnect;

1;
