use Test2::V0;

# DSN construction per dialect. The MySQL family must emit 'database=' for
# the database name (DBD::MariaDB rejects 'dbname='; DBD::mysql accepts
# both), while PostgreSQL and SQLite keep 'dbname='.

package My::Test::DBConfig {
    sub new { my $class = shift; bless {@_}, $class }
    sub db_name    { $_[0]->{db_name} }
    sub host       { $_[0]->{host} }
    sub port       { $_[0]->{port} }
    sub socket     { $_[0]->{socket} }
    sub dbi_driver { $_[0]->{dbi_driver} }
}

sub db_config { My::Test::DBConfig->new(db_name => 'mydb', host => 'db.example.com', port => 1234, @_) }

subtest sqlite => sub {
    skip_all "DBD::SQLite is required" unless eval { require DBD::SQLite; 1 };
    require DBIx::QuickORM::Dialect::SQLite;

    my $dsn = DBIx::QuickORM::Dialect::SQLite->dsn(db_config());
    is($dsn, 'dbi:SQLite:dbname=mydb', "SQLite DSN uses dbname=");
};

subtest postgresql => sub {
    skip_all "DBD::Pg is required" unless eval { require DBD::Pg; 1 };
    require DBIx::QuickORM::Dialect::PostgreSQL;

    my $dsn = DBIx::QuickORM::Dialect::PostgreSQL->dsn(db_config());
    is($dsn, 'dbi:Pg:dbname=mydb;host=db.example.com;port=1234;', "PostgreSQL DSN uses dbname=");
};

subtest mysql_family => sub {
    my $mariadb = eval { require DBD::MariaDB; 1 };
    my $mysql   = eval { require DBD::mysql; 1 };
    skip_all "DBD::MariaDB or DBD::mysql is required" unless $mariadb || $mysql;

    require DBIx::QuickORM::Dialect::MySQL;

    if ($mariadb) {
        my $dsn = DBIx::QuickORM::Dialect::MySQL->dsn(db_config(dbi_driver => 'DBD::MariaDB'));
        is($dsn, 'dbi:MariaDB:database=mydb;host=db.example.com;port=1234;', "MySQL DSN uses database= for DBD::MariaDB");
    }

    if ($mysql) {
        my $dsn = DBIx::QuickORM::Dialect::MySQL->dsn(db_config(dbi_driver => 'DBD::mysql'));
        is($dsn, 'dbi:mysql:database=mydb;host=db.example.com;port=1234;', "MySQL DSN uses database= for DBD::mysql");
    }

    my $socket_dsn = DBIx::QuickORM::Dialect::MySQL->dsn(db_config(socket => '/tmp/mysql.sock', dbi_driver => $mariadb ? 'DBD::MariaDB' : 'DBD::mysql'));
    like($socket_dsn, qr/^dbi:(?:MariaDB|mysql):database=mydb;(?:mariadb|mysql)_socket=\/tmp\/mysql\.sock$/, "socket DSN keeps database= and the driver socket field");
};

subtest duckdb => sub {
    skip_all "DBD::DuckDB is required" unless eval { require DBD::DuckDB; 1 };
    require DBIx::QuickORM::Dialect::DuckDB;

    my $dsn = DBIx::QuickORM::Dialect::DuckDB->dsn(db_config());
    is($dsn, 'dbi:DuckDB:dbname=mydb', "DuckDB DSN uses dbname=");
};

done_testing;
