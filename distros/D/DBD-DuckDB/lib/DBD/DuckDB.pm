package DBD::DuckDB {

    use strict;
    use warnings;
    use DBI ();

    use DBD::DuckDB::FFI qw(duckdb_library_version);

    our $VERSION = '0.14';
    $VERSION =~ tr/_//d;

    our $drh;
    our $methods_are_installed;

    DBD::DuckDB::FFI->init unless $drh;

    sub driver {

        return $drh if $drh;

        DBI->setup_driver('DBD::DuckDB');

        unless ($methods_are_installed) {

            DBD::DuckDB::db->install_method('x_duckdb_appender');
            DBD::DuckDB::db->install_method('x_duckdb_version');

            DBD::DuckDB::db->install_method('x_duckdb_read_csv');
            DBD::DuckDB::db->install_method('x_duckdb_read_json');
            DBD::DuckDB::db->install_method('x_duckdb_read_xlsx');

            $methods_are_installed++;

        }

        my ($class, $attr) = @_;
        $class .= "::dr";

        my $lib_version = duckdb_library_version();

        $drh = DBI::_new_drh(
            $class,
            {
                Name        => 'DuckDB',
                Version     => $VERSION,
                Attribution => "DBD::DuckDB $VERSION using DuckDB $lib_version by Giuseppe Di Terlizzi",

            }
        ) or return undef;
        return $drh;
    }

    sub CLONE { undef $drh }

}


package    # hide from PAUSE
    DBD::DuckDB::dr {

    use strict;
    use warnings;
    use DBI;
    use base qw(DBD::_::dr);

    use DBD::DuckDB::FFI qw(:all);

    our $imp_data_size = 0;

    sub connect {

        my ($drh, $dsn, $user, $pass, $attr) = @_;

        my $driver_prefix = 'duckdb_';

        foreach my $var (split /;/, $dsn) {

            my ($attr_name, $attr_value) = split '=', $var, 2;
            return $drh->set_err($DBI::stderr, "Can't parse DSN part '$var'") unless defined $attr_value;

            $attr_name = $driver_prefix . $attr_name unless $attr_name =~ /^$driver_prefix/o;

            $attr->{$attr_name} = $attr_value;
        }

        $attr->{duckdb_dbname}                   //= ':memory:';
        $attr->{duckdb_checkpoint_on_disconnect} //= 1;

        my $dbh = DBI::_new_dbh($drh, {Name => $dsn});

        my ($db, $conn, $rc);

        $rc = duckdb_open($attr->{duckdb_dbname}, \$db);

        return $dbh->set_err(1, "Can't connect to $dsn: duckdb_open failed") if $rc;

        $rc = duckdb_connect($db, \$conn);
        return $dbh->set_err(1, "Can't connect to $dsn: duckdb_connect failed") if $rc;

        $dbh->{duckdb_conn}    = $conn;
        $dbh->{duckdb_db}      = $db;
        $dbh->{duckdb_version} = duckdb_library_version();

        $dbh->STORE('Active', 1);

        return $dbh;

    }

    sub disconnect_all {1}

    sub STORE {
        my ($drh, $attr, $value) = @_;

        if ($attr =~ /^duckdb_/) {
            $drh->{$attr} = $value;
            return 1;
        }

        $drh->SUPER::STORE($attr, $value);
    }

    sub FETCH {
        my ($drh, $attr) = @_;

        if ($attr =~ /^duckdb_/) {
            return $drh->{$attr};
        }

        $drh->SUPER::FETCH($attr);
    }

}

package    # hide from PAUSE
    DBD::DuckDB::db {

    use strict;
    use warnings;
    use DBI  qw(:sql_types);
    use base qw(DBD::_::db);

    use DBD::DuckDB::FFI qw(:all);
    use DBD::DuckDB::Appender;


    our $imp_data_size = 0;

    sub x_duckdb_version { DBD::DuckDB::FFI::duckdb_library_version() }

    sub x_duckdb_appender {

        my ($dbh, $table, $schema) = @_;

        Carp::croak('Usage: $dbh->duckdb_appender($table [, $schema ])') unless $table;
        $schema //= 'main';

        return DBD::DuckDB::Appender->new(schema => $schema, table => $table, dbh => $dbh);

    }

    sub x_duckdb_read_json {

        my ($dbh, $file, $params) = @_;

        # read_json(VARCHAR,
        #     convert_strings_to_integers : BOOLEAN,
        #     maximum_sample_files : BIGINT,
        #     timestamp_format : VARCHAR,
        #     field_appearance_threshold : DOUBLE,
        #     timestampformat : VARCHAR,
        #     map_inference_threshold : BIGINT,
        #     date_format : VARCHAR,
        #     filename : ANY,
        #     union_by_name : BOOLEAN,
        #     compression : VARCHAR,
        #     maximum_depth : BIGINT,
        #     columns : ANY,
        #     sample_size : BIGINT,
        #     hive_types : ANY,
        #     hive_types_autocast : BOOLEAN,
        #     maximum_object_size : UINTEGER,
        #     format : VARCHAR,
        #     ignore_errors : BOOLEAN,
        #     hive_partitioning : BOOLEAN,
        #     auto_detect : BOOLEAN,
        #     records : VARCHAR,
        #     dateformat : VARCHAR
        # )

        my @placeholders = map {"$_ = ?"} sort keys %$params;
        my @bind         = map { $params->{$_} } sort keys %$params;

        unshift @bind,         $file;
        unshift @placeholders, '?';

        my $sql = sprintf 'SELECT * FROM read_json(%s)', join(', ', @placeholders);

        my $sth = $dbh->prepare($sql) or return;
        $sth->execute(@bind)          or return;
        return $sth;

    }

    sub x_duckdb_read_csv {

        my ($dbh, $file, $params) = @_;

        # read_csv(VARCHAR
        #     thousands : VARCHAR
        #     strict_mode : BOOLEAN
        #     dtypes : ANY
        #     column_types : ANY
        #     null_padding : BOOLEAN
        #     column_names : VARCHAR[]
        #     buffer_size : UBIGINT
        #     parallel : BOOLEAN
        #     force_not_null : VARCHAR[]
        #     hive_types : ANY
        #     new_line : VARCHAR
        #     files_to_sniff : BIGINT
        #     dateformat : VARCHAR
        #     delim : VARCHAR
        #     sep : VARCHAR
        #     decimal_separator : VARCHAR
        #     nullstr : ANY
        #     escape : VARCHAR
        #     compression : VARCHAR
        #     encoding : VARCHAR
        #     hive_types_autocast : BOOLEAN
        #     all_varchar : BOOLEAN
        #     columns : ANY
        #     hive_partitioning : BOOLEAN
        #     auto_detect : BOOLEAN
        #     comment : VARCHAR
        #     quote : VARCHAR
        #     max_line_size : VARCHAR
        #     store_rejects : BOOLEAN
        #     union_by_name : BOOLEAN
        #     header : BOOLEAN
        #     types : ANY
        #     skip : BIGINT
        #     filename : ANY
        #     sample_size : BIGINT
        #     timestampformat : VARCHAR
        #     normalize_names : BOOLEAN
        #     ignore_errors : BOOLEAN
        #     names : VARCHAR[]
        #     allow_quoted_nulls : BOOLEAN
        #     maximum_line_size : VARCHAR
        #     rejects_table : VARCHAR
        #     auto_type_candidates : ANY
        #     rejects_scan : VARCHAR
        #     rejects_limit : BIGINT
        # )

        my @placeholders = map {"$_ = ?"} sort keys %$params;
        my @bind         = map { $params->{$_} } sort keys %$params;

        unshift @bind,         $file;
        unshift @placeholders, '?';

        my $sql = sprintf 'SELECT * FROM read_csv(%s)', join(', ', @placeholders);

        my $sth = $dbh->prepare($sql) or return;
        $sth->execute(@bind)          or return;
        return $sth;

    }

    sub x_duckdb_read_xlsx {

        my ($dbh, $file, $params) = @_;

        # read_xlsx(VARCHAR
        #     normalize_names : BOOLEAN
        #     empty_as_varchar : BOOLEAN
        #     stop_at_empty : BOOLEAN
        #     sheet : VARCHAR
        #     range : VARCHAR
        #     ignore_errors : BOOLEAN
        #     all_varchar : BOOLEAN
        #     header : BOOLEAN
        # )

        my @placeholders = map {"$_ = ?"} sort keys %$params;
        my @bind         = map { $params->{$_} } sort keys %$params;

        unshift @bind,         $file;
        unshift @placeholders, '?';

        my $sql = sprintf 'SELECT * FROM read_xlsx(%s)', join(', ', @placeholders);

        my $sth = $dbh->prepare($sql) or return;
        $sth->execute(@bind)          or return;
        return $sth;

    }

    sub get_info {
        my ($dbh, $info_type) = @_;

        require DBD::DuckDB::GetInfo;
        my $v = $DBD::DuckDB::GetInfo::info{int($info_type)};
        $v = $v->($dbh) if ref $v eq 'CODE';
        return $v;
    }

    sub disconnect {

        my $dbh = shift;

        my $conn = delete $dbh->{duckdb_conn};
        my $db   = delete $dbh->{duckdb_db};

        if ($dbh->FETCH('duckdb_checkpoint_on_disconnect') && $dbh->FETCH('AutoCommit')) {
            my $rc = duckdb_query($conn, 'CHECKPOINT');
            return $dbh->set_err(1, 'failed to save checkpoint') if $rc;
        }

        duckdb_disconnect(\$conn);
        duckdb_close(\$db);

        $dbh->STORE('Active', 0);

        return 1;

    }

    sub prepare {

        my ($dbh, $sql, $attr) = @_;

        my ($outer, $sth) = DBI::_new_sth($dbh, {Statement => $sql});
        return $sth unless ($sth);

        my $rc = duckdb_prepare($dbh->{duckdb_conn}, $sql, \my $stmt);

        if ($rc) {
            $dbh->set_err(1, duckdb_prepare_error($stmt) // 'duckdb_prepare failed');
            return;
        }

        $sth->{duckdb_stmt} = $stmt;
        return $outer;

    }

    sub quote {

        my ($self, $value, $data_type) = @_;

        return "NULL" unless defined $value;

        $value =~ s/'/''/g;
        return "'$value'";

    }

    sub ping {

        my $dbh = shift;

        my $file = $dbh->FETCH('duckdb_dbname');

        return 0 if $file && !-f $file;
        return $dbh->FETCH('Active') ? 1 : 0;

    }

    # SQL/CLI (ISO/IEC JTC 1/SC 32 N 0595), 6.63 Tables
    sub table_info {

        my ($dbh, $catalog, $schema, $table, $type, $attr) = @_;

        my @where = ();
        my @bind  = ();

        my $like = sub {

            my ($col, $val) = @_;

            return if !defined $val || $val eq '' || $val eq '%';

            push @where, ($val =~ /[%_]/) ? "$col LIKE ? ESCAPE '\\'" : "$col = ?";
            push @bind, $val;

        };

        $type = 'BASE TABLE' if (defined $type && uc($type) eq 'TABLE');

        $like->('table_catalog', $catalog) if defined $catalog;
        $like->('table_schema',  $schema)  if defined $schema;
        $like->('table_name',    $table)   if defined $table;
        $like->('table_type',    uc $type) if defined $type;

        my $sql = q{
            SELECT
                table_catalog AS TABLE_CAT,
                table_schema  AS TABLE_SCHEM,
                table_name    AS TABLE_NAME,
                CASE table_type WHEN 'BASE TABLE' THEN 'TABLE' ELSE table_type END AS TABLE_TYPE,
                CAST(NULL AS VARCHAR) AS REMARKS
            FROM information_schema.tables
        };

        $sql .= ' WHERE ' . join(' AND ', @where) if @where;
        $sql .= ' ORDER BY TABLE_TYPE, TABLE_SCHEM, TABLE_NAME';

        my $sth = $dbh->prepare($sql) or return;
        $sth->execute(@bind)          or return;
        return $sth;

    }

    sub primary_key_info {

        my ($dbh, $catalog, $schema, $table) = @_;

        my @where = ();
        my @bind  = ();

        my $like = sub {

            my ($col, $val) = @_;

            return if !defined $val || $val eq '' || $val eq '%';

            push @where, ($val =~ /[%_]/) ? "$col LIKE ? ESCAPE '\\'" : "$col = ?";
            push @bind, $val;

        };

        $like->('kc.table_catalog', $catalog) if defined $catalog;
        $like->('kc.table_schema',  $schema)  if defined $schema;
        $like->('kc.table_name',    $table)   if defined $table;

        my $sql = q{
            SELECT
                kc.table_catalog    AS TABLE_CAT,
                kc.table_schema     AS TABLE_SCHEM,
                kc.table_name       AS TABLE_NAME,
                kc.column_name      AS COLUMN_NAME,
                kc.ordinal_position AS KEY_SEQ,
                tc.constraint_name  AS PK_NAME
            FROM information_schema.table_constraints   AS tc
            JOIN information_schema.key_column_usage    AS kc
                ON  kc.constraint_catalog = tc.constraint_catalog
                AND kc.constraint_schema  = tc.constraint_schema
                AND kc.constraint_name    = tc.constraint_name
            WHERE tc.constraint_type = 'PRIMARY KEY'
        };

        $sql .= ' AND ' . join(' AND ', @where) if @where;
        $sql .= ' ORDER BY kc.table_catalog, kc.table_schema, kc.table_name, kc.ordinal_position';

        my $sth = $dbh->prepare($sql) or return;
        $sth->execute(@bind)          or return;
        return $sth;

    }

    sub foreign_key_info {

        my ($dbh, $pk_catalog, $pk_schema, $pk_table, $fk_catalog, $fk_schema, $fk_table) = @_;

        my @where = ();
        my @bind  = ();

        my $like = sub {

            my ($col, $val) = @_;

            return if !defined $val || $val eq '' || $val eq '%';

            push @where, ($val =~ /[%_]/) ? "$col LIKE ? ESCAPE '\\'" : "$col = ?";
            push @bind, $val;

        };

        $like->('kc.table_catalog', $pk_catalog) if defined $pk_catalog;
        $like->('uk.table_schema',  $pk_schema)  if defined $pk_schema;
        $like->('uk.table_name',    $pk_table)   if defined $pk_table;
        $like->('fk.table_catalog', $fk_catalog) if defined $fk_catalog;
        $like->('fk.table_schema',  $fk_schema)  if defined $fk_schema;
        $like->('fk.table_name',    $fk_table)   if defined $fk_table;

        my $sql = q{
            SELECT
              uk.table_catalog      AS UK_TABLE_CAT,
              uk.table_schema       AS UK_TABLE_SCHEM,
              uk.table_name         AS UK_TABLE_NAME,
              ku.column_name        AS UK_COLUMN_NAME,
              fk.table_catalog      AS FK_TABLE_CAT,
              fk.table_schema       AS FK_TABLE_SCHEM,
              fk.table_name         AS FK_TABLE_NAME,
              kf.column_name        AS FK_COLUMN_NAME,
              kf.ordinal_position   AS ORDINAL_POSITION,
              rc.update_rule        AS UPDATE_RULE,
              rc.delete_rule        AS DELETE_RULE,
              fk.constraint_name    AS FK_NAME,
              uk.constraint_name    AS UK_NAME,
              CAST(NULL AS INTEGER) AS DEFERABILITY,   -- ??
              CASE
                WHEN UPPER(uk.constraint_type) = 'PRIMARY KEY' THEN 'P'
                ELSE 'U'
              END AS UNIQUE_OR_PRIMARY
            FROM information_schema.table_constraints AS fk
            JOIN information_schema.key_column_usage AS kf
              ON  kf.constraint_catalog = fk.constraint_catalog
              AND kf.constraint_schema  = fk.constraint_schema
              AND kf.constraint_name    = fk.constraint_name
            JOIN information_schema.referential_constraints AS rc
              ON  rc.constraint_catalog = fk.constraint_catalog
              AND rc.constraint_schema  = fk.constraint_schema
              AND rc.constraint_name    = fk.constraint_name
            JOIN information_schema.table_constraints AS uk
              ON  uk.constraint_catalog = rc.unique_constraint_catalog
              AND uk.constraint_schema  = rc.unique_constraint_schema
              AND uk.constraint_name    = rc.unique_constraint_name
            JOIN information_schema.key_column_usage AS ku
              ON  ku.constraint_catalog = uk.constraint_catalog
              AND ku.constraint_schema  = uk.constraint_schema
              AND ku.constraint_name    = uk.constraint_name
              AND COALESCE(ku.ordinal_position, 0) = COALESCE(kf.position_in_unique_constraint, kf.ordinal_position, 0)
            WHERE fk.constraint_type = 'FOREIGN KEY'
        };

        $sql .= ' AND ' . join(' AND ', @where) if @where;
        $sql .= ' ORDER BY fk.table_catalog, fk.table_schema, fk.table_name, kf.ordinal_position;';

        my $sth = $dbh->prepare($sql) or return;
        $sth->execute(@bind)          or return;
        return $sth;

    }


    sub type_info_all {

        my $PS  = 'precision,scale';
        my $LEN = 'length';
        my $UN;

        my $ti = [
            {
                TYPE_NAME          => 0,
                DATA_TYPE          => 1,
                COLUMN_SIZE        => 2,
                LITERAL_PREFIX     => 3,
                LITERAL_SUFFIX     => 4,
                CREATE_PARAMS      => 5,
                NULLABLE           => 6,
                CASE_SENSITIVE     => 7,
                SEARCHABLE         => 8,
                UNSIGNED_ATTRIBUTE => 9,
                FIXED_PREC_SCALE   => 10,
                AUTO_UNIQUE_VALUE  => 11,
                LOCAL_TYPE_NAME    => 12,
                MINIMUM_SCALE      => 13,
                MAXIMUM_SCALE      => 14,
                SQL_DATA_TYPE      => 15,
                SQL_DATETIME_SUB   => 16,
                NUM_PREC_RADIX     => 17,
                INTERVAL_PRECISION => 18,
            },
            ['ARRAY',     SQL_ALL_TYPES, $UN, $UN,  $UN, $UN,  1, 0, 0, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, $UN, $UN],
            ['BIGINT',    SQL_BIGINT,    19,  $UN,  $UN, $UN,  1, 0, 3, 0,   0, $UN, $UN, $UN, $UN, $UN, $UN, 10,  $UN],
            ['BLOB',      SQL_BLOB,      $UN, "X'", "'", $UN,  1, 0, 0, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, $UN, $UN],
            ['BOOLEAN',   SQL_BOOLEAN,   1,   $UN,  $UN, $UN,  1, 0, 3, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, $UN, $UN],
            ['DATE',      SQL_DATE,      10,  "'",  "'", $UN,  1, 0, 3, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, $UN, $UN],
            ['DECIMAL',   SQL_DECIMAL,   38,  $UN,  $UN, $PS,  1, 0, 3, 0,   1, $UN, $UN, 0,   38,  $UN, $UN, 10,  $UN],
            ['DOUBLE',    SQL_DOUBLE,    53,  $UN,  $UN, $UN,  1, 0, 3, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, 2,   $UN],
            ['INTEGER',   SQL_INTEGER,   10,  $UN,  $UN, $UN,  1, 0, 3, 0,   0, $UN, $UN, $UN, $UN, $UN, $UN, 10,  $UN],
            ['INTERVAL',  SQL_INTERVAL,  $UN, "'",  "'", $UN,  1, 0, 3, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, $UN, $UN],
            ['LIST',      SQL_ALL_TYPES, $UN, $UN,  $UN, $UN,  1, 0, 0, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, $UN, $UN],
            ['REAL',      SQL_REAL,      24,  $UN,  $UN, $UN,  1, 0, 3, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, 2,   $UN],
            ['SMALLINT',  SQL_SMALLINT,  5,   $UN,  $UN, $UN,  1, 0, 3, 0,   0, $UN, $UN, $UN, $UN, $UN, $UN, 10,  $UN],
            ['STRUCT',    SQL_ALL_TYPES, $UN, $UN,  $UN, $UN,  1, 0, 0, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, $UN, $UN],
            ['TIME',      SQL_TIME,      8,   "'",  "'", $UN,  1, 0, 3, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, $UN, $UN],
            ['TIMESTAMP', SQL_TIMESTAMP, 26,  "'",  "'", $UN,  1, 0, 3, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, $UN, $UN],
            ['TINYINT',   SQL_TINYINT,   3,   $UN,  $UN, $UN,  1, 0, 3, 0,   0, $UN, $UN, $UN, $UN, $UN, $UN, 10,  $UN],
            ['UBIGINT',   SQL_BIGINT,    20,  $UN,  $UN, $UN,  1, 0, 3, 1,   0, $UN, $UN, $UN, $UN, $UN, $UN, 10,  $UN],
            ['UINTEGER',  SQL_INTEGER,   10,  $UN,  $UN, $UN,  1, 0, 3, 1,   0, $UN, $UN, $UN, $UN, $UN, $UN, 10,  $UN],
            ['USMALLINT', SQL_SMALLINT,  5,   $UN,  $UN, $UN,  1, 0, 3, 1,   0, $UN, $UN, $UN, $UN, $UN, $UN, 10,  $UN],
            ['UTINYINT',  SQL_TINYINT,   3,   $UN,  $UN, $UN,  1, 0, 3, 1,   0, $UN, $UN, $UN, $UN, $UN, $UN, 10,  $UN],
            ['UUID',      SQL_VARCHAR,   36,  "'",  "'", $UN,  1, 0, 3, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, $UN, $UN],
            ['VARCHAR',   SQL_VARCHAR,   $UN, "'",  "'", $LEN, 1, 1, 1, $UN, 0, $UN, $UN, $UN, $UN, $UN, $UN, $UN, $UN],
        ];

        return $ti;

    }

    sub rollback {

        my $dbh = shift;

        if ($dbh->FETCH('AutoCommit')) {
            if ($dbh->FETCH('Warn')) {
                warn("Rollback ineffective while AutoCommit is on");
            }
            return;
        }

        $dbh->do('ROLLBACK');
        $dbh->do('BEGIN TRANSACTION');

        return 1;

    }

    sub commit {

        my $dbh = shift;

        if ($dbh->FETCH('AutoCommit')) {
            warn("Commit ineffective while AutoCommit is on") if ($dbh->FETCH('Warn'));
            return;
        }

        $dbh->do('COMMIT');

        return 1;

    }

    sub STORE {
        my ($dbh, $attr, $value) = @_;

        if ($attr =~ /^duckdb_/) {
            $dbh->{$attr} = $value;
            return 1;
        }

        if ($attr eq 'AutoCommit') {

            my $old_value = $dbh->{AutoCommit};
            my $never_set = !$old_value;

            if (!$old_value && $value && $never_set) {

                # DuckDB auto commit
            }
            elsif (!$old_value && $value) {
                $dbh->trace_msg("    -> DuckDB: commit changes\n");
                $dbh->do('COMMIT');
            }
            elsif ($old_value && !$value || !$old_value && !$value && $never_set) {
                $dbh->trace_msg("    -> DuckDB: start transaction\n");
                $dbh->do('BEGIN TRANSACTION');
            }

            $dbh->{AutoCommit} = $value;
            return 1;

        }

        $dbh->SUPER::STORE($attr, $value);
    }

    sub FETCH {
        my ($dbh, $attr) = @_;

        if ($attr =~ /^duckdb_/) {
            return $dbh->{$attr};
        }

        return $dbh->{AutoCommit} if $attr eq 'AutoCommit';
        return $dbh->SUPER::FETCH($attr);
    }

    sub DESTROY {
        my $dbh = shift;
        $dbh->disconnect if $dbh->FETCH('Active');
    }

}


package    # hide from PAUSE
    DBD::DuckDB::st {

    use strict;
    use warnings;
    use DBI  qw(:sql_types);
    use base qw(DBD::_::st);

    use Carp;
    use Config;
    use Time::Piece;

    use FFI::Platypus::Buffer qw( scalar_to_buffer buffer_to_scalar );

    use DBD::DuckDB::FFI       qw(:all);
    use DBD::DuckDB::Constants qw(:all);

    our $imp_data_size = 0;


    sub _sql_type {

        my ($attr, $value) = @_;

        return $attr         if defined $attr        && !ref $attr;
        return $attr->{TYPE} if ref($attr) eq 'HASH' && exists $attr->{TYPE};

        return SQL_INTEGER if defined $value && $value =~ /^-?\d+\z/;
        return SQL_DOUBLE  if defined $value && $value =~ /^-?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][+-]?\d+)?\z/;
        return SQL_BOOLEAN if defined $value && $value =~ /^(?:true|false|0|1)\z/i;
        return SQL_VARCHAR;

    }

    sub bind_param {

        my ($sth, $i, $value, $attr) = @_;

        my $sql_type    = _sql_type($attr, $value);
        my $duckdb_stmt = $sth->{duckdb_stmt};

        if (!defined $value) {
            my $rc = duckdb_bind_null($duckdb_stmt, $i);
            return $rc ? $sth->set_err(1, "duckdb_bind_null failed at $i") : 1;
        }

        if ($sql_type == SQL_INTEGER) {
            my $rc = duckdb_bind_int64($duckdb_stmt, $i, int($value));
            return $rc ? $sth->set_err(1, "duckdb_bind_int64 failed at $i") : 1;
        }

        if ($sql_type == SQL_DOUBLE) {
            my $rc = duckdb_bind_double($duckdb_stmt, $i, 0.0 + $value);
            return $rc ? $sth->set_err(1, "duckdb_bind_double failed at $i") : 1;
        }

        if ($sql_type == SQL_BOOLEAN) {
            my $rc = duckdb_bind_bool($duckdb_stmt, $i, ($value ? 1 : 0));
            return $rc ? $sth->set_err(1, "duckdb_bind_bool failed at $i") : 1;
        }

        if ($sql_type == SQL_BLOB) {

            utf8::downgrade($value, 1);

            my ($pointer, $size) = scalar_to_buffer($value);
            my $rc = duckdb_bind_blob($duckdb_stmt, $i, $pointer, $size);

            return $rc ? $sth->set_err(1, "duckdb_bind_blob failed at $i") : 1;

        }

        # Fallback

        my $rc = duckdb_bind_varchar($duckdb_stmt, $i, "$value");
        return $rc ? $sth->set_err(1, "duckdb_bind_varchar failed at $i") : 1;

    }

    sub rows { shift->{duckdb_rows} }

    sub execute {

        my ($sth, @bind) = @_;

        my $duckdb_stmt = $sth->{duckdb_stmt};

        for my $i (0 .. $#bind) {
            my $ok = $sth->bind_param($i + 1, $bind[$i]);
            return $ok if !defined $ok;
        }

        my $res = DBD::DuckDB::FFI::Result->new;
        my $rc  = duckdb_execute_prepared($duckdb_stmt, $res);

        return $sth->set_err(1, duckdb_result_error($res) // 'duckdb_execute_prepared failed') if $rc;

        my $res_type = duckdb_result_return_type($res);

        # cache result for fetching
        $sth->{duckdb_res}   = $res;
        $sth->{duckdb_cols}  = duckdb_column_count($res) || 0;
        $sth->{duckdb_rows}  = duckdb_row_count($res)    || 0;
        $sth->{duckdb_index} = 0;

        $sth->STORE('NUM_OF_FIELDS', $sth->{duckdb_cols});

        # fetchrow_hashref
        my @names         = map { duckdb_column_name($res, $_) // "column$_" } (0 .. $sth->{duckdb_cols} - 1);
        my @types         = map { duckdb_column_type($res, $_) } (0 .. $sth->{duckdb_cols} - 1);
        my @logical_types = map { duckdb_column_logical_type($res, $_) } 0 .. $sth->{duckdb_cols} - 1;

        $sth->{NAME}    = \@names;
        $sth->{NAME_lc} = [map lc, @names];
        $sth->{NAME_uc} = [map uc, @names];

        $sth->{duckdb_col_types}         = \@types;
        $sth->{duckdb_col_logical_types} = \@logical_types;

        # DML rows changed
        if ($res_type == DUCKDB_RESULT_TYPE_CHANGED_ROWS) {
            my $name = duckdb_column_name($res, 0) // '';
            if (lc($name) eq 'count') {
                $sth->{duckdb_rows} = duckdb_rows_changed($res);
            }
        }

        return '0E0';

    }

    sub finish {

        my $sth = shift;

        my $res  = delete $sth->{duckdb_res};
        my $stmt = delete $sth->{duckdb_stmt};

        duckdb_destroy_result($res);
        duckdb_destroy_prepare($stmt);

        foreach my $lt (@{$sth->{duckdb_col_logical_types}}) {
            duckdb_destroy_logical_type(\$lt);
        }

        $sth->{duckdb_col_logical_types} = [];

        return 1;

    }

    sub _fetch_vector_value {

        my ($vector, $row_idx, $logical_type) = @_;

        my $validity = duckdb_vector_get_validity($vector);
        return undef unless (duckdb_validity_row_is_valid($validity, $row_idx));

        my $vector_data = duckdb_vector_get_data($vector);
        my $type_id     = duckdb_get_type_id($logical_type);

        return _vector_array($logical_type, $vector, $row_idx)              if ($type_id == DUCKDB_TYPE_ARRAY);
        return _vector_date($vector_data, $row_idx)                         if ($type_id == DUCKDB_TYPE_DATE);
        return _vector_decimal($logical_type, $vector_data, $row_idx)       if ($type_id == DUCKDB_TYPE_DECIMAL);
        return _vector_f32($vector_data, $row_idx)                          if ($type_id == DUCKDB_TYPE_FLOAT);
        return _vector_f64($vector_data, $row_idx)                          if ($type_id == DUCKDB_TYPE_DOUBLE);
        return _vector_i16($vector_data, $row_idx)                          if ($type_id == DUCKDB_TYPE_SMALLINT);
        return _vector_i32($vector_data, $row_idx)                          if ($type_id == DUCKDB_TYPE_INTEGER);
        return _vector_i64($vector_data, $row_idx)                          if ($type_id == DUCKDB_TYPE_BIGINT);
        return _vector_i8($vector_data, $row_idx)                           if ($type_id == DUCKDB_TYPE_TINYINT);
        return _vector_list($logical_type, $vector, $vector_data, $row_idx) if ($type_id == DUCKDB_TYPE_LIST);
        return _vector_map($logical_type, $vector, $vector_data, $row_idx)  if ($type_id == DUCKDB_TYPE_MAP);
        return _vector_struct($logical_type, $vector, $row_idx)             if ($type_id == DUCKDB_TYPE_STRUCT);
        return _vector_timestamp($vector_data, $row_idx, 0)                 if ($type_id == DUCKDB_TYPE_TIMESTAMP);
        return _vector_timestamp($vector_data, $row_idx, 1)                 if ($type_id == DUCKDB_TYPE_TIMESTAMP_TZ);
        return _vector_u16($vector_data, $row_idx)                          if ($type_id == DUCKDB_TYPE_USMALLINT);
        return _vector_u32($vector_data, $row_idx)                          if ($type_id == DUCKDB_TYPE_UINTEGER);
        return _vector_u64($vector_data, $row_idx)                          if ($type_id == DUCKDB_TYPE_UBIGINT);
        return _vector_u8($vector_data, $row_idx)                           if ($type_id == DUCKDB_TYPE_UTINYINT);
        return _vector_u8($vector_data, $row_idx) ? !!1 : !!0               if ($type_id == DUCKDB_TYPE_BOOLEAN);
        return _vector_union($logical_type, $vector, $row_idx)              if ($type_id == DUCKDB_TYPE_UNION);
        return _vector_varchar($vector_data, $row_idx)                      if ($type_id == DUCKDB_TYPE_BLOB);
        return _vector_varchar($vector_data, $row_idx)                      if ($type_id == DUCKDB_TYPE_VARCHAR);

        Carp::carp "Unknown type ($type_id)";
        return undef;

    }

    sub _mem {
        my ($vector_data, $row_idx, $size) = @_;
        my $addr = $vector_data + $row_idx * $size;
        my $sv   = buffer_to_scalar($addr, $size);
        return $sv;
    }

    sub _vector_u8  { unpack 'C',  _mem(@_, 1) }
    sub _vector_i8  { unpack 'c',  _mem(@_, 1) }
    sub _vector_u16 { unpack 'S<', _mem(@_, 2) }
    sub _vector_i16 { unpack 's<', _mem(@_, 2) }
    sub _vector_u32 { unpack 'L<', _mem(@_, 4) }
    sub _vector_i32 { unpack 'l<', _mem(@_, 4) }
    sub _vector_u64 { unpack 'Q<', _mem(@_, 8) }
    sub _vector_i64 { unpack 'q<', _mem(@_, 8) }
    sub _vector_f32 { unpack 'f<', _mem(@_, 4) }
    sub _vector_f64 { unpack 'd<', _mem(@_, 8) }

    sub _vector_varchar {

        my ($vector_data, $row_idx) = @_;

        my $PTRSIZE = $Config{ptrsize};

        my $rec = buffer_to_scalar($vector_data + $row_idx * 16, 16);
        my $len = unpack('L<', substr($rec, 0, 4));

        return undef unless defined $len;

        if ($len <= 12) {
            return substr($rec, 4, $len);
        }
        else {
            my $ptr = unpack(($PTRSIZE == 8 ? 'Q<' : 'L<'), substr($rec, 8, $PTRSIZE));
            return undef unless $ptr;
            return buffer_to_scalar($ptr, $len);
        }

    }

    sub _vector_date {

        my ($vector_data, $row_idx) = @_;

        # Decode duckdb_date struct
        my $days  = _vector_i32($vector_data, $row_idx);
        my $epoch = 0 + 86400 * $days;

        my $t = Time::Piece->new($epoch);
        return $t->date;

    }

    sub _vector_timestamp {
        my ($vector_data, $row_idx, $tz) = @_;
        my $epoch = int(_vector_i64($vector_data, $row_idx) / 1_000_000);
        return ($tz == 1) ? localtime($epoch)->datetime : gmtime($epoch)->datetime;
    }

    sub _vector_array {

        my ($logical_type, $vector_data, $row_idx) = @_;

        my $child_logical_type = duckdb_array_type_child_type($logical_type);
        my $size               = duckdb_array_type_array_size($logical_type);
        my $child_vector       = duckdb_array_vector_get_child($vector_data);

        my $begin = $row_idx * $size;
        my $end   = $begin + $size;

        my @out = ();

        for (my $i = $begin; $i < $end; $i++) {
            push @out, _fetch_vector_value($child_vector, $i, $child_logical_type);
        }

        duckdb_destroy_logical_type(\$child_logical_type);

        return \@out;

    }

    sub _vector_list {

        my ($logical_type, $vector, $vector_data, $row_idx) = @_;

        my $child_logical_type = duckdb_list_type_child_type($logical_type);
        my $child_vector       = duckdb_list_vector_get_child($vector);

        # Decode duckdb_list_entry struct
        my ($offset, $length) = unpack('Q< Q<', buffer_to_scalar($vector_data + $row_idx * 16, 16));

        my $begin = $offset;
        my $end   = $offset + $length;

        my @out = ();

        for (my $i = $begin; $i < $end; $i++) {
            push @out, _fetch_vector_value($child_vector, $i, $child_logical_type);
        }

        duckdb_destroy_logical_type(\$child_logical_type);

        return \@out;

    }

    sub _vector_struct {

        my ($logical_type, $vector_data, $row_idx) = @_;

        my $child_count = duckdb_struct_type_child_count($logical_type);

        my %struct = ();

        for (my $i = 0; $i < $child_count; ++$i) {

            my $name               = duckdb_struct_type_child_name($logical_type, $i);
            my $child_vector       = duckdb_struct_vector_get_child($vector_data, $i);
            my $child_logical_type = duckdb_struct_type_child_type($logical_type, $i);
            my $value              = _fetch_vector_value($child_vector, $row_idx, $child_logical_type);

            $struct{$name} = $value;

            duckdb_destroy_logical_type(\$child_logical_type);

        }

        return \%struct;

    }

    sub _vector_union {

        my $struct = _vector_struct(@_);

        return undef unless $struct && ref $struct eq 'HASH';

        for my $key (sort keys %{$struct}) {
            next if $key eq '';

            return $struct->{$key} if defined $struct->{$key};
        }

        return undef;

    }

    sub _vector_map {

        my ($logical_type, $vector, $vector_data, $row_idx) = @_;

        my $key_logical_type   = duckdb_map_type_key_type($logical_type);
        my $value_logical_type = duckdb_map_type_value_type($logical_type);

        # Decode duckdb_list_entry struct
        my ($offset, $length) = unpack('Q< Q<', buffer_to_scalar($vector_data + $row_idx * 16, 16));

        my $begin = $offset;
        my $end   = $offset + $length;

        my %out = ();

        my $child        = duckdb_list_vector_get_child($vector);
        my $key_vector   = duckdb_struct_vector_get_child($child, 0);
        my $value_vector = duckdb_struct_vector_get_child($child, 1);

        for (my $i = $begin; $i < $end; ++$i) {

            my $key   = _fetch_vector_value($key_vector,   $i, $key_logical_type);
            my $value = _fetch_vector_value($value_vector, $i, $value_logical_type);

            $out{$key} = $value;

        }

        duckdb_destroy_logical_type(\$key_logical_type);
        duckdb_destroy_logical_type(\$value_logical_type);

        return \%out;

    }

    sub _vector_decimal {

        my ($logical_type, $vector_data, $row_idx) = @_;

        my $width = duckdb_decimal_width($logical_type);
        my $scale = duckdb_decimal_scale($logical_type);
        my $type  = duckdb_decimal_internal_type($logical_type);
        my $value = undef;

        $value = _vector_i32($vector_data, $row_idx) if ($type == DUCKDB_TYPE_INTEGER);
        $value = _vector_i16($vector_data, $row_idx) if ($type == DUCKDB_TYPE_SMALLINT);
        $value = _vector_i64($vector_data, $row_idx) if ($type == DUCKDB_TYPE_BIGINT);

        # TODO Add other numeric types

        if ($value) {
            return sprintf("%.${scale}f", $value / (10**$scale));
        }

        Carp::carp "Unknown decimal internal type ($type)";
        return undef;

    }

    sub fetchrow_arrayref {

        my $sth = shift;

        my $res = $sth->{duckdb_res} or return undef;
        my $idx = $sth->{duckdb_index} // 0;

        if ($idx >= ($sth->{duckdb_rows} // 0)) {
            $sth->STORE(Active => 0);
            return undef;
        }

        my @row = ();

        if (!defined $sth->{duckdb_chunk}) {

            $sth->{duckdb_chunk} = duckdb_fetch_chunk($sth->{duckdb_res});

            unless ($sth->{duckdb_chunk}) {
                $sth->STORE('Active', 0);
                return undef;
            }

            $sth->{duckdb_chunk_size} = duckdb_data_chunk_get_size($sth->{duckdb_chunk});
            $sth->{duckdb_chunk_row}  = 0;

            if ($sth->{duckdb_chunk_size} == 0) {
                $sth->STORE('Active', 0);
                return undef;
            }

        }

        for my $col (0 .. $sth->{duckdb_cols} - 1) {
            my $vector       = duckdb_data_chunk_get_vector($sth->{duckdb_chunk}, $col);
            my $logical_type = $sth->{duckdb_col_logical_types}->[$col];
            push @row, _fetch_vector_value($vector, $sth->{duckdb_chunk_row}, $logical_type);
        }

        $sth->{duckdb_chunk_row}++;
        $sth->{duckdb_index}++;


        if ($sth->{duckdb_chunk_row} >= $sth->{duckdb_chunk_size}) {
            my $tmp = $sth->{chunk};
            duckdb_destroy_data_chunk(\$tmp);
            $sth->{duckdb_chunk} = undef;
        }

        map {s/\s+$//} @row if $sth->FETCH('ChopBlanks');
        return $sth->_set_fbav(\@row);

    }

    *fetch = \&fetchrow_arrayref;

    sub STORE {
        my ($sth, $attr, $value) = @_;

        if ($attr =~ /^duckdb_/) {
            $sth->{$attr} = $value;
            return 1;
        }

        $sth->SUPER::STORE($attr, $value);
    }

    sub FETCH {
        my ($sth, $attr) = @_;

        if ($attr =~ /^duckdb_/) {
            return $sth->{$attr};
        }

        $sth->SUPER::FETCH($attr);
    }

}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

DBD::DuckDB - DuckDB database driver for the DBI module

=head1 SYNOPSIS

  use DBI;
  my $dbh = DBI->connect("dbi:DuckDB:dbname=$dbfile","","");

=head1 DESCRIPTION

DuckDB is a high-performance analytical database system. It is designed to be 
fast, reliable, portable, and easy to use. DuckDB provides a rich SQL dialect 
with support far beyond basic SQL. DuckDB supports arbitrary and nested 
correlated subqueries, window functions, collations, complex types (arrays, 
structs, maps), and several extensions designed to make SQL easier to use.

L<https://duckdb.org>

=head1 MODULE DOCUMENTATION

This documentation describes driver specific behavior and restrictions. It is
not supposed to be used as the only reference for the user. In any case
consult the B<DBI> documentation first!

L<Latest DBI documentation.|DBI>

=head1 SETUP

To use L<DBD::DuckDB>, the native DuckDB library must be available when the
module is loaded.  There are two common ways to satisfy this requirement.

=head2 Manual installation

=over

=item * Download the library

    $ wget https://github.com/duckdb/duckdb/releases/download/v$VERSION/libduckdb-linux-amd64.zip
    $ unzip duckdb-linux-amd64.zip
    $ sudo cp libduckdb.so /usr/lib64/          # or another system library directory

=item * Update the library search path

If the library was not placed in a directory already listed in
C</etc/ld.so.conf> (or equivalent), add its location to
C<LD_LIBRARY_PATH>:

    $ export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH

or add the directory to C</etc/ld.so.conf> and run:

    $ sudo ldconfig

=back

=head2 Use Alien::DuckDB

L<Alien::DuckDB> is a CPAN module that automatically downloads and
installs the native DuckDB C library for the current platform.

=over

=item * Install the Alien module

    $ cpanm Alien::DuckDB

    # or

    $ perl -MCPAN -e 'install Alien::DuckDB'

=item * DBD::DuckDB detects Alien automatically

No environment variables or manual copying of *.so files are needed;
when you C<use DBD::DuckDB>, the module calls
C<Alien::DuckDB-E<gt>dynamic_lib> to obtain the correct library path.

=back


=head1 THE DBI CLASS

=head2 DBI Class Methods

=head3 B<connect>

This method creates a database handle by connecting to a database, and is the 
DBI equivalent of the "new" method.

The connection string is always of the form: "dbi:DuckDB:dbname=<dbfile>"

    my $dbh = DBI->connect("dbi:DucDB:dbname=$dbfile", "", "", $attr);

DuckDB creates a file per a database.

The file is opened in read/write mode, and will be created if it does not exist yet.

Although the database is stored in a single file, the directory containing the 
database file must be writable by DuckDB because the library will create 
several temporary files there.

If the filename C<$dbfile> is ":memory:", then a private, temporary in-memory 
database is created for the connection. This in-memory database will vanish 
when the database connection is closed. It is handy for your library tests.

=head2 Connect Attributes

=over

=item * B<duckdb_checkpoint_on_disconnect>

=back


=head2 Methods Common To All Handles

For all of the methods below, B<$h> can be either a database handle (B<$dbh>) 
or a statement handle (B<$sth>). Note that I<$dbh> and I<$sth> can be replaced with 
any variable name you choose: these are just the names most often used. Another 
common variable used in this documentation is $I<rv>, which stands for "return value".

=head3 B<err>

    $rv = $h->err;

Returns the error code from the last method called. 

=head3 B<errstr>

    $str = $h->errstr;

Returns the last error that was reported by DuckDB. 

=head3 B<state>

    $str = $h->state;

Returns a five-character "SQLSTATE" code. Success is indicated by a C<00000> code, which 
gets mapped to an empty string by DBI.

Note that the specific success code C<00000> is translated to any empty string
(false). DuckDB does not support SQLSTATE then state() will return C<S1000> (General Error)
for all errors.

=head3 B<trace>

    $h->trace($trace_settings);
    $h->trace($trace_settings, $trace_filename);
    $trace_settings = $h->trace;

Changes the trace settings on a database or statement handle. 
The optional second argument specifies a file to write the 
trace information to. If no filename is given, the information 
is written to F<STDERR>. Note that tracing can be set globally as 
well by setting C<< DBI->trace >>, or by using the environment 
variable I<DBI_TRACE>.

=head3 B<trace_msg>

    $h->trace_msg($message_text);
    $h->trace_msg($message_text, $min_level);

Writes a message to the current trace output (as set by the L</trace> method). If a second argument 
is given, the message is only written if the current tracing level is equal to or greater than 
the C<$min_level>.

=head3 B<Other common methods>

See the L<DBI> documentation for full details.


=head1 DBI DATABASE HANDLE OBJECTS

=head2 Database Handle Methods

=head3 B<selectall_arrayref>

    $ary_ref = $dbh->selectall_arrayref($sql);
    $ary_ref = $dbh->selectall_arrayref($sql, \%attr);
    $ary_ref = $dbh->selectall_arrayref($sql, \%attr, @bind_values);

Returns a reference to an array containing the rows returned by preparing and
executing the SQL string. See the L<DBI> documentation for full details.

=head3 B<selectcol_arrayref>
  
    $ary_ref = $dbh->selectcol_arrayref($sql, \%attr, @bind_values);

Returns a reference to an array containing the first column from each rows 
returned by preparing and executing the SQL string. It is possible to specify 
exactly which columns to return. See the L<DBI> documentation for full details.

=head3 B<prepare>

    $sth = $dbh->prepare($statement, \%attr);

Prepares a statement for later execution by the database engine and returns a
reference to a statement handle object.

=head3 B<prepare_cached>

    $sth = $dbh->prepare_cached($statement, \%attr);

Implemented by DBI, no driver-specific impact. This method is most useful if
the same query is used over and over as it will cut down round trips to the server.

=head3 B<do>

    $rv = $dbh->do($statement);
    $rv = $dbh->do($statement, \%attr);
    $rv = $dbh->do($statement, \%attr, @bind_values);

Prepare and execute a single statement. Returns the number of rows affected if 
the query was successful, returns undef if an error occurred, and returns -1 if 
the number of rows is unknown or not available. Note that this method will 
return B<0E0> instead of 0 for 'no rows were affected', in order to always 
return a true value if no error occurred.

=head3 B<last_insert_id>

DuckDB does not implement auto_increment of serial type columns it uses 
predefined sequences where the id numbers are either selected before insert, at 
insert time, or as part of the query.

    $dbh->do('CREATE SEQUENCE id_sequence START 1');

    $dbh->do( q{CREATE TABLE tbl (
        id INTEGER DEFAULT nextval('id_sequence'),
        s VARCHAR
    } );

    $dbh->do( q{INSERT INTO tbl (s) VALUES ('hello'), ('world')} );

See L<https://duckdb.org/docs/stable/sql/statements/create_sequence.html>.

=head3 B<commit>

    $rv = $dbh->commit;

Issues a COMMIT to DuckDB, indicating that the current transaction is 
finished and that all changes made will be visible to other processes. If 
AutoCommit is enabled, then a warning is given and no COMMIT is issued. Returns 
true on success, false on error.

=head3 B<rollback>

    $rv = $dbh->rollback;

Issues a ROLLBACK to DuckDB, which discards any changes made in the current 
transaction. If AutoCommit is enabled, then a warning is given and no ROLLBACK 
is issued. Returns true on success, and false on error.

=head3 B<begin_work>

This method turns on transactions until the next call to "commit" or "rollback",
if AutoCommit is currently enabled. If it is not enabled, calling begin_work will
issue an error. Note that the transaction will not actually begin until the first
statement after begin_work is called.

Example:

    $dbh->{AutoCommit} = 1;
    $dbh->do('INSERT INTO foo VALUES (123)'); ## Changes committed immediately
    $dbh->begin_work();
    ## Not in a transaction yet, but AutoCommit is set to 0

    $dbh->do("INSERT INTO foo VALUES (345)");
    ## DuckDB actually issues two statements here:
    ## BEGIN;
    ## INSERT INTO foo VALUES (345)
    ## We are now in a transaction

    $dbh->commit();
    ## AutoCommit is now set to 1 again

=head3 B<disconnect>

    $rv = $dbh->disconnect;

Disconnects from the DuckDB database. Any uncommitted changes will be rolled 
back upon disconnection. It's good policy to always explicitly call commit or 
rollback at some point before disconnecting, rather than relying on the default 
rollback behavior.

If the script exits before disconnect is called (or, more precisely, if the 
database handle is no longer referenced by anything), then the database 
handle's DESTROY method will call the rollback() and disconnect() methods 
automatically. It is best to explicitly disconnect rather than rely on this 
behavior.

=head3 B<quote>

    $rv = $dbh->quote($value, $data_type);

=head3 B<quote_identifier>

    $string = $dbh->quote_identifier( $name );
    $string = $dbh->quote_identifier( undef, $schema, $table);

=head3 B<table_info>

    $sth = $dbh->table_info($catalog, $schema, $table, $type, \%attr);

Returns all tables and schemas (databases) as specified in L<DBI/table_info>.
The schema and table arguments will do a C<LIKE> search. You can specify an
ESCAPE character by including an 'Escape' attribute in \%attr. The C<$type>
argument accepts a comma separated list of the following types 'TABLE',
'INDEX', 'VIEW' and 'TRIGGER' (by default all are returned).
Note that a statement handle is returned, and not a direct list of tables.
The following fields are returned:

=over

=item * B<TABLE_CAT>: The name of the catalog.

=item * B<TABLE_SCHEM>: The name of the schema (database) that the table or view is
in. The default schema is 'main' and other databases will be in the name given when
the database was attached.

B<TABLE_NAME>: The name of the table or view.

B<TABLE_TYPE>: The type of object returned. Will be one of 'TABLE', 'INDEX',
'VIEW', 'TRIGGER'.

=back

=head3 B<tables>

    @names = $dbh->tables( undef, $schema, $table, $type, \%attr );

Supported by this driver as proposed by DBI. This method returns all tables
and/or views (including foreign tables and materialized views) which are
visible to the current user: see L</table_info> for more information about
the arguments.

=head3 B<type_info_all>

    $type_info_all = $dbh->type_info_all;

Supported by this driver as proposed by DBI. Information is only provided for
SQL datatypes and for frequently used datatypes.

=head3 B<type_info>

    @type_info = $dbh->type_info($data_type);

Returns a list of hash references holding information about one or more variants of $data_type. 
See the DBI documentation for more details.

=head3 B<primary_key primary_key_info>

    @names = $dbh->primary_key(undef, $schema, $table);
    $sth   = $dbh->primary_key_info(undef, $schema, $table, \%attr);

You can retrieve primary key names or more detailed information.

=head3 B<foreign_key_info>

    $sth = $dbh->foreign_key_info( $pk_catalog, $pk_schema, $pk_table,
                                   $fk_catalog, $fk_schema, $fk_table );

Supported by this driver as proposed by DBI, using the SQL/CLI variant.

=head3 B<ping>

    my $bool = $dbh->ping;

Returns true if the database file exists (or the database is in-memory), and
the database connection is active.

=head2 DuckDB methods

=head3 B<x_duckdb_version>

Return the current DuckDB library version using C<duckdb_library_version> C
function.

=head3 B<x_duckdb_appender>

Appenders are the most efficient way of loading data into DuckDB from within 
the C interface, and are recommended for fast data loading. The appender is 
much faster than using prepared statements or individual INSERT INTO statements.

    $dbh->do('CREATE TABLE people (id INTEGER, name VARCHAR)');
    my $appender = $dbh->x_duckdb_appender('people');

    $appender->append(1, DUCKDB_TYPE_INTEGER);
    $appender->append('Mark', DUCKDB_TYPE_VARCHAR);
    $appender->end_row;

    # or

    $appeder->append_row(id => 1, name => 'Mark');

See L<DBD::DuckDB::Appender>.

=head3 B<x_duckdb_read_csv>

    $dbh->x_duckdb_read_csv( $file );
    $dbh->x_duckdb_read_csv( $file, \%params );

Helper method for C<read_csv> function (L<https://duckdb.org/docs/stable/data/csv/overview>).

    $sth = $dbh->x_duckdb_read_csv('https://duckdb.org/data/flights.csv' => {sep => '|'}) or Carp::croak $dbh->errstr;

    while (my $row = $sth->fetchrow_hashref) {
        say sprintf '%s --> %s', $row->{OriginCityName}, $row->{DestCityName}; 
    }

=head3 B<x_duckdb_read_json>

    $dbh->x_duckdb_read_json( $file );
    $dbh->x_duckdb_read_json( $file, \%params );

Helper method for C<read_json> function (L<https://duckdb.org/docs/stable/data/json/loading_json>).

    $sth = $dbh->x_duckdb_read_json('https://duckdb.org/data/json/todos.json') or Carp::croak $dbh->errstr;

    while (my $row = $sth->fetchrow_hashref) {
        say sprintf '[%s] %s', ($row->{completed} ? '✓' : ' '), $row->{title};
    }

=head3 B<x_duckdb_read_xlsx>

    $dbh->x_duckdb_read_xlsx( $file );
    $dbh->x_duckdb_read_xlsx( $file, \%params );

Helper method for C<read_xlsx> function (L<https://duckdb.org/docs/stable/core_extensions/excel>).


=head1 DBI STATEMENT HANDLE OBJECTS

=head2 Statement Handle Methods

=head3 B<bind_param>

    $rv = $sth->bind_param($param_num, $bind_value);
    $rv = $sth->bind_param($param_num, $bind_value, $bind_type);
    $rv = $sth->bind_param($param_num, $bind_value, \%attr);

Allows the user to bind a value and/or a data type to a placeholder.

=head3 B<bind_param_array>

    $rv = $sth->bind_param_array($param_num, $array_ref_or_value)
    $rv = $sth->bind_param_array($param_num, $array_ref_or_value, $bind_type)
    $rv = $sth->bind_param_array($param_num, $array_ref_or_value, \%attr)

Binds an array of values to a placeholder, so that each is used in turn by a call 
to the L</execute_array> method.

=head3 B<execute>

    $rv = $sth->execute(@bind_values);

Perform whatever processing is necessary to execute the prepared statement.

=head3 B<execute_array>

    $tuples = $sth->execute_array() or die $sth->errstr;
    $tuples = $sth->execute_array(\%attr) or die $sth->errstr;
    $tuples = $sth->execute_array(\%attr, @bind_values) or die $sth->errstr;
    ($tuples, $rows) = $sth->execute_array(\%attr) or die $sth->errstr;
    ($tuples, $rows) = $sth->execute_array(\%attr, @bind_values) or die $sth->errstr;

Execute a prepared statement once for each item in a passed-in hashref, or items that 
were previously bound via the L</bind_param_array> method. See the L<DBI> documentation 
for more details.

=head3 B<execute_for_fetch>

    $tuples = $sth->execute_for_fetch($fetch_tuple_sub);
    $tuples = $sth->execute_for_fetch($fetch_tuple_sub, \@tuple_status);
    ($tuples, $rows) = $sth->execute_for_fetch($fetch_tuple_sub);
    ($tuples, $rows) = $sth->execute_for_fetch($fetch_tuple_sub, \@tuple_status);

Used internally by the L</execute_array> method, and rarely used directly. See the 
L<DBI> documentation for more details.


=head3 B<fetchrow_arrayref>

    $ary_ref = $sth->fetchrow_arrayref;

Fetches the next row of data from the statement handle, and returns a reference to an array 
holding the column values. Any columns that are NULL are returned as undef within the array.

If there are no more rows or if an error occurs, then this method return undef. You should 
check C<< $sth->err >> afterwards (or use the L<RaiseError|/RaiseError (boolean, inherited)> attribute) to discover if the undef returned 
was due to an error.

Note that the same array reference is returned for each fetch, so don't store the reference and 
then use it after a later fetch. Also, the elements of the array are also reused for each row, 
so take care if you want to take a reference to an element. See also L</bind_columns>.

=head3 B<fetchrow_array>

    @ary = $sth->fetchrow_array;

Similar to the L</fetchrow_arrayref> method, but returns a list of column information rather than 
a reference to a list. Do not use this in a scalar context.

=head3 B<fetchrow_hashref>

    $hash_ref = $sth->fetchrow_hashref;
    $hash_ref = $sth->fetchrow_hashref($name);

Fetches the next row of data and returns a hashref containing the name of the columns as the keys 
and the data itself as the values. Any NULL value is returned as an undef value.

If there are no more rows or if an error occurs, then this method return undef. You should 
check C<< $sth->err >> afterwards (or use the L<RaiseError|/RaiseError (boolean, inherited)> attribute) to discover if the undef returned 
was due to an error.

The optional C<$name> argument should be either C<NAME>, C<NAME_lc> or C<NAME_uc>, and indicates 
what sort of transformation to make to the keys in the hash.

=head3 B<fetchall_arrayref>

    $tbl_ary_ref = $sth->fetchall_arrayref();
    $tbl_ary_ref = $sth->fetchall_arrayref( $slice );
    $tbl_ary_ref = $sth->fetchall_arrayref( $slice, $max_rows );

Returns a reference to an array of arrays that contains all the remaining rows to be fetched from the 
statement handle. If there are no more rows, an empty arrayref will be returned. If an error occurs, 
the data read in so far will be returned. Because of this, you should always check C<< $sth->err >> after 
calling this method, unless L<RaiseError|/RaiseError (boolean, inherited)> has been enabled.

If C<$slice> is an array reference, fetchall_arrayref uses the L</fetchrow_arrayref> method to fetch each 
row as an array ref. If the C<$slice> array is not empty then it is used as a slice to select individual 
columns by perl array index number (starting at 0, unlike column and parameter numbers which start at 1).

With no parameters, or if $slice is undefined, fetchall_arrayref acts as if passed an empty array ref.

If C<$slice> is a hash reference, fetchall_arrayref uses L</fetchrow_hashref> to fetch each row as a hash reference.

See the L<DBI> documentation for a complete discussion.

=head3 B<fetchall_hashref>

    $hash_ref = $sth->fetchall_hashref( $key_field );

Returns a hashref containing all rows to be fetched from the statement handle. See the DBI documentation for 
a full discussion.

=head3 B<finish>

    $rv = $sth->finish;

Indicates to DBI that you are finished with the statement handle and are not going to use it again. Only needed 
when you have not fetched all the possible rows.

=head3 B<rows>

    $rv = $sth->rows;

Returns the number of rows returned by the last query. In contrast to many other DBD modules, 
the number of rows is available immediately after calling C<< $sth->execute >>. Note that 
the L</execute> method itself returns the number of rows itself, which means that this 
method is rarely needed.

=head3 B<dump_results>

    $rows = $sth->dump_results($maxlen, $lsep, $fsep, $fh);

Fetches all the rows from the statement handle, calls C<DBI::neat_list> for each row, and 
prints the results to C<$fh> (which defaults to F<STDOUT>). Rows are separated by C<$lsep> (which defaults 
to a newline). Columns are separated by C<$fsep> (which defaults to a comma). The C<$maxlen> controls 
how wide the output can be, and defaults to 35.

This method is designed as a handy utility for prototyping and testing queries. Since it uses 
"neat_list" to format and edit the string for reading by humans, it is not recommended 
for data transfer applications.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-DBD-DuckDB/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-DBD-DuckDB>

    git clone https://github.com/giterlizzi/perl-DBD-DuckDB.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
