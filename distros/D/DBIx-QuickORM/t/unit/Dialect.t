# Test origin: AI
use Test2::V0;

use DBI;
use DBIx::QuickORM::Dialect;

my $D = 'DBIx::QuickORM::Dialect';

subtest for_dbh => sub {
    my $dbh     = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    my $dialect = $D->for_dbh($dbh);
    is(ref($dialect), 'DBIx::QuickORM::Dialect::SQLite', "The driver picks the dialect, an object");
    my ($major, $minor, $patch) = split m/\./ => $dbh->selectrow_array('SELECT sqlite_version()');
    is($dialect->server_version,      $major * 1_000_000 + $minor * 1_000 + $patch, "holding the server's version");
    is($D->for_dbh($dbh)->quote_char, '"',                                          "Each call gives a new object, which answers like the class");
    like(
        dies { $D->for_dbh(DBI->connect('dbi:NullP:', '', '', {RaiseError => 1})) },
        qr/^Unsupported database driver 'DBD::NullP', supported drivers are: DBD::DuckDB, DBD::MariaDB, DBD::Pg, DBD::SQLite at /,
        "An unsupported driver croaks, naming the supported ones",
    );
};

subtest defaults => sub {
    is($D->name,                                                                                                               'Dialect',                                        "The name is the last part of the class");
    is($D->new->name,                                                                                                          'Dialect',                                        "on an object too");
    is($D->dialect_for_dbh(undef),                                                                                             $D,                                               "A dialect is its own choice by default");
    is($D->quote_char,                                                                                                         '"',                                              "Double quotes");
    is($D->quote_identifier('users'),                                                                                          '"users"',                                        "Quotes an identifier");
    is($D->quote_identifier('we"ird'),                                                                                         '"we""ird"',                                      "Doubles a quote inside it");
    is($D->quote_identifier('0'),                                                                                              '"0"',                                            "A name of 0 works");
    is([map { $D->$_ } qw/supports_savepoints supports_returning_insert supports_returning_update supports_returning_delete/], [1, 1, 1, 1],                                     "Savepoints and RETURNING everywhere");
    is($D->supports_second_connection(undef),                                                                                  1,                                                "A second connection reaches the same data by default");
    is($D->bind_limit,                                                                                                         999,                                              "The lowest bind limit");
    is([$D->datetime_format],                                                                                                  ['DateTime::Format::Pg', 'DateTime::Format::Pg'], "DateTime::Format::Pg parses and formats dates by default");
};

subtest begin_sql => sub {
    is([$D->begin_sql], ['BEGIN'], "A root transaction begins with BEGIN");
    like(dies { $D->begin_sql('SERIALIZABLE') }, qr/^The Dialect dialect cannot set a transaction isolation level/, "No isolation level by default");
    is($D->supports_isolation, 0, "and supports_isolation says so");
};

subtest version_number => sub {
    is($D->_version_number('8.0.36'),              8_000_036,  "A dotted version");
    is($D->_version_number('10.11.6-MariaDB-log'), 10_011_006, "with a suffix");
    is($D->_version_number('v1.1.3'),              1_001_003,  "with a prefix");
    is($D->_version_number('3.45'),                3_045_000,  "without a patch");
    ok($D->_version_number('9.7.0') > $D->_version_number('8.4.12'), "Versions compare as numbers");
    is($D->_version_number('unknown'), undef, "A string without a version gives undef");
    is($D->_version_number(undef),     undef, "and so does no string");

    my $dbh = mock {} => (add => [selectrow_array => sub { '8.4.2' }]);
    is($D->_server_version($dbh), 8_004_002, "The default reads SELECT version()");

    my $garbled = mock {Driver => {Name => 'SQLite'}} => (add => [selectrow_array => sub { 'garbled' }]);
    my $dialect = $D->for_dbh($garbled);
    isa_ok($dialect, ['DBIx::QuickORM::Dialect::SQLite'], "An unreadable version string does not refuse the connection");
    is($dialect->server_version, undef, "and leaves server_version undef");
};

subtest namespace_and_release => sub {
    my @sql;
    my $dbh = mock {} => (add => [selectrow_array => sub { push @sql => $_[1]; 'public' }]);
    is($D->namespace($dbh), 'public',                    "Namespace from the connection");
    is(\@sql,               ['SELECT current_schema()'], "via current_schema()");

    my %h;
    $D->release_inherited(\%h);
    is(\%h, {InactiveDestroy => 1}, "Releasing sets InactiveDestroy");
};

subtest binds => sub {
    is($D->binary_bind_attrs,                  {TYPE => DBI::SQL_BLOB()}, "Binary binds are SQL_BLOB");
    is($D->bind_attrs({affinity => 'binary'}), {TYPE => DBI::SQL_BLOB()}, "for a binary field");
    is($D->bind_attrs({affinity => 'string'}), undef,                     "and nothing for others");
    is($D->bind_attrs(undef),                  undef,                     "or for no field");
    my $dbh = mock {} => (add => [last_insert_id => sub { shift; [@_] }]);
    is($D->last_insert_id($dbh, 't', 'id'), [undef, undef, 't', 'id'], "last_insert_id asks DBI for the table and field");
};

subtest error_kind => sub {
    my %states = (
        '40001' => 'serialization_failure',
        '40P01' => 'deadlock',
        '55P03' => 'lock_timeout',
        '23505' => 'unique_violation',
        '23503' => 'foreign_key_violation',
        '23502' => 'not_null_violation',
        '23514' => 'check_violation',
    );
    is($D->error_kind(7,     $_,      'text'), $states{$_}, "SQLSTATE $_ is $states{$_}") for sort keys %states;
    is($D->error_kind(7,     'S1000', 'text'), undef,       "A generic SQLSTATE has no kind");
    is($D->error_kind(undef, undef,   undef),  undef,       "Nothing at all has no kind");
    is($D->native_error_kinds, {}, "No native codes by default");
};

subtest field_facts => sub {
    my %cases = (
        'integer'                     => {type => 'integer',                  affinity => 'numeric'},
        'VARCHAR(255)'                => {type => 'varchar',                  affinity => 'string',  size => 255},
        'character varying(50)'       => {type => 'character varying',        affinity => 'string',  size => 50},
        'numeric(10,2)'               => {type => 'numeric',                  affinity => 'numeric', size => 10},
        'timestamp(3) with time zone' => {type => 'timestamp with time zone', affinity => 'string',  size => 3},
        'int(10) unsigned zerofill'   => {type => 'int',                      affinity => 'numeric', size => 10},
        'integer[]'                   => {type => 'integer',                  affinity => 'numeric'},
        'INTEGER[3]'                  => {type => 'integer',                  affinity => 'numeric'},
        "enum('a','b')"               => {type => 'enum',                     affinity => 'string'},
        'STRUCT(a DECIMAL(10,2))'     => {type => 'struct',                   affinity => 'string'},
        'mediumblob'                  => {type => 'mediumblob',               affinity => 'binary'},
        'UBIGINT'                     => {type => 'ubigint',                  affinity => 'numeric'},
        'varbinary(16)'               => {type => 'varbinary',                affinity => 'binary', size => 16},
        'jsonb'                       => {type => 'jsonb',                    affinity => 'string'},
        'bool'                        => {type => 'bool',                     affinity => 'boolean'},
        'bit(8)'                      => {type => 'bit',                      affinity => 'string', size => 8},
        'something_new'               => {type => 'something_new',            affinity => 'string'},
    );
    for my $db_type (sort keys %cases) {
        is($D->field_facts($db_type), {db_type => $db_type, %{$cases{$db_type}}}, "'$db_type'");
    }

    is($D->field_facts('my_domain', 'bytea'),       {db_type => 'my_domain', type => 'my_domain', affinity => 'binary'},                                    "A base type decides the affinity");
    is($D->field_facts('integer', undef, 1, 1),     {db_type => 'integer', type => 'integer', affinity => 'numeric', db_fills => 1, db_refuses_value => 1}, "Fill and refuse facts are set when true");
    is($D->field_facts('integer', undef, 0, undef), {db_type => 'integer', type => 'integer', affinity => 'numeric'},                                       "and absent otherwise");
};

subtest grouping => sub {
    my $keys = $D->_keys_by_table([[t => 1, 'a'], [t => 2, 'b'], [t => 1, 'c'], [u => 1, 'd']]);
    is($keys, {t => {1 => [['a'], ['c']], 2 => [['b']]}, u => {1 => [['d']]}}, "Rows group by table and key, in row order");

    my %tables = (
        t     => {pk => ['id'],     unique => [], fk => {}, fields => {map { $_ => {} } qw/id a b x z/}},
        nopk  => {pk => undef,      unique => [], fk => {}},
        other => {pk => ['b', 'a'], unique => [], fk => {}},
    );

    $D->_add_unique(
        \%tables,
        $D->_keys_by_table([
            [t    => 'pk_again', 'id'],
            [t    => 'ab',       'b'], [t => 'ab',   'a'],
            [t    => 'ba',       'a'], [t => 'ba',   'b'],
            [t    => 'expr',     'x'], [t => 'expr', undef],
            [t    => 'z',        'z'],
            [t    => 'ghost',    'nope'],
            [gone => 'k',        'x'],
        ])
    );
    is($tables{t}->{unique}, [['a', 'b'], ['z']], "Unique keys: sorted, deduplicated, without the primary key, a key over an expression, or one naming a field the table lacks");
    ok(!$tables{gone}, "A key on a table not scanned is ignored");

    $D->_add_fks(
        \%tables,
        $D->_keys_by_table([
            [t    => 1, 'o_id', 'other', 'a'],
            [t    => 2, 'o_id', 'other', 'a'],                                     # a duplicate
            [t    => 3, 'x',    'other', undef], [t => 3, 'y', 'other', undef],    # the other table's primary key
            [t    => 4, 'p',    'nopk',  undef],                                   # unusable
            [t    => 5, 'p',    'far',   'id'],                                    # a table outside the map
            [t    => 6, 'id',   't',     'id'],
            [nopk => 1, 'q',    't',     'id'],
        ])
    );
    is(
        $tables{t}->{fk},
        {other => [{o_id => 'a'}, {x => 'b', y => 'a'}], far => [{p => 'id'}], t => [{id => 'id'}]},
        "Foreign keys: grouped by the other table, deduplicated, with implied fields taken from its primary key",
    );
    is($tables{nopk}->{fk}, {t => [{q => 'id'}]}, "Each table gets its own");
};

subtest scan => sub {
    my %rows = (
        tables => [['users'], ['0']],
        fields => [['users', 'id', 'integer', undef], ['users', 'name', 'varchar(5)', undef], ['0', '0', 'int', undef], ['view', 'x', 'int', undef]],
        pk     => [['users', 'id'], ['0', '0']],
        unique => [['users', 'k', 'name']],
        fk     => [['0', 'k', '0', 'users', 'id']],
    );
    my $dbh   = mock {} => (add => [selectall_arrayref => sub { $rows{$_[1]} }]);
    my $guard = mock $D => (
        add => [
            map {
                my $k = $_;
                ("${k}_sql" => sub { $k })
            } keys %rows
        ]
    );

    is(
        $D->scan($dbh),
        {
            users => {
                fields => {id => {table => 'users', name => 'id', db_type => 'integer', type => 'integer', affinity => 'numeric'}, name => {table => 'users', name => 'name', db_type => 'varchar(5)', type => 'varchar', size => 5, affinity => 'string'}},
                pk     => ['id'],
                unique => [['name']],
                fk     => {},
            },
            0 => {fields => {0 => {table => '0', name => '0', db_type => 'int', type => 'int', affinity => 'numeric'}}, pk => ['0'], unique => [], fk => {users => [{0 => 'id'}]}},
        },
        "The scan queries become map data; rows for tables not scanned are ignored",
    );
};

done_testing;
