use DBI;
unlink "t/test.db";
my $dbh;

if ( $ENV{DSN} ) {
    $dbh = DBI->connect(
        $ENV{DSN}, $ENV{DB_USER}, $ENV{DB_PASS},
        { AutoCommit => 0, RaiseError => 1, }
    );
}
else {
    $dbh = DBI->connect(
        'dbi:SQLite:dbname=t/test.db', '', '',
        { AutoCommit => 0, RaiseError => 1, }
    );
}
return $dbh;

__DATA__
