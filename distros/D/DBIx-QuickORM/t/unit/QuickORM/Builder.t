use Test2::V0 -target => 'DBIx::QuickORM';
use lib 't/lib';
use DBIx::QuickORM::Tester qw/dbs_do all_dbs/;

ok(1);
done_testing;

__END__
BEGIN {
    no strict 'refs';
    $CLASS->import(@{"$CLASS\::EXPORT_OK"});
    imported_ok(@{"$CLASS\::EXPORT_OK"});

    package DBIx::QuickORM::ORM;
    *main::STATE = \*DBIx::QuickORM::STATE;
}

sub db_common {
    my $dbname = shift;

    db_class $dbname;
    db_name 'quickdb';
    sql_spec foo => 'bar';
    db_user '';
    db_password '';
}

dbs_do db => sub {
    my ($dbname, $dbc, $st) = @_;
    imported_ok('db');

    my $dba = db 'dba' => sub {
        db_common($dbname);

        db_attributes foo => 'bar';
        db_attributes {baz => 'bat', apple => 'orange'};
        db_connect sub { $dbc->connect };
    };

    unless ($dbname eq 'SQLite') {
        my $dbb = db 'dbb' => sub {
            db_common($dbname);

            db_host "127.0.0.1";
            db_port 123;
        };

        like($dbb->dsn, qr/dbname=quickdb;host=127\.0\.0\.1;port=123;/, "host+port");
    }

    is(
        $dba->attributes,
        {
            AutoCommit          => T(),
            AutoInactiveDestroy => T(),
            PrintError          => T(),
            RaiseError          => T(),
            apple               => 'orange',
            baz                 => 'bat',
            foo                 => 'bar',
        },
        "All attributes set"
    );

    my %dbs;
    $dbs{'connect'} = db 'connect' => sub {
        db_common($dbname);
        db_connect sub { $dbc->connect };
    };

    $dbs{'dsn'} = db 'dsn' => sub {
        db_common($dbname);
        db_dsn $dbc->connect_string('quickdb');
    };

    unless ($dbname eq 'SQLite') {
        $dbs{'socket'} = db 'socket' => sub {
            db_common($dbname);

            if ($dbname eq 'PostgreSQL') {
                db_socket $dbc->dir; # Bug in DBIx::QuickDB?
            }
            else {
                db_socket $dbc->socket;
            }
        };
    }

    for my $id (keys %dbs) {
        my $db = $dbs{$id};

        isa_ok(
            $db,
            ["DBIx::QuickORM::DB", "DBIx::QuickORM::DB::$dbname"],
            "Got the database instance ($id)",
        );

        my $con = $db->connect;
        isa_ok($con, ['DBIx::QuickORM::Connection'], "Can get database connection");
        isa_ok($con->dbh, ['DBI::db'], "Can get a dbh");

        is($db->db_name, 'quickdb', "Set the db name");

        isa_ok($db->sql_spec, ['DBIx::QuickORM::SQLSpec'], "Specs object");
        is(
            $db->sql_spec,
            {'overrides' => {}, 'global' => {'foo' => 'bar'}},
            "Specs are set"
        );

        is($db->user, '', "User is set to empty string");
        is($db->password, '', "Password is set to empty string");
    }
};

dbs_do orm => sub {
    my ($dbname, $dbc, $st) = @_;
    imported_ok('orm');

    my $sth = $dbc->connect->do(<<"    EOT");
    CREATE TABLE orm_test(
        orm_test_id     INTEGER     PRIMARY KEY
    );
    EOT

    my $foo = orm foo => sub {
        db foo => sub {
            db_common($dbname);
            db_connect sub { $dbc->connect };
        };

        schema foo => sub {
            autofill 0;

            table foo => sub {
                column foo_id => sub {
                    primary_key;
                    serial;
                    sql_spec(
                        mysql      => {type => 'INTEGER'},
                        postgresql => {type => 'SERIAL'},
                        sqlite     => {type => 'INTEGER'},
                        type       => 'INTEGER',    # Fallback
                    );
                };

                column name => sub {
                    unique;
                    sql_spec(type => 'VARCHAR(128)');
                };
            };
        };
    };

    isa_ok($foo,             ['DBIx::QuickORM::ORM'],        "Got an orm instance");
    isa_ok($foo->db,         ['DBIx::QuickORM::DB'],         "Can get the db");
    isa_ok($foo->schema,     ['DBIx::QuickORM::Schema'],     "Can get the schema");
    isa_ok($foo->connection, ['DBIx::QuickORM::Connection'], "Can get the connection");

    if(ok(my $source = $foo->source('foo'), "Can get source for table")) {
        isa_ok($source, ['DBIx::QuickORM::Source'],  "Can get a table source");
    }

    like(
        dies { $foo->source('orm_test') },
        qr{'orm_test' is not defined in the schema as a table/view, or temporary table/view},
        "Cannot get source for orm_test because we did not specify it in the schema, and autofill was turned off"
    );

    my $bar = orm bar => sub {
        db foo => sub {
            db_common($dbname);
            db_connect sub { $dbc->connect };
        };

        schema foo => sub {
            autofill 1;
        };
    };

    isa_ok($bar,             ['DBIx::QuickORM::ORM'],        "Got an orm instance");
    isa_ok($bar->db,         ['DBIx::QuickORM::DB'],         "Can get the db");
    isa_ok($bar->schema,     ['DBIx::QuickORM::Schema'],     "Can get the schema");
    isa_ok($bar->connection, ['DBIx::QuickORM::Connection'], "Can get the connection");

    if(ok(my $source = $bar->source('orm_test'), "Can get source for table")) {
        isa_ok($source, ['DBIx::QuickORM::Source'],  "Can get a table source");

        ok(my $table = $source->table, "Got table");
        isa_ok($table, ['DBIx::QuickORM::Table'], "Table is the correct type");

        ok(!$table->is_temp, "Not a temporary table");
        ok(!$table->is_view, "Not a view");
        is($table->primary_key, ['orm_test_id'], "Got primary key columns");
        is($table->name, 'orm_test', "Got correct table name");
        isa_ok($table->column('orm_test_id'), ['DBIx::QuickORM::Table::Column'], "Can get column definition");
    }

    like(
        dies { orm 'xxx', "foo", "bar"; },
        qr/The `orm\(name, db, schema\)` form can only be used under a mixer builder/,
        "orm(name, db, schema) outside of mixer"
    );

    local %STATE = (MIXER => { dbs => {}, schemas => {} });

    like(
        dies { orm 'xxx', "foo", "bar"; },
        qr/The 'foo' database is not defined/,
        "Invalid db",
    );

    $STATE{MIXER}{dbs}{foo} = 1;

    like(
        dies { orm 'xxx', "foo", "bar"; },
        qr/The 'bar' schema is not defined/,
        "Invalid schema",
    );

    local %STATE;

    like(
        dies {
            my $orm = orm sub {
                db xyz => sub { db_common(); db_class 'SQLite'; db_connect sub {} };
                $STATE{DB} = {class => 'SQLite'};
            },
        },
        qr/orm was given more than 1 database/,
        "Cannot provide multiple DBs"
    );

    local %STATE;

    like(
        dies {
            my $orm = orm sub {
                db xyz => sub { db_common(); db_class 'SQLite'; db_connect sub {} };
                my %s;
                schema yyy => sub { %s = %{$STATE{SCHEMA}} };
                $STATE{SCHEMA} = \%s;
            },
        },
        qr/orm was given more than 1 schema/,
        "Cannot provide multiple schemas"
    );

};

#sub orm {
#    my $cb       = ref($_[-1]) eq 'CODE' ? pop : undef;
#    my $new_args = ref($_[-1]) eq 'HASH' ? pop : {};
#    my ($name, $db, $schema) = @_;
#
#    my @caller = caller;
#
#    my %params = (
#        name    => $name // 'orm',
#        created => "$caller[1] line $caller[2]",
#        plugins => _push_plugins(),
#    );
#
#    if ($db || $schema) {
#        my $mixer = $STATE{MIXER} or croak "The `orm(name, db, schema)` form can only be used under a mixer builder";
#
#        if ($db) {
#            $params{db} = $mixer->{dbs}->{$db} or croak "The '$db' database is not defined";
#        }
#        if ($schema) {
#            $params{schema} = $mixer->{schemas}->{$schema} or croak "The '$schema' schema is not defined";
#        }
#    }
#
#    local $STATE{PLUGINS} = $params{plugins};
#    local $STATE{ORM}    = \%params;
#    local $STATE{STACK}   = ['ORM', @{$STATE{STACK} // []}];
#
#    local $STATE{DB}        = undef;
#    local $STATE{RELATIONS} = undef;
#    local $STATE{SCHEMA}    = undef;
#
#    set_subname('orm_callback', $cb) if subname($cb) ne '__ANON__';
#    $cb->(%STATE);
#
#    if (my $db = delete $STATE{DB}) {
#        $db = _build_db($db);
#        croak "orm was given more than 1 database" if $params{db};
#        $params{db} = $db;
#    }
#
#    if (my $schema = delete $STATE{SCHEMA}) {
#        $schema = _build_schema($schema);
#        croak "orm was given more than 1 schema" if $params{schema};
#        $params{schema} = $schema;
#    }
#
#    require DBIx::QuickORM::ORM;
#    my $orm = DBIx::QuickORM::ORM->new(%params, %$new_args);
#
#    if (my $mixer = $STATE{MIXER}) {
#        $mixer->{orms}->{$name} = $orm;
#    }
#    else {
#        croak "Cannot be called in void context outside of a mixer without a symbol name"
#            unless defined($name) || defined(wantarray);
#
#        if ($name && !defined(wantarray)) {
#            no strict 'refs';
#            *{"$caller[0]\::$name"} = set_subname $name => sub { $orm };
#        }
#    }
#
#    return $orm;
#}


subtest mixer => sub {
    my @dbs = all_dbs();
    my @orms;
    my $mixer = mixer sub {
        schema empty => sub {};

        schema manual => sub {
            table mixer_test => sub {
                column 'mixer_test_id';
                primary_key 'mixer_test_id';
            };
        };

        for my $dbs (@dbs) {
            my ($dbname, $dbc) = @$dbs;

            my $sth = $dbc->connect->do(<<"            EOT");
            CREATE TABLE mixer_test(
                mixer_test_id     INTEGER     PRIMARY KEY
            );
            EOT

            db $dbname => sub {
                db_common($dbname);
                db_connect sub { $dbc->connect };
            };

            for my $schema (qw/empty manual/) {
                push @orms => "$schema + $dbname";
                orm "$schema + $dbname" => sub {
                    db $dbname;
                    schema $schema;
                };
            }
        }
    };

    isa_ok($mixer->database($_->[0]), ['DBIx::QuickORM::DB'], "Got db '$_->[0]'") for @dbs;

    isa_ok($mixer->schema('empty'), ['DBIx::QuickORM::Schema'], "Got empty schema");
    isa_ok($mixer->schema('manual'), ['DBIx::QuickORM::Schema'], "Got manual schema");

    ok(@orms, "Got some orms");

    for my $orm_name (@orms) {
        ok(my $orm = $mixer->orm($orm_name), "Can get orm '$orm_name'");
        isa_ok($orm, ['DBIx::QuickORM::ORM'], "orm '$orm_name' is the right type");
    }

    {
        local *my_mixer;
        not_imported_ok('my_mixer');
        mixer my_mixer => sub {};
        imported_ok('my_mixer');
        isa_ok(my_mixer(), ['DBIx::QuickORM::Mixer'], "Got the mixer via injected sub");
    }
    ok(!__PACKAGE__->can('my_mixer'), "Removed symbol when done with it");

    like(
        dies { mixer sub { } },
        qr/Cannot be called in void context without a symbol name/,
        "Need non-void or a symbol name"
    );
};

done_testing;
