# NAME

DBIx::QuickORM - Composable ORM builder.

# DESCRIPTION

DBIx::QuickORM allows you to define ORMs with reusable and composible parts.

With this ORM builder you can specify:

- How to connect to one or more databases on one or more servers.
- One or more schema structures.
- Custom row classes to use.
- Plugins to use.

# DOCUMENTATION

The best place to start is [DBIx::QuickORM::Manual::QuickStart](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AManual%3A%3AQuickStart), which walks
you through connecting to a database and working with rows as objects in just
a few lines. Broader documentation - tutorials, guides, recipes, and worked
examples - lives in [DBIx::QuickORM::Manual](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AManual), the documentation hub. For a
brief index of every feature with links to where each is documented, see
[DBIx::QuickORM::Manual::Features](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AManual%3A%3AFeatures).

The `DBIx::QuickORM` module itself exports a DSL (a set of builder functions)
for defining ORMs, databases, servers, schemas, tables, columns, and links.
The rest of this document is the reference for those DSL functions: what each
one does and how they nest. It is intentionally function-focused rather than
an end-to-end guide - for that, start with the manual.

# ORM BUILDER EXPORTS

You get all these when using DBIx::QuickORM.

- `orm $NAME => sub { ... }`
- `my $orm = orm($NAME)`

    Define or fetch an ORM.

        orm myorm => sub {
            db mydb => sub { ... };
            schema myschema => sub { ... };
        };

        my $orm = orm('myorm');

    You can also compose using databases or schemas you defined previously:

        db mydb1 => sub { ... };
        db mydb2 => sub { ... };

        schema myschema1 => sub { ... };
        schema myschema2 => sub { ... };

        orm myorm1 => sub {
            db 'mydb1';
            schema 'myschema1';
        };

        orm myorm2 => sub {
            db 'mydb2';
            schema 'myschema2';
        };

        orm my_mix_a => sub {
            db 'mydb1';
            schema 'myschema2';
        };

        orm my_mix_b => sub {
            db 'mydb2';
            schema 'myschema1';
        };

    Used at the top level. Can contain `db`, `schema`, `handle_class`,
    `autofill`, plus `alt`, `plugin`, `plugins`, `meta`, and `build_class`.

- `alt $VARIANT => sub { ... }`

    Can be used to add variations to any builder:

        orm my_orm => sub {
            db mydb => sub {
                # ************************************
                alt mysql => sub {
                    dialect 'MySQL';
                };

                alt pgsql => sub {
                    dialect 'PostgreSQL';
                };
                # ************************************
            };

            schema my_schema => sub {
                table foo => sub {
                    column x => sub {
                        identity();

                        # ************************************
                        alt mysql => sub {
                            type \'BIGINT';
                        };

                        alt pgsql => sub {
                            type \'BIGSERIAL';
                        };
                        # ************************************
                    };
                }
            };
        };

    Variants can be fetched using the colon `:` in the name:

        my $pg_orm    = orm('my_orm:pgsql');
        my $mysql_orm = orm('my_orm:mysql');

    This works in `orm()`, `db()`, `schema()`, `table()`, and `row()` builders. It does
    cascade, so if you ask for the `mysql` variant of an ORM, it will also give you
    the `mysql` variants of the database, schema, tables and rows.

    Can be nested under any builder. Can contain whatever the builder it is nested
    under can contain.

- `db $NAME`
- `db $NAME => sub { ... }`
- `$db = db $NAME`
- `$db = db $NAME => sub { ... }`

    Used to define a database.

        db mydb => sub {
            dialect 'MySQL';
            host 'mysql.myapp.com';
            port 1234;
            user $MYSQL_USER;
            pass $MYSQL_PASS;
            db_name 'myapp_mysql';    # In mysql the db is named myapp_mysql
        };

    Can also be used to fetch a database by name:

        my $db = db('mydb');

    Can also be used to tell an ORM which database to use:

        orm myorm => sub {
            db 'mydb';
            ...
        };

    Used at the top level, or nested under `orm` or `server`. Can contain
    `driver`, `dialect`, `connect`, `attributes`, `creds`, `dsn`, `host`,
    `port`, `socket`, `user`, `pass`, and `db_name`.

- `dialect '+DBIx::QuickORM::Dialect::PostgreSQL'`
- `dialect 'PostgreSQL'`
- `dialect 'MySQL'`
- `dialect 'MySQL::MariaDB'`
- `dialect 'MySQL::Percona'`
- `dialect 'MySQL::Community'`
- `dialect 'SQLite'`

    Specify what dialect of SQL should be used. This is important for reading
    schema from an existing database, or writing new schema SQL.

    `DBIx::QuickORM::Dialect::` will be prefixed to the start of any string
    provided unless it starts with a plus `+`, in which case the plus is removed
    and the rest of the string is left unmodified.

    The following are all supported by DBIx::QuickORM by default

    - [PostgreSQL](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADialect%3A%3APostgreSQL)

        For interacting with PostgreSQL databases.

    - [MySQL](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADialect%3A%3AMySQL)

        For interacting with generic MySQL databases. Selecting this will auto-upgrade
        to MariaDB, Percona, or Community variants if it can detect the variant. If it
        cannot detect the variant then the generic will be used.

        **NOTE:** Using the correct variant can produce better results. For example
        MariaDB supports `RETURNING` on `INSERT`s, Percona and Community variants
        do not, and thus need a second query to fetch the data post-`INSERT`, and using
        `last_insert_id` to get auto-generated primary keys. DBIx::QuickORM is aware
        of this and will use returning when possible.

    - [MySQL::MariaDB](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADialect%3A%3AMySQL%3A%3AMariaDB)

        For interacting with MariaDB databases.

    - [MySQL::Percona](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADialect%3A%3AMySQL%3A%3APercona)

        For interacting with MySQL as distributed by Percona.

    - [MySQL::Community](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADialect%3A%3AMySQL%3A%3ACommunity)

        For interacting with the Community Edition of MySQL.

    - [SQLite](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADialect%3A%3ASQLite)

        For interacting with SQLite databases.

    - [DuckDB](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ADialect%3A%3ADuckDB)

        For interacting with DuckDB databases. DuckDB is embedded (like SQLite) and
        supports `RETURNING` on all DML, but does **not** support savepoints, so
        nested transactions are unavailable.

    Can be nested under `db` or `server`.

- `driver '+DBD::Pg'`
- `driver 'Pg'`
- `driver 'mysql'`
- `driver 'MariaDB'`
- `driver 'SQLite'`

    Usually you do not need to specify this as your dialect should specify the
    correct one to use. However in cases like MySQL and MariaDB they are more or
    less interchangeable and you may want to override the default.

    Specify what DBI driver should be used. `DBD::` is prefixed to any string you
    specify unless it starts with `+`, in which case the plus is stripped and the
    rest of the module name is unmodified.

    **NOTE:** DBIx::QuickORM can use either [DBD::mysql](https://metacpan.org/pod/DBD%3A%3Amysql) or [DBD::MariaDB](https://metacpan.org/pod/DBD%3A%3AMariaDB) to
    connect to any of the MySQL variants. It will default to [DBD::MariaDB](https://metacpan.org/pod/DBD%3A%3AMariaDB) if it
    is installed and you have not requested [DBD::mysql](https://metacpan.org/pod/DBD%3A%3Amysql) directly.

    Can be nested under `db` or `server`.

- `attributes \%HASHREF`
- `attributes(attr => val, ...)`

    Set the attributes of the database connection.

    This can take a hashref or key-value pairs.

    This will override all previous attributes, it does not merge.

        db mydb => sub {
            attributes { foo => 1 };
        };

    Or:

        db mydb => sub {
            attributes foo => 1;
        };

    Can be nested under `db` or `server`.

- `host $HOSTNAME`
- `hostname $HOSTNAME`

    Provide a hostname or IP address for database connections

        db mydb => sub {
            host 'mydb.mydomain.com';
        };

    Can be nested under `db` or `server`.

- `port $PORT`

    Provide a port number for database connection.

        db mydb => sub {
            port 1234;
        };

    Can be nested under `db` or `server`.

- `socket $SOCKET_PATH`

    Provide a socket instead of a host+port

        db mydb => sub {
            socket '/path/to/db.socket';
        };

    Can be nested under `db` or `server`.

- `user $USERNAME`
- `username $USERNAME`

    provide a database username

        db mydb => sub {
            user 'bob';
        };

    Can be nested under `db` or `server`.

- `pass $PASSWORD`
- `password $PASSWORD`

    provide a database password

        db mydb => sub {
            pass 'hunter2'; # Do not store any real passwords in plaintext in code!!!!
        };

    Can be nested under `db` or `server`.

- `creds sub { return \%CREDS }`

    Allows you to provide a coderef that will return a hashref with all the
    necessary database connection fields.

    This is mainly useful if you credentials are in an encrypted YAML or JSON file
    and you have a method to decrypt and read it returning it as a hash.

        db mydb => sub {
            creds sub { ... };
        };

    Can be nested under `db` or `server`.

- `connect sub { ... }`
- `connect \&connect`

    Instead of providing all the other fields, you may specify a coderef that
    returns a [DBI](https://metacpan.org/pod/DBI) connection.

    **IMPORTANT:** This function must always return a new [DBI](https://metacpan.org/pod/DBI) connection it
    **MUST NOT** cache it!

        sub mydb => sub {
            connect sub { ... };
        };

    Can be nested under `db` or `server`.

- `dsn $DSN`

    Specify the DSN used to connect to the database. If not provided then an
    attempt will be made to construct a DSN from other parameters, if they are
    available.

        db mydb => sub {
            dsn "dbi:Pg:dbname=foo";
        };

    Can be nested under `db` or `server`.

- `server $NAME => sub { ... }`

    Used to define a server with multiple databases. This is a way to avoid
    re-specifying credentials for each database you connect to.

    You can use `db('server_name.db_name')` to fetch the database.

    Basically this allows you to specify any database fields once in the server, then
    define any number of databases that inherit them.

    Example:

        server pg => sub {
            host 'pg.myapp.com';
            user $USER;
            pass $PASS;
            attributes { work_well => 1 }

            db 'myapp';       # Points at the 'myapp' database on this db server
            db 'otherapp';    # Points at the 'otherapp' database on this db server

            # You can also override any if a special db needs slight modifications.
            db special => sub {
                attributes { work_well => 0, work_wrong => 1 };
            };
        };

        orm myapp => sub {
            db 'pg.myapp';
            ...;
        };

        orm otherapp => sub {
            db 'pg.otherapp';
            ...;
        };

    Used at the top level. Can contain `db` plus the same connection settings a
    `db` can contain (`driver`, `dialect`, `connect`, `attributes`, `creds`,
    `dsn`, `host`, `port`, `socket`, `user`, `pass`).

- `schema $NAME => sub { ... }`
- `$schema = schema($NAME)`
- `$schema = schema($NAME => sub { ... })`

    Used to either fetch or define a schema.

    When called with only 1 argument it will fetch the schema with the given name.

    When used inside an ORM builder it will set the schema for the ORM (all ORMs
    have exactly one schema).

    When called with 2 arguments it will define the schema using the coderef as a
    builder.

    When called in a non-void context it will return the compiled schema, otherwise
    it adds it to the ORM class.

        # Define the 'foo' schema:
        schema foo => sub {
            table a => sub { ... };
            table b => sub { ... };
        };

        # Fetch it:
        my $foo = schema('foo');

        # Define and compile one:
        my $bar = schema bar => sub { ... }

        # Use it in an orm:
        orm my_orm => sub {
            schema('foo');
            db(...);
        };

    Used at the top level, or nested under `orm`. Can contain `table`, `view`,
    `tables`, `row_class`, `sql`, and `link`.

- `table $NAME => sub { ... }`
- `table $CLASS`
- `table $CLASS => sub { ... }`

    Used to define a table, or load a table class.

        schema my_schema => sub {
            # Load an existing table
            table 'My::Table::Foo';

            # Define a new table
            table my_table => sub {
                column foo => sub { ... };
                primary_key('foo');
            };

            # Load an existing table, but make some changes to it
            table 'My::Table::Bar' => sub {
                # Override the row class used in the original
                row_class 'DBIx::QuickORM::Row';
            };
        };

    This will assume you are loading a table class if the double colon `::`
    appears in the name.  Otherwise it assumes you are defining a new table.
    This means it is not possible to load top-level packages as table classes,
    which is a feature, not a bug.

    Can be nested under `schema`. Can contain `column`, `columns`,
    `primary_key`, `unique`, `index`, `db_name`, `row_class`, `sql`, and
    `link`.

- `view $NAME => sub { ... }`
- `view $CLASS`
- `view $CLASS => sub { ... }`

    Used to define a view, or load a view class. Behaves exactly like `table`
    above, but produces a view instead of a table.

        schema my_schema => sub {
            view active_users => sub {
                column id   => sub { ... };
                column name => sub { ... };
            };
        };

    Can be nested under `schema`. Can contain the same things as `table`.

- `tables 'Table::Namespace'`

    Used to load all tables in the specified namespace:

        schema my_schema => sub {
            # Load My::Table::Foo, My::Table::Bar, etc.
            tables 'My::Table';
        };

    Can be nested under `schema`.

- `row_class '+My::Row::Class'`
- `row_class 'MyRowClass'`

    When fetching a row from a table, this is the class that each row will be
    blessed into.

    This can be provided as a default for a schema, or as a specific one to use in
    a table. When using table classes this will set the base class for the table as
    the table class itself will be the row class.

    If the class name has a plus `+` it will be stripped off and the class name will not
    be altered further. If there is no `+` then `DBIx::QuickORM::Row::` will be
    prefixed onto your string, and the resulting class will be loaded.

        schema my_schema => sub {
            # Uses My::Row::Class as the default for rows in all tables that do not override it.
            row_class '+My::Row::Class';

            table foo => sub {
                row_class 'Foo'; # Uses DBIx::QuickORM::Row::Foo as the row class for this table
            };
        };

    In a table class:

        package My::ORM::Table::Foo;
        use DBIx::QuickORM type => 'table';

        table foo => sub {
            # Sets the base class (@ISA) for this table class to 'My::Row::Class'
            row_class '+My::Row::Class';
        };

    Can be nested under `table` or `schema`.

- `db_name $NAME`

    Sometimes you want the ORM to use one name for a table or database, but the
    database server actually uses another. For example you may want the ORM to use the
    name `people` for a table, but the database actually uses the table name `populace`.
    You can use `db_name` to set the in-database name.

        table people => sub {
            db_name 'populace';

            ...
        };

    This can also be used to have a different name for an entire database in the
    orm from its actual name on the server:

        db theapp => sub {    # Name in the orm
            db_name 'myapp'    # Actual name on the server;
        };

    It works the same way for an individual column, letting the ORM use one name
    for a column while the database uses another:

        column people_id => sub {    # Name in the orm
            db_name 'id';            # Actual column name in the table
        };

    Can be nested under `table`, `db`, or `column`.

- `column NAME => sub { ... }`
- `column NAME => %SPECS`

    Define a column with the given name. By default the name is used both as the
    name the ORM uses for the column and as the actual name of the column in the
    database. To have the ORM use a different name from the database column, set
    `db_name` inside the column.

        column foo => sub {
            type \'BIGINT'; # Specify a type in raw SQL (can also accept DBIx::QuickORM::Type::*)

            not_null(); # Column cannot be null

            # This column is an identity column, or is a primary key using
            # auto-increment. OR similar
            identity();

            ...
        };

    Another simple way to do everything above:

        column foo => ('not_null', 'identity', \'BIGINT');

    Can be nested under `table`. Can contain `omit`, `nullable`, `not_null`,
    `identity`, `affinity`, `type`, `sql`, `default`, `primary_key`,
    `unique`, `link`, and `db_name`.

- `omit`

    When set on a column, the column will be omitted from `SELECT`s by default. When
    you fetch a row the column will not be fetched until needed. This is useful if
    a table has a column that is usually huge and rarely used.

        column foo => sub {
            omit;
        };

    In a non-void context it will return the string `omit` for use in a column
    specification without a builder.

        column bar => omit();

    Can be nested under `column`.

- `nullable()`
- `nullable(1)`
- `nullable(0)`
- `not_null()`
- `not_null(1)`
- `not_null(0)`

    Toggle nullability for a column. `nullable()` defaults to setting the column as
    nullable. `not_null()` defaults to setting the column as _not_ nullable.

        column not_nullable => sub {
            not_null();
        };

        column is_nullable => sub {
            nullable();
        };

    In a non-void context these will return a string, either `nullable` or
    `not_null`. These can be used in column specifications that do not use a
    builder.

        column foo => nullable();
        column bar => not_null();

    Can be nested under `column`.

- `identity()`
- `identity(1)`
- `identity(0)`

    Used to designate a column as an identity column. This is mainly used for
    generating schema SQL. In a sufficient version of PostgreSQL this will generate
    an identity column. It will fallback to a column with a sequence, or in
    MySQL/SQLite it will use auto-incrementing columns.

    In a column builder it will set (default) or unset the `identity` attribute of
    the column.

        column foo => sub {
            identity();
        };

    In a non-void context it will simply return `identity` by default or when given
    a true value as an argument. It will return an empty list if a false argument
    is provided.

        column foo => identity();

    Can be nested under `column`.

- `affinity('string')`
- `affinity('numeric')`
- `affinity('binary')`
- `affinity('boolean')`

    When used inside a column builder it will set the columns affinity to the one
    specified.

        column foo => sub {
            affinity 'string';
        };

    When used in a non-void context it will return the provided string. This case
    is only useful for checking for typos as it will throw an exception if you use
    an invalid affinity type.

        column foo => affinity('string');

    Can be nested under `column`.

- `type(\$sql)`
- `type("+My::Custom::Type") # The + is stripped off`
- `type("+My::Custom::Type", @CONSTRUCTION_ARGS)`
- `type("MyType") # Short for "DBIx::QuickORM::Type::MyType"`
- `type("MyType", @CONSTRUCTION_ARGS)`
- `type(My::Type->new(...))`

    Used to specify the type for the column. You can provide custom SQL in the form
    of a scalar referernce. You can also provide the class of a type, if you prefix
    the class name with a plus `+` then it will strip the `+` off and make no further
    modifications. If you provide a string without a `+` it will attempt to load
    `DBIx::QuickORM::Type::YOUR_STRING` and use that.

    In a column builder this will directly apply the type to the column being
    built.

    In scalar context this will return the constructed type object.

        column foo => sub {
            type 'MyType';
        };

        column foo => type('MyType');

    Can be nested under `column`.

- `sql($sql)`
- `sql(infix => $sql)`
- `sql(prefix => $sql)`
- `sql(postfix => $sql)`

    This is used when generating SQL to define the database.

    This allows you to provide custom SQL to define a table/column, or add SQL
    before (prefix) and after (postfix).

    Infix will prevent the typical SQL from being generated, the infix will be used
    instead.

    If no \*fix is specified then `infix` is assumed.

    Can be nested under `schema`, `table`, or `column`.

- `default(\$sql)`
- `default(sub { ... })`
- `%key_val = default(\$sql)`
- `%key_val = default(sub { ... })`

    When given a scalar reference it is treated as SQL to be used when generating
    SQL to define the column.

    When given a coderef it will be used as a default value generator for the
    column whenever DBIx::QuickORM `INSERT`s a new row.

    In void context it will apply the default to the column being defined, or will
    throw an exception if no column is being built.

        column foo => sub {
            default \"NOW()"; # Used when generating SQL for the table
            default sub { 123 }; # Used when inserting a new row
        };

    This can also be used without a codeblock:

        column foo => default(\"NOW()"), default(sub { 123 });

    In the above cases they return:

        (sql_default => "NOW()")
        (perl_default => sub { 123 })

    Can be nested under `column`.

- `columns(@names)`
- `columns(@names, \%attrs)`
- `columns(@names, sub { ... })`

    Define multiple columns at a time. If any attrs hashref or sub builder are
    specified they will be applied to **all** provided column names.

    Can be nested under `table`.

- `primary_key`
- `primary_key(@COLUMNS)`
- `primary_key(\%OPTIONS, @COLUMNS)`

    Used to define a primary key. When used under a table you must provide a
    list of columns. When used under a column builder it designates just that
    column as the primary key, no arguments would be accepted.

        table mytable => sub {
            column a => sub { ... };
            column b => sub { ... };

            primary_key('a', 'b');
        };

    Or to make a single column the primary key:

        table mytable => sub {
            column a => sub {
                ...
                primary_key();
            };
        };

    Can be nested under `table` or `column`.

    When the live database reports a different primary key than the one you
    declare here, schema construction croaks rather than silently picking one.
    Pass a leading options hashref with `override => 1` to declare that your
    key is intentional and should win over the database's:

        table mytable => sub {
            column a => sub { ... };

            primary_key({override => 1}, 'a');
        };

    The options hashref works under a column builder too:

        column a => sub {
            ...
            primary_key({override => 1});
        };

- `unique`
- `unique(@COLUMNS)`

    Used to define a unique constraint. When used under a table you must provide a
    list of columns. When used under a column builder it designates just that
    column as unique, no arguments would be accepted.

        table mytable => sub {
            column a => sub { ... };
            column b => sub { ... };

            unique('a', 'b');
        };

    Or to make a single column unique:

        table mytable => sub {
            column a => sub {
                ...
                unique();
            };
        };

    Can be nested under `table` or `column`.

- `index $NAME => \@COLUMNS`
- `index $NAME => \@COLUMNS, \%PARAMS`
- `my $index = index(...)`

    Define an index on a table. Pass the index name, an arrayref of columns, and an
    optional hashref of extra parameters.

        table mytable => sub {
            column a => sub { ... };
            column b => sub { ... };

            index my_idx => ['a', 'b'];
        };

    In a non-void context it returns the index hashref instead of attaching it to
    the table.

    Can be nested under `table`.

- `link \@LOCAL => \@OTHER`
- `link [$table => \@columns]`

    Define a foreign-key style link/relationship. The exact arguments depend on
    context: under a `schema` you provide both the local and the foreign side;
    under a `column` the local side is taken to be the current column and you
    provide only the side being linked to.

        # In a schema, linking two tables:
        schema my_schema => sub {
            ...
            link ['foo', ['foo_id']] => ['bar', ['id']];
        };

        # In a column, linking just this column:
        table foo => sub {
            column bar_id => sub {
                link ['bar', ['id']];
            };
        };

    Can be nested under `schema` or `column`.

- `build_class $CLASS`

    Use this to override the class being built by a builder.

        schema myschema => sub {
            build_class 'DBIx::QuickORM::Schema::MySchemaSubclass';

            ...
        };

    Can be nested under any builder.

- `my $meta = meta`

    Get the current builder meta hashref

        table mytable => sub {
            my $meta = meta();

            # This is what db_name('foo') would do!
            $meta->{name} = 'foo';
        };

    Can be nested under any builder.

- `plugin '+My::Plugin'`
- `plugin 'MyPlugin'`
- `plugin 'MyPlugin' => @CONSTRUCTION_ARGS`
- `plugin 'MyPlugin' => \%CONSTRUCTION_ARGS`
- `plugin My::Plugin->new()`

    Load a plugin and apply it to the current builder (or top level) and all nested
    builders below it.

    The `+` prefix can be used to specify a fully qualified plugin package name.
    Without the plus `+` the namespace `DBIx::QuickORM::Plugin::` will be prefixed to
    the string.

        plugin '+My::Plugin';    # Loads 'My::Plugin'
        plugin 'MyPlugin';       # Loads 'DBIx::QuickORM::Plugin::MyPlugin

    You can also provide an already blessed plugin:

        plugin My::Plugin->new();

    Or provide construction args:

        plugin '+My::Plugin' => (foo => 1, bar => 2);
        plugin '+MyPlugin'   => {foo => 1, bar => 2};

    Can be used at the top level or nested under any builder.

- `$plugins = plugins()`
- `plugins '+My::Plugin', 'MyPlugin' => \%ARGS, My::Plugin->new(...), ...`

    Load several plugins at once, if a plugin class is followed by a hashref it is
    used as construction arguments.

    Can also be used with no arguments to return an arrayref of all active plugins
    for the current scope.

    Can be used at the top level or nested under any builder.

- `handle_class '+My::Handle::Class'`
- `handle_class 'MyHandleClass'`

    Set the default handle class for the ORM. Handles are the objects returned when
    you query the ORM for rows.

    If the class name has a plus `+` it will be stripped off and the class name
    will not be altered further. If there is no `+` then `DBIx::QuickORM::Handle`
    is assumed.

        orm my_orm => sub {
            handle_class '+My::Handle::Class';
        };

    Can be nested under `orm`.

- `autofill()`
- `autofill($CLASS)`
- `autofill(sub { ... })`
- `autofill($CLASS, sub { ... })`
- `autofill $CLASS`
- `autofill sub { ... }`
- `autofill $CLASS => sub { ... }`

    Used inside an `orm()` builder. This tells QuickORM to build an
    [DBIx::QuickORM::Schema](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ASchema) object by asking the database what tables and columns
    it has.

        orm my_orm => sub {
            db ...;

            autofill; # Autofill schema from the db itself
        };

    By default the [DBIx::QuickORM::Schema::Autofill](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ASchema%3A%3AAutofill) class is used to do the
    autofill operation. You can provide an alternate class as the first argument if
    you wish to use a custom one.

    There are additional operations that can be done inside autofill, just provide
    a subref and call them:

        autofill sub {
            autotype $TYPE;                         # Automatically use DBIx::QuickORM::Type::TYPE classes when applicable
            autoskip table => qw/table1 table2/;    # Do not generate schema for the specified tables
            autorow 'My::Row::Namespace';           # Automatically generate My::Row::Namespace::TABLE classes, also loading any that exist as .pm files
            autoname TYPE => sub { ... };           # Custom names for tables, accessors, links, etc.
            autohook HOOK => sub { ... };           # Run behavior at specific hook points
        };

    Can be nested under `orm`. Can contain `autotype`, `autoskip`, `autorow`,
    `autoname`, and `autohook`.

- `autotype $TYPE_CLASS`
- `autotype 'JSON'`
- `autotype '+DBIx::QuickORM::Type::JSON'`
- `autotype 'UUID'`
- `autotype '+DBIx::QuickORM::Type::UUID'`

    Load custom [DBIx::QuickORM::Type](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3AType) subclasses. If a column is found with the
    right type then the type class will be used to inflate/deflate the values
    automatically.

    Can be nested under `autofill`.

- `autoskip table =` qw/table1 table2 .../>
- `autoskip column =` qw/col1 col2 .../>

    Skip defining schema entries for the specified tables or columns.

    Can be nested under `autofill`.

- `autorow 'My::App::Row'`
- `autorow $ROW_BASE_CLASS`

    Generate `My::App::Row::TABLE` classes for each table autofilled. If you write
    a `My/App/Row/TABLE.pm` file it will be loaded as well.

    If you define a `My::App::Row` class it will be loaded and all table rows will
    use it as a base class. If no such class is found the new classes will use
    [DBIx::QuickORM::Row](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ARow) as a base class.

    Can be nested under `autofill`.

- `autoname link_accessor => sub { ... }`
- `autoname field_accessor => sub { ... }`
- `autoname table => sub { ... }`
- `autoname link => sub { ... }`

    You can name the `$row->FIELD` accessor:

        autoname field_accessor => sub {
            my %params     = @_;
            my $name       = $params{name};   # Name that would be used by default
            my $field_name = $params{field};  # Usually the same as 'name'
            my $table      = $params{table};  # The DBIx::QuickORM::Schema::Table object
            my $column     = $params{column}; # The DBIx::QuickORM::Schema::Table::Column object

            return $new_name;
        };

    You can also name the `$row->LINK` accessor

        autoname link_accessor => sub {
            my %params = @_;
            my $name         = $params{name};        # Name that would be used by default
            my $link         = $params{link};        # DBIx::QuickORM::Link object
            my $table        = $params{table};       # DBIx::QuickORM::Schema::Table object
            my $linked_table = $params{linked_table} # Name of the table being linked to

            # If the foreign key points to a unique row, then the accessor will
            # return a single row object:
            return "obtain_" . $linked_table if $link->unique;

            # If the foreign key points to non-unique rows, then the accessor will
            # return a DBIx::QuickORM::Query object:
            return "select_" . $linked_table . "s";
        };

    You can also provide custom names for tables. When using the table in the ORM
    you would use the name provided here, but under the hood the ORM will use the
    correct table name in queries.

        autoname table => sub {
            my %params = @_;
            my $name   = $params{name};     # The name of the table in the database
            my $table  = $params{table};    # A hashref that will be blessed into the DBIx::QuickORM::Schema::Table once the name is set.

            return $new_name;
        };

    You can also set aliases for links before they are constructed:

        autoname link => sub {
            my %params       = @_;
            my $in_table     = $params{in_table};
            my $in_fields    = $params{in_fields};
            my $fetch_table  = $params{fetch_table};
            my $fetch_fields = $params{fetch_fields};

            return $alias;
        };

    Can be nested under `autofill`.

- `autohook HOOK =` sub { my %params = @\_; ... }>

    See [DBIx::QuickORM::Schema::Autofill](https://metacpan.org/pod/DBIx%3A%3AQuickORM%3A%3ASchema%3A%3AAutofill) for a list of hooks and their params.

    Can be nested under `autofill`.

# YOUR ORM PACKAGE EXPORTS

- `$orm_meta = orm()`
- `$orm = orm($ORM_NAME)`
- `$db = orm(db => $DB_NAME)`
- `$schema = orm(schema => $SCHEMA_NAME)`
- `$orm_variant = orm("${ORM_NAME}:${VARIANT}")`
- `$db_variant = orm(db => "${DB_NAME}:${VARIANT}")`
- `$schema_variant = orm(schema => "${SCHEMA_NAME}:${VARIANT}")`

    This function is the one-stop shop to access any ORM, schema, or database instances
    you have defined.

## RENAMING THE EXPORT

You can rename the `orm()` function at import time by providing an alternate
name.

    use My::ORM qw/renamed_orm/;

    my $orm = renamed_orm('my_orm');

# SOURCE

The source code repository for DBIx::QuickORM can be found at
[https://https://github.com/exodist/DBIx-QuickORM](https://https://github.com/exodist/DBIx-QuickORM).

# MAINTAINERS

- Chad Granum <exodist7@gmail.com>

# AUTHORS

- Chad Granum <exodist7@gmail.com>

# COPYRIGHT

Copyright Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See [https://dev.perl.org/licenses/](https://dev.perl.org/licenses/)
