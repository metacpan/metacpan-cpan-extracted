# create the database
my $db_file = $ENV{TESTAPP_DB_FILE};
unlink $db_file if -e $db_file;

my $dbh = DBI->connect( "dbi:SQLite:$db_file" ) or die $DBI::errstr;
my $sql = q{
    CREATE TABLE user (
        id       INTEGER PRIMARY KEY,
        username TEXT,
        password TEXT,
        session_data TEXT
    );
    CREATE TABLE role (
        id   INTEGER PRIMARY KEY,
        role TEXT
    );
    CREATE TABLE user_role (
        id   INTEGER PRIMARY KEY,
        user INTEGER,
        role INTEGER
    );

    INSERT INTO user VALUES (1, 'andyg', 'hackme', NULL);
    INSERT INTO user VALUES (2, 'sri', 'sacqLGlWjDRw2', NULL);
    INSERT INTO user VALUES (3, 'chansen', 'cc9597d31f0503bded5df310eb5f28fb4d49fb0f', NULL);
    INSERT INTO user VALUES (4, 'nuffin', 'much', NULL);
    INSERT INTO user VALUES (5, 'rusty', '{SSHA}ncHs4XYmQKJqL+VuyNQzQjwRXfvu6noa', NULL);
    INSERT INTO role VALUES (1, 'admin');
    INSERT INTO role VALUES (2, 'user');
    INSERT INTO user_role VALUES (1, 1, 1);
    INSERT INTO user_role VALUES (2, 1, 2);
    INSERT INTO user_role VALUES (3, 4, 2)
};
$dbh->do( $_ ) for split /;/, $sql;
$dbh->disconnect;