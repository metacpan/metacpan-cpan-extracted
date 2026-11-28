# Test origin: AI
use Test2::V0;

use DBD::SQLite::Constants qw/DBD_SQLITE_STRING_MODE_UNICODE_STRICT/;

use DBIx::QuickORM::Dialect::SQLite;

my $D = 'DBIx::QuickORM::Dialect::SQLite';

isa_ok($D, ['DBIx::QuickORM::Dialect'], "Inherits the defaults");
is($D->namespace(undef),                                                                                                   'main',                          "The namespace is always main");
is([map { $D->$_ } qw/supports_savepoints supports_returning_insert supports_returning_update supports_returning_delete/], [1, 1, 1, 1],                    "Savepoints and RETURNING everywhere");
is($D->bind_limit,                                                                                                         999,                             "SQLite's old bind limit");
is([$D->datetime_format],                                                                                                  ['DateTime::Format::Pg', undef], "DateTime::Format::Pg parses dates; no formatter, so the type formats them");

like(dies { $D->begin_sql('SERIALIZABLE') }, qr/^The SQLite dialect cannot set a transaction isolation level/, "No isolation level");
is($D->supports_isolation, 0, "and supports_isolation says so");

my @sql;
my $dbh = mock {} => (add => [do => sub { push @sql => $_[1]; 1 }]);
$D->init_session($dbh, 'America/New_York');
is(\@sql,                                ['PRAGMA foreign_keys = ON'],          "Foreign keys are turned on, the only SQL sent");
is($dbh->{sqlite_string_mode},           DBD_SQLITE_STRING_MODE_UNICODE_STRICT, "Strict Unicode string mode, and no session time zone set");
is($dbh->{sqlite_extended_result_codes}, 1,                                     "Extended result codes");

my %kinds = (5 => 'lock_timeout', 517 => 'lock_timeout', 6 => 'lock_timeout', 2067 => 'unique_violation', 1555 => 'unique_violation', 787 => 'foreign_key_violation', 1299 => 'not_null_violation', 275 => 'check_violation');
is($D->error_kind($_, 'S1000', 'text'), $kinds{$_}, "native $_ is $kinds{$_}") for sort keys %kinds;
is($D->error_kind(19, 'S1000', 'text'), undef,      "A plain SQLITE_CONSTRAINT has no kind");

my %affinity = (
    'INT'              => 'numeric',
    'BIGINT UNSIGNED'  => 'numeric',
    'POINT'            => 'numeric',    # INT inside
    'VARCHAR(10)'      => 'string',
    'CLOB'             => 'string',
    'TEXT'             => 'string',
    'BLOB'             => 'binary',
    ''                 => 'binary',
    'DOUBLE PRECISION' => 'numeric',
    'FLOAT'            => 'numeric',
    'DATE'             => 'string',
    'BOOLEAN'          => 'boolean',
    'JSON'             => 'string',
    'WHATEVER'         => 'numeric',
);
is($D->affinity($_),    $affinity{$_},                                     "affinity of '$_'") for sort keys %affinity;
is($D->field_facts(''), {db_type => '', type => '', affinity => 'binary'}, "A field with no declared type");

my $file = mock {} => (add => [sqlite_db_filename => sub { '/tmp/x.db' }]);
my $mem  = mock {} => (add => [sqlite_db_filename => sub { '' }]);
is($D->supports_second_connection($file), 1, "A database file can be opened by a second connection");
is($D->supports_second_connection($mem),  0, "an in-memory database cannot");

done_testing;
