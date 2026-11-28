# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Dialect::PostgreSQL;

my $D = 'DBIx::QuickORM::Dialect::PostgreSQL';

# A handle that records the SQL it is given.
sub fake_dbh {
    my @sql;
    my $dbh = mock {} => (
        add => [
            do    => sub { push @sql => $_[1]; 1 },
            quote => sub { "'$_[1]'" },
        ],
    );
    return ($dbh, \@sql);
}

isa_ok($D, ['DBIx::QuickORM::Dialect'], "Inherits the defaults");
is($D->bind_limit,                                                                                                         65535,        "Wire protocol bind limit");
is([map { $D->$_ } qw/supports_savepoints supports_returning_insert supports_returning_update supports_returning_delete/], [1, 1, 1, 1], "Savepoints and RETURNING everywhere");
is($D->quote_identifier('a"b'),                                                                                            '"a""b"',     "Double-quoted identifiers");

is([$D->begin_sql],                 ['BEGIN'],                              "BEGIN without a level");
is([$D->begin_sql('SERIALIZABLE')], ['BEGIN ISOLATION LEVEL SERIALIZABLE'], "BEGIN at a level");
is($D->supports_isolation,          1,                                      "Levels can be set");

my ($dbh, $sql) = fake_dbh();
$D->init_session($dbh, 'UTC');
is($sql,                   ["SET client_encoding TO 'UTF8'", "SET TIME ZONE 'UTC'", "SET DateStyle TO 'ISO, YMD'"], "UTF-8 client encoding, the time zone by name, then ISO dates");
is($dbh->{pg_enable_utf8}, 1,                                                                                       "pg_enable_utf8 turned on");

is($D->_server_version({pg_server_version => 110004}), 110004, "The server version is pg_server_version");
like($D->new(server_version => 110000)->unique_sql, qr/i\.indnkeyatts - 1/, "Unique keys leave out INCLUDE columns on PostgreSQL 11 and later");
like($D->new(server_version => 100000)->unique_sql, qr/i\.indnatts - 1/,    "and use every index column before");
unlike($D->new(server_version => 90600)->fields_sql, qr/attidentity|attgenerated/, "Fields scan without identity or generated columns before PostgreSQL 10");
like($D->new(server_version => 100000)->fields_sql, qr/attidentity = 'a'/, "with identity columns from 10");
unlike($D->new(server_version => 110000)->fields_sql, qr/attgenerated/, "but not generated columns before 12");
like($D->new(server_version => 120000)->fields_sql, qr/attgenerated <> ''/, "and with them from 12");
is($D->error_kind(7, '40P01', 'text'), 'deadlock',              "Kinds come from the SQLSTATE");
is($D->error_kind(7, '40001', 'text'), 'serialization_failure', "including serialization failures");

subtest binary_bind_attrs => sub {
    # DBD::Pg is only suggested. Some platforms (GNU/Hurd, Haiku) have none.
    skip_all "DBD::Pg is not installed" unless eval { require DBD::Pg; 1 };
    is($D->binary_bind_attrs, {pg_type => DBD::Pg::PG_BYTEA()}, "Binary binds are bytea");
};

done_testing;
