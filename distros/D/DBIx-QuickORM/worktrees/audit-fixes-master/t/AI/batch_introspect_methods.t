use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Unit tests for the batch-introspection helpers added to the dialects. The
# contract of the refactor is: the whole-database sweep methods (_fetch_all_*)
# produce, per table, exactly the rows the retained single-table fallbacks
# (_query_*) produce, and the pre-fetched-data derivation helpers
# (_pk_from_xinfo / _rowid_alias_from) match the original query-based helpers
# (_primary_key / _rowid_alias_column). If those equivalences hold, the batch
# path and the per-table path build identical schema objects.

require DBIx::QuickORM;

my @TABLES = qw/owners pets memberships gen wr/;

subtest sqlite => sub {
    skip_all "DBD::SQLite required" unless eval { require DBD::SQLite; 1 };

    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:SQLite:dbname=$dir/methods.sqlite";
    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE owners (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, note TEXT)');
        $dbh->do('CREATE TABLE pets (id INTEGER PRIMARY KEY, owner_id INTEGER REFERENCES owners(id), name TEXT NOT NULL, tag INTEGER UNIQUE)');
        $dbh->do('CREATE INDEX pets_owner_idx ON pets(owner_id)');
        $dbh->do('CREATE TABLE memberships (owner_id INTEGER NOT NULL, pet_id INTEGER NOT NULL, kind TEXT, PRIMARY KEY (owner_id, pet_id))');
        $dbh->do('CREATE TABLE gen (id INTEGER PRIMARY KEY, base INTEGER NOT NULL, doubled INTEGER GENERATED ALWAYS AS (base * 2) VIRTUAL)');
        $dbh->do('CREATE TABLE wr (code TEXT PRIMARY KEY, total INTEGER) WITHOUT ROWID');
        $dbh->disconnect;
    }

    my $con     = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    my $dialect = $con->dialect;

    my $all_xinfo = $dialect->_fetch_all_xinfo;
    my $all_idx   = $dialect->_fetch_all_index_info;
    my $all_fks   = $dialect->_fetch_all_fks;
    my $all_ddl   = $dialect->_fetch_all_ddl;

    # Every permanent table is keyed under the is_temp=0 dimension. The sweep
    # also surfaces SQLite-internal tables (e.g. sqlite_sequence from the
    # AUTOINCREMENT column); build_tables_from_db skips those by name, so ignore
    # them here too.
    is([sort grep { $_ !~ /^sqlite_/ } keys %{$all_xinfo->{0}}], [sort @TABLES], "xinfo sweep grouped all permanent tables under is_temp=0");
    is($all_xinfo->{1}, undef, "no temporary tables, so no is_temp=1 group");

    for my $tbl (@TABLES) {
        is($all_xinfo->{0}{$tbl}, $dialect->_query_xinfo($tbl), "xinfo: batch slice == single-table fallback for $tbl");
        is($all_idx->{0}{$tbl} // [], $dialect->_query_index_info($tbl), "index info: batch slice == fallback for $tbl");
        is($all_fks->{0}{$tbl} // [], $dialect->_query_fks($tbl), "foreign keys: batch slice == fallback for $tbl");

        is(
            [$dialect->_pk_from_xinfo($all_xinfo->{0}{$tbl})],
            [$dialect->_primary_key($tbl)],
            "primary key derived from pre-fetched xinfo matches _primary_key for $tbl",
        );

        is(
            $dialect->_rowid_alias_from($all_xinfo->{0}{$tbl}, $all_ddl->{$tbl}),
            $dialect->_rowid_alias_column($tbl),
            "rowid alias derived from pre-fetched xinfo/DDL matches _rowid_alias_column for $tbl",
        );
    }

    # Spot-check the derivations resolve the way the schema layer expects.
    is([$dialect->_pk_from_xinfo($all_xinfo->{0}{memberships})], ['owner_id', 'pet_id'], "composite PK ordered correctly");
    is($dialect->_rowid_alias_from($all_xinfo->{0}{owners}, $all_ddl->{owners}), 'id', "INTEGER PRIMARY KEY aliases rowid");
    is($dialect->_rowid_alias_from($all_xinfo->{0}{wr}, $all_ddl->{wr}), undef, "WITHOUT ROWID table has no rowid alias");
    is($dialect->_rowid_alias_from($all_xinfo->{0}{memberships}, $all_ddl->{memberships}), undef, "composite PK has no rowid alias");
};

subtest duckdb => sub {
    skip_all "DBD::DuckDB required" unless eval { require DBD::DuckDB; 1 };

    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:DuckDB:dbname=$dir/methods.duckdb";
    my $built = eval {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0, AutoCommit => 1});
        $dbh->do('CREATE SEQUENCE owners_seq');
        $dbh->do(q{CREATE TABLE owners (id INTEGER PRIMARY KEY DEFAULT nextval('owners_seq'), name TEXT NOT NULL UNIQUE, note TEXT)});
        $dbh->do('CREATE TABLE pets (id INTEGER PRIMARY KEY, owner_id INTEGER REFERENCES owners(id), name TEXT NOT NULL, tag INTEGER UNIQUE)');
        $dbh->do('CREATE TABLE memberships (owner_id INTEGER NOT NULL, pet_id INTEGER NOT NULL, kind TEXT, PRIMARY KEY (owner_id, pet_id))');
        $dbh->disconnect;
        1;
    };
    skip_all "DuckDB unavailable: $@" unless $built;

    my $con     = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    my $dialect = $con->dialect;

    # Primary-key membership comes from the shared constraint sweep, the same way
    # build_tables_from_db feeds it to _fetch_all_columns.
    my $all_con = $dialect->_fetch_all_constraints;
    my %pk_by_table;
    for my $tname (keys %$all_con) {
        for my $con_row (@{$all_con->{$tname}}) {
            next unless $con_row->{constraint_type} eq 'PRIMARY KEY';
            $pk_by_table{$tname}{$_} = 1 for @{$con_row->{constraint_column_names} // []};
        }
    }

    my $all_columns = $dialect->_fetch_all_columns(\%pk_by_table);

    # The duckdb_columns()->pragma-shape mapping must match what pragma_table_info
    # (the single-table fallback's source) reports for the fields the column
    # builder consumes: name, cid (order), notnull, type, and PK-ness.
    my $norm = sub {
        my ($rows) = @_;
        return [map { [$_->{name}, $_->{cid}, ($_->{notnull} ? 1 : 0), ($_->{pk} ? 1 : 0), $_->{type}] } @$rows];
    };

    for my $tbl (qw/owners pets memberships/) {
        is(
            $norm->($all_columns->{$tbl}),
            $norm->($dialect->_query_columns($tbl)),
            "duckdb_columns() batch mapping matches pragma_table_info for $tbl",
        );
    }

    # Constraint and index sweeps carry an extra table_name column the
    # single-table fallbacks omit, so compare the logical content per table.
    my $cnorm = sub {
        [sort map {
            join('|', $_->{constraint_type}, join(',', @{$_->{constraint_column_names} // []}),
                 $_->{referenced_table} // '', join(',', @{$_->{referenced_column_names} // []}))
        } @{$_[0]}];
    };
    for my $tbl (qw/owners pets memberships/) {
        is($cnorm->($all_con->{$tbl} // []), $cnorm->($dialect->_query_constraints($tbl)), "constraints: batch slice == fallback for $tbl");
    }

    my $inorm = sub {
        [sort map {
            my $e = $_->{expressions};
            my $es = ref($e) eq 'ARRAY' ? join(',', @$e) : (defined $e ? $e : '');
            join('|', $_->{index_name} // '', $_->{is_unique} ? 1 : 0, $es)
        } @{$_[0]}];
    };
    my $all_idx = $dialect->_fetch_all_indexes;
    is($inorm->($all_idx->{pets} // []), $inorm->($dialect->_query_indexes('pets')), "indexes: batch slice == fallback for pets");
};

done_testing;
