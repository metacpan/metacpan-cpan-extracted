use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Coverage for the affinity-from-db-type-info feature:
#  - Affinity::affinity_from_sql_type_code maps standard numeric SQL type codes
#    to affinities and returns undef for unrecognized codes.
#  - Dialect::affinity_from_db_type resolves via the static name map first, then
#    the database's type-code catalog, then warns once and defaults to 'string'.

use DBIx::QuickORM::Affinity qw/affinity_from_sql_type_code/;
use DBI qw/:sql_types/;

subtest sql_type_code_map => sub {
    is(affinity_from_sql_type_code(SQL_INTEGER),  'numeric', "SQL_INTEGER -> numeric");
    is(affinity_from_sql_type_code(SQL_BIGINT),   'numeric', "SQL_BIGINT -> numeric");
    is(affinity_from_sql_type_code(SQL_SMALLINT), 'numeric', "SQL_SMALLINT -> numeric");
    is(affinity_from_sql_type_code(SQL_TINYINT),  'numeric', "SQL_TINYINT -> numeric");
    is(affinity_from_sql_type_code(SQL_DECIMAL),  'numeric', "SQL_DECIMAL -> numeric");
    is(affinity_from_sql_type_code(SQL_FLOAT),    'numeric', "SQL_FLOAT -> numeric");
    is(affinity_from_sql_type_code(SQL_DOUBLE),   'numeric', "SQL_DOUBLE -> numeric");

    is(affinity_from_sql_type_code(SQL_CHAR),        'string', "SQL_CHAR -> string");
    is(affinity_from_sql_type_code(SQL_VARCHAR),     'string', "SQL_VARCHAR -> string");
    is(affinity_from_sql_type_code(SQL_LONGVARCHAR), 'string', "SQL_LONGVARCHAR -> string");
    is(affinity_from_sql_type_code(SQL_WVARCHAR),    'string', "SQL_WVARCHAR -> string");

    is(affinity_from_sql_type_code(SQL_BINARY),        'binary', "SQL_BINARY -> binary");
    is(affinity_from_sql_type_code(SQL_VARBINARY),     'binary', "SQL_VARBINARY -> binary");
    is(affinity_from_sql_type_code(SQL_LONGVARBINARY), 'binary', "SQL_LONGVARBINARY -> binary");

    is(affinity_from_sql_type_code(SQL_BOOLEAN), 'boolean', "SQL_BOOLEAN -> boolean");
    is(affinity_from_sql_type_code(SQL_BIT),     'boolean', "SQL_BIT -> boolean");

    is(affinity_from_sql_type_code(SQL_TYPE_DATE),      'string', "SQL_TYPE_DATE -> string");
    is(affinity_from_sql_type_code(SQL_TYPE_TIMESTAMP), 'string', "SQL_TYPE_TIMESTAMP -> string");

    is(affinity_from_sql_type_code(999999), undef, "an unrecognized code returns undef");
    is(affinity_from_sql_type_code(undef),  undef, "undef code returns undef");
};

subtest dialect_affinity_from_db_type => sub {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
    require DBIx::QuickORM::Dialect::SQLite;

    my $dir  = tempdir(CLEANUP => 1);
    my $dbh  = DBI->connect("dbi:SQLite:dbname=$dir/aff.sqlite", '', '', {RaiseError => 1, PrintError => 0});
    my $dia  = DBIx::QuickORM::Dialect::SQLite->new(dbh => $dbh, db_name => 'main');

    # 1. Static name-map fast path: no warning.
    is(
        warnings { is($dia->affinity_from_db_type('integer'), 'numeric', "name-map hit -> numeric") },
        [],
        "a name-map hit does not warn",
    );
    is($dia->affinity_from_db_type('VARCHAR(255)'), 'string', "name-map hit strips size and resolves");

    # 2. Catalog fallback: a name absent from the static map but present in the
    #    (here injected) type-code catalog resolves via the numeric code, no warn.
    $dia->{db_type_code_map} = { weirdint => DBI::SQL_INTEGER(), oddblob => DBI::SQL_VARBINARY() };
    is(
        warnings {
            is($dia->affinity_from_db_type('weirdint'), 'numeric', "catalog code SQL_INTEGER -> numeric");
            is($dia->affinity_from_db_type('oddblob'),  'binary',  "catalog code SQL_VARBINARY -> binary");
        },
        [],
        "a catalog-code resolution does not warn",
    );

    # 3. Unknown to both the name map and the catalog: warn once, default string.
    my $warns = warnings { is($dia->affinity_from_db_type('totally_bogus_xyz'), 'string', "unknown type defaults to string") };
    is(scalar(@$warns), 1, "an unknown type warns exactly once");
    like($warns->[0], qr/does not recognize the database type 'totally_bogus_xyz'/, "warning names the type");
    like($warns->[0], qr{file a ticket}, "warning asks for a ticket");

    # Cached: a second lookup of the same unknown type does not warn again.
    is(
        warnings { is($dia->affinity_from_db_type('totally_bogus_xyz'), 'string', "still string on the second call") },
        [],
        "the unknown-type warning is not repeated",
    );

    $dbh->disconnect;
};

done_testing;
