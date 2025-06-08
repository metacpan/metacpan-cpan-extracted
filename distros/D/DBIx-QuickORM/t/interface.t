use Test2::V0 -target => 'DBIx::QuickORM';

{
    package DBIx::QuickORM::DB::Fake;
    $INC{'DBIx/QuickORM/DB/Fake.pm'} = __FILE__;
    our @ISA = ('DBIx::QuickORM::DB');
    use DBIx::QuickORM::Util::HashBase;

    package DBIx::QuickORM::Type::MyType;
    $INC{'DBIx/QuickORM/Type/MyType.pm'} = __FILE__;
    use DBIx::QuickORM::Util::HashBase;
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Type';
    sub qorm_inflate  { }
    sub qorm_deflate  { }
    sub qorm_compare  { }
    sub qorm_affinity { }
    sub qorm_sql_type { }

    package DBIx::QuickORM::Row::ClassA;
    $INC{'DBIx/QuickORM/Row/ClassA.pm'} = __FILE__;
    our @ISA = ('DBIx::QuickORM::Row');
    use DBIx::QuickORM::Util::HashBase;

    package DBIx::QuickORM::Row::ClassB;
    $INC{'DBIx/QuickORM/Row/ClassB.pm'} = __FILE__;
    our @ISA = ('DBIx::QuickORM::Row');
    use DBIx::QuickORM::Util::HashBase;

    package DBIx::QuickORM::Plugin::My::Plugin;
    $INC{'DBIx/QuickORM/Plugin/My/Plugin.pm'} = __FILE__;
    our @ISA = ('DBIx::QuickORM::Plugin');
    use DBIx::QuickORM::Util::HashBase;

    package DBIx::QuickORM::Handle::TestHandle;
    $INC{'DBIx/QuickORM/Handle/TestHandle.pm'} = __FILE__;
    use Role::Tiny::With qw/with/;
    use parent 'DBIx::QuickORM::Handle';
    with 'DBIx::QuickORM::Role::Handle';
}

{
    package Test::ORM;
    use Test2::V0 qw/!pass !meta/, meta => {'-as' => 't2_meta'};
    use Scalar::Util qw/blessed/;

    use ok 'DBIx::QuickORM';

    imported_ok(qw{
        plugin
        plugins
        meta
        orm

        handle_class

        build_class

        server
         driver
         dialect
         attributes
         host
         port
         socket
         user
         pass
         db
          connect
          dsn

        schema
         alt
         row_class
         table
          db_name
          column
           affinity
           omit
           nullable
           not_null
           identity
           type
          columns
          primary_key
          unique
          index
         link

        builder
        import
    });

    {
        package Another::Importer;
        use Test2::V0 qw/imported_ok/;
        use DBIx::QuickORM(
            only => ['password'],
            rename => {pass => 'password'},
        );

        imported_ok(qw/password/);
    }

    my $bld = __PACKAGE__->builder;
    isa_ok($bld, ['DBIx::QuickORM'], "Got an instance");
    ref_is(builder(), $bld, "Can be called as a method or a function");

    ref_is(
        $bld->top,
        $bld->{stack}->[-1],
        "Cann access top build"
    );

    ok(!$bld->top->{building}, "Top level is not building anything");

    like(
        dies {
            alt foo => sub { 1 }
        },
        qr/alt\(\) cannot be used outside of a builder/,
        "Cannot use alt outside of a builder"
    );

    like(
        dies { plugin(bless({}, 'FooBar')) },
        qr/is not an instance of 'DBIx::QuickORM::Plugin' or a subclass of it/,
        "Must be a valid plugin"
    );

    like(
        dies { plugin(bless({}, 'DBIx::QuickORM::Plugin'), "foo") },
        qr/Cannot pass in both a blessed plugin instance and constructor arguments/,
        "Cannot combine blessed instance and construction args"
    );

    like(
        dies { plugin('+DBIx::QuickORM') },
        qr/DBIx::QuickORM is not a subclass of DBIx::QuickORM::Plugin/,
        "Not a valid plugin, but real class"
    );

    like(
        dies { plugin('DBIx::QuickORM::Plugin::This::Is::A::Fake::Plugin') },
        qr{Could not load plugin 'DBIx::QuickORM::Plugin::This::Is::A::Fake::Plugin': Can't locate DBIx/QuickORM/Plugin/This/Is/A/Fake/Plugin\.pm in \@INC},
        "Not a valid plugin, but real class"
    );

    ok(lives { plugin(bless({}, 'DBIx::QuickORM::Plugin')) }, "Valid plugin is OK");
    is(@{$bld->top->{plugins}}, 1, "1 plugin present");

    my $plugin = plugin('My::Plugin');
    isa_ok($plugin, ['DBIx::QuickORM::Plugin::My::Plugin', 'DBIx::QuickORM::Plugin'], "Can add plugin by class");
    is(@{$bld->top->{plugins}}, 2, "2 plugins present");

    $plugin = plugin('+DBIx::QuickORM::Plugin::My::Plugin');
    isa_ok($plugin, ['DBIx::QuickORM::Plugin::My::Plugin', 'DBIx::QuickORM::Plugin'], "Can add plugin by fully qualified class prefixed by +");
    is(@{$bld->top->{plugins}}, 3, "3 plugins present");

    is(plugins(), $bld->top->{plugins}, "Got all the plugins");

    $bld->top->{plugins} = [];

    plugins
        '+DBIx::QuickORM::Plugin' => {foo => 1},
        'My::Plugin'              => {bar => 1},
        'My::Plugin',
        '+DBIx::QuickORM::Plugin';

    is(
        plugins(),
        [
            bless({foo => 1}, 'DBIx::QuickORM::Plugin'),
            bless({bar => 1}, 'DBIx::QuickORM::Plugin::My::Plugin'),
            bless({},         'DBIx::QuickORM::Plugin::My::Plugin'),
            bless({},         'DBIx::QuickORM::Plugin'),
        ],
        "Can add a bunch of plugins with optional params"
    );

    $bld->top->{plugins} = [];

    like(
        dies { meta() },
        qr/Cannot access meta without a builder/,
        "Cannot use meta without a build",
    );

    like(
        dies { build_class('DBIx::QuickORM') },
        qr/Cannot set the build class without a builder/,
        "Cannot access without a builder"
    );

    like(
        dies { build_class() },
        qr/Not enough arguments/,
        "Must specify a class"
    );

    like(
        dies { build_class('') },
        qr/You must provide a class name/,
        "Must specify a class"
    );

    like(
        dies { build_class('Some::Fake::Class::That::Should::Not::Exist') },
        qr/Could not load class 'Some::Fake::Class::That::Should::Not::Exist': Can't locate Some/,
        "Must be a valid class"
    );

    my $db_inner;
    server somesql => sub {
        host 'foo';
        dialect 'PostgreSQL';

        $db_inner = db somedb => sub {
            user 'bob';
        };
    };

    my $db = db('somesql.somedb');
    ref_is($db, $db_inner, "Same blessed ref");
    isa_ok($db, ['DBIx::QuickORM::DB'], "Got a db instance");
    like(
        $db,
        {
            user => 'bob',      # From db { ... }
            host => 'foo',      # From server { ... }
            name => 'somedb',

            dialect => 'DBIx::QuickORM::Dialect::PostgreSQL',
        },
        "Got expected db fields"
    );

    db otherdb => sub {
        host 'boo';
        user 'boouser';
        pass 'boopass';
        dialect 'PostgreSQL';

        meta bah => 'humbug';
        is(meta()->{bah}, 'humbug', "Set the meta data directly");

        like(
            meta(),
            {
                host => 'boo',
                name => 'otherdb',
                user => 'boouser',
                pass => 'boopass',
                bah  => 'humbug',

                dialect => 'DBIx::QuickORM::Dialect::PostgreSQL',
            },
            "The fields were set"
        );
    };

    like(
        db('otherdb'),
        {
            compiled => T(),
            created  => T(),

            host => 'boo',
            name => 'otherdb',
            user => 'boouser',
            pass => 'boopass',
            bah  => 'humbug',
        },
        "Created a db without a server"
    );

    db fake => sub {
        dialect 'SQLite';
        build_class 'DBIx::QuickORM::DB::Fake';
    };
    isa_ok(db('fake'), ['DBIx::QuickORM::DB::Fake'], "Got the alternate build class");

    db full => sub {
        db_name "full_db";
        dialect 'PostgreSQL';
        driver 'Pg';

        connect sub { die "oops" };

        attributes {foo => 1};
        is(meta->{attributes}, {foo => 1}, "Can set attrs with a hashref");
        attributes foo => 2;
        is(meta->{attributes}, {foo => 2}, "Can set attrs with pairs");

        dsn "mydsn";
        host "myhost";
        port 1234;
        user "me";
        pass "hunter1";

        like(dies { connect 'foo' }, qr/connect must be given a coderef as its only argument, got 'foo' instead/, "Only coderef");
        like(dies { attributes [] }, qr/attributes\(\) accepts either a hashref, or \(key => value\) pairs/,      "Must be valid attributes");
    };

    isa_ok(db('full'), ['DBIx::QuickORM::DB'], "Got the db");
    like(
        db('full'),
        {
            name       => 'full',
            db_name    => 'full_db',
            connect    => T(),
            attributes => {foo => 2},
            dsn        => "mydsn",
            host       => "myhost",
            port       => 1234,
            user       => 'me',
            pass       => 'hunter1',
            dbi_driver => 'DBD::Pg',
            dialect    => 'DBIx::QuickORM::Dialect::PostgreSQL',

            created  => T(),
            compiled => T(),
        },
        "All builders worked"
    );

    schema variable => sub {
        table foo => sub {
            alt alt_a => sub {
                column a => {affinity => 'string'};
            };

            alt alt_b => sub {
                column a => {affinity => 'numeric'};
            };

            column x => sub {
                affinity 'boolean';
                alt alt_a => sub {
                    affinity 'string';
                };
                alt alt_b => sub {
                    affinity 'numeric';
                };
            };
        };

        alt alt_a => sub {
            table a1 => sub {
                column a => sub { affinity 'string' }
            };
        };

        alt alt_b => sub {
            table a2 => sub {
                column a => sub { affinity 'numeric' }
            };
        };
    };

    like(
        schema('variable'),
        {
            name     => 'variable',
            created  => T(),
            compiled => T(),
            tables   => {
                foo => {
                    created  => T(),
                    compiled => T(),
                    name     => 'foo',
                    columns  => {
                        x => {
                            order    => 1,
                            created  => T(),
                            compiled => T(),
                            name     => 'x',
                            affinity => 'boolean',
                        },
                    },
                },
            },
        },
        "Got a base variable schema",
    );

    like(
        schema('variable:alt_a'),
        {
            created  => T(),
            compiled => T(),
            name     => 'variable',
            tables   => {
                foo => {
                    created  => T(),
                    compiled => T(),
                    name     => 'foo',
                    columns  => {
                        a => {
                            created  => T(),
                            compiled => T(),
                            name     => 'a',
                            affinity => 'string',
                        },
                        x => {
                            created  => T(),
                            compiled => T(),
                            name     => 'x',
                            affinity => 'string',
                        },
                    },
                },
                a1 => {
                    created  => T(),
                    compiled => T(),
                    name     => 'a1',
                    columns  => {
                        a => {
                            created  => T(),
                            compiled => T(),
                            name     => 'a',
                            affinity => 'string',
                        },
                    },
                },
            },
        },
        "Got the alt_a variant of the variable schema",
    );

    like(
        schema('variable:alt_b'),
        {
            created  => T(),
            compiled => T(),

            name   => 'variable',
            tables => {
                foo => {
                    created  => T(),
                    compiled => T(),
                    name     => 'foo',
                    columns  => {
                        a => {
                            name     => 'a',
                            affinity => 'numeric',
                            created  => T(),
                            compiled => T(),
                        },
                        x => {
                            name     => 'x',
                            affinity => 'numeric',
                            created  => T(),
                            compiled => T(),
                        },
                    },
                },
                a2 => {
                    created  => T(),
                    compiled => T(),
                    name     => 'a2',
                    columns  => {
                        a => {
                            name     => 'a',
                            affinity => 'numeric',
                            created  => T(),
                            compiled => T(),
                        },
                    },
                },
            },
        },
        "Got the alt_b variant of the variable schema",
    );

    server variable => sub {
        pass "foo";
        dialect 'SQLite';

        alt mysql => sub {
            host 'mysql';
            port 1234;
            user 'my_user';
            dialect 'MySQL';
        };

        alt postgresql => sub {
            host 'postgresql';
            port 2345;
            user 'pg_user';
            dialect 'PostgreSQL';
        };

        db 'db_one';
        db 'db_two';
    };

    like(
        db('variable.db_one:mysql'),
        {
            host    => 'mysql',
            name    => 'db_one',
            pass    => 'foo',
            port    => 1234,
            user    => 'my_user',
            dialect => 'DBIx::QuickORM::Dialect::MySQL',

            created  => T(),
            compiled => T(),
        },
        "Got 'db_one' from server 'variable', 'mysql' variant",
    );

    like(
        db('variable.db_one:postgresql'),
        {
            host    => 'postgresql',
            name    => 'db_one',
            pass    => 'foo',
            port    => 2345,
            user    => 'pg_user',
            dialect => 'DBIx::QuickORM::Dialect::PostgreSQL',

            created  => T(),
            compiled => T(),
        },
        "Got 'db_one' from server 'variable', 'postgresql' variant",
    );

    like(
        db('variable.db_two:mysql'),
        {
            host    => 'mysql',
            name    => 'db_two',
            pass    => 'foo',
            port    => 1234,
            user    => 'my_user',
            dialect => 'DBIx::QuickORM::Dialect::MySQL',

            created  => T(),
            compiled => T(),
        },
        "Got 'db_two' from server 'variable', 'mysql' variant",
    );

    like(
        db('variable.db_two:postgresql'),
        {
            host    => 'postgresql',
            name    => 'db_two',
            pass    => 'foo',
            port    => 2345,
            user    => 'pg_user',
            dialect => 'DBIx::QuickORM::Dialect::PostgreSQL',

            created  => T(),
            compiled => T(),
        },
        "Got 'db_two' from server 'variable', 'postgresql' variant",
    );

    db 'from_creds' => sub {
        dialect 'PostgreSQL';
        creds sub {
            return {
                user   => 'username',
                pass   => 'password',
                socket => 'socketname',
            };
        };
    };

    like(
        db('from_creds'),
        {
            name    => 'from_creds',
            user    => 'username',
            pass    => 'password',
            socket  => 'socketname',
            dialect => 'DBIx::QuickORM::Dialect::PostgreSQL',

            created  => T(),
            compiled => T(),
        },
        "Got credentials from subroutine",
    );

    schema deeptest => sub {
        row_class "ClassA";
        table foo => sub {
            row_class "ClassB";
            db_name 'foo1';
            column a => 'MyType';
            column b => \'VARCHAR(123)', 'string';
            column c => sub {
                type \'VARCHAR';
                affinity 'string';
                omit;
                nullable;
                sql prefix => 'prefix 1';
                sql prefix => 'prefix 2';
                sql "c varchar";
                sql postfix => "default 'x'";
                sql postfix => "postfix 2";

                link get_bar => [bar => ['xyz']];
            };
            columns qw/x y z/ => {type => \'int', affinity => 'numeric'};

            primary_key(qw/a b/);
            unique(qw/x y z/);
            index myidx1 => [qw/a x/];
            index myidx2 => [qw/b y/], {type => 'foo', unique => 0};
            index [qw/a b x y/];
        };

        table 'bar' => sub {
            column xyz => 'MyType';
        };

        link(
            {table => 'foo', columns => ['x'],   alias => 'bar1'},
            {table => 'bar', columns => ['xyz'], alias => 'foo1'},
        );

        link foo2 => [bar => [qw/x/]],
            bar2  => [foo => [qw/x/]];

        link foo3 => [bar => [qw/x/]], foo => [qw/x/];

        link(
            foo => [qw/x/],
            bar => [qw/x/],
        );
    };

    like(
        schema('deeptest'),
        {
            name      => 'deeptest',
            row_class => 'DBIx::QuickORM::Row::ClassA',
            links     => DNE(),
            tables    => {
                bar => {
                    name      => 'bar',
                    row_class => 'DBIx::QuickORM::Row::ClassA',
                    columns   => {
                        xyz => {
                            name => 'xyz',
                            type => 'DBIx::QuickORM::Type::MyType',
                        },
                    },
                    links => [
                        {
                            local_table   => 'bar',
                            other_table   => 'foo',
                            key           => 'xyz',
                            aliases       => ['foo1'],
                            local_columns => ['xyz'],
                            other_columns => ['x'],
                            unique        => F(),
                            created       => T(),
                        },
                        {
                            local_table   => 'bar',
                            other_table   => 'foo',
                            key           => 'x',
                            aliases       => ['foo2'],
                            local_columns => ['x'],
                            other_columns => ['x'],
                            unique        => F(),
                            created       => T(),
                        },
                        {
                            local_table   => 'bar',
                            other_table   => 'foo',
                            key           => 'x',
                            aliases       => ['foo3'],
                            local_columns => ['x'],
                            other_columns => ['x'],
                            unique        => F(),
                            created       => T(),
                        },
                    ],
                },
                foo => {
                    name        => 'foo',
                    db_name     => 'foo1',
                    row_class   => 'DBIx::QuickORM::Row::ClassB',
                    primary_key => ['a', 'b'],
                    unique      => {'x, y, z' => ['x', 'y', 'z']},
                    columns     => {
                        a => {
                            name => 'a',
                            type => 'DBIx::QuickORM::Type::MyType',
                        },
                        b => {
                            affinity => 'string',
                            name     => 'b',
                            type     => \'VARCHAR(123)'
                        },
                        c => {
                            affinity => 'string',
                            name     => 'c',
                            nullable => 1,
                            omit     => 1,
                            sql      => {
                                infix   => 'c varchar',
                                postfix => ['default \'x\'', 'postfix 2'],
                                prefix  => ['prefix 1',      'prefix 2'],
                            },
                            type => \'VARCHAR',
                        },
                        x => {
                            affinity => 'numeric',
                            name     => 'x',
                            type     => \'int',
                        },
                        y => {
                            affinity => 'numeric',
                            name     => 'y',
                            type     => \'int',
                        },
                        z => {
                            affinity => 'numeric',
                            name     => 'z',
                            type     => \'int',
                        },
                    },
                    indexes => [
                        {columns => ['x', 'y', 'z',], unique => 1},
                        {columns => ['a', 'x',], name => 'myidx1'},
                        {columns => ['b', 'y',], name => 'myidx2', type => 'foo', unique => 0},
                        {columns => ['a', 'b', 'x', 'y',], name => undef},
                    ],
                    links => [
                        {
                            local_table   => 'foo',
                            other_table   => 'bar',
                            key           => 'x',
                            aliases       => ['bar1'],
                            local_columns => ['x'],
                            other_columns => ['xyz'],
                            unique        => F(),
                            created       => T(),
                        },
                        {
                            local_table   => 'foo',
                            other_table   => 'bar',
                            key           => 'x',
                            aliases       => ['bar2'],
                            local_columns => ['x'],
                            other_columns => ['x'],
                            unique        => F(),
                            created       => T(),
                        },
                        {
                          local_table => 'foo',
                          other_table => 'bar',
                          key => 'x',
                          aliases => [],
                          local_columns => [ 'x' ],
                          other_columns => [ 'x' ],
                          unique => F(),
                          created => T(),
                        },
                        {
                          local_table => 'foo',
                          other_table => 'bar',
                          key => 'x',
                          aliases => [],
                          local_columns => [ 'x' ],
                          other_columns => [ 'x' ],
                          unique => F(),
                          created => T(),
                        },
                        {
                            local_table   => 'foo',
                            other_table   => 'bar',
                            key           => 'c',
                            aliases       => ['get_bar'],
                            local_columns => ['c'],
                            other_columns => ['xyz'],
                            unique        => F(),
                            created       => T(),
                        },
                    ],
                },
            }
        },
        "Got expected schema structure",
    );

    {

        package Test::ORM::Table::ABC;
        $INC{'Test/ORM/Table/ABC.pm'} = __FILE__;

        use DBIx::QuickORM type => 'table';

        table abc => sub {
            column abc => sub {
                affinity 'string';
            };
        };

        package Test::ORM::Table::XYZ;
        $INC{'Test/ORM/Table/XYZ.pm'} = __FILE__;

        use DBIx::QuickORM type => 'table';
        use Test2::V0 qw/is isa_ok ref_is_not like/;

        table xyz => sub {
            column xyz => sub {
                affinity 'string';
            };
        };

        isa_ok(__PACKAGE__, ['DBIx::QuickORM::Row'], "This package is now a row");

        ref_is_not(__PACKAGE__->qorm_table, __PACKAGE__->qorm_table, "Deep clone");

        like(
            __PACKAGE__->qorm_table,
            {
                name      => 'xyz',
                class     => 'DBIx::QuickORM::Schema::Table',
                row_class => 'Test::ORM::Table::XYZ',

                meta => {
                    name    => 'xyz',
                    columns => {
                        xyz => {
                            meta => {
                                name     => 'xyz',
                                affinity => 'string'
                            },
                            name  => 'xyz',
                            class => 'DBIx::QuickORM::Schema::Table::Column'
                        }
                    },
                },
            },
            "Got correct structure from table",
        );
    }

    schema xyz_a => sub {
        table 'Test::ORM::Table::XYZ';

        table clone_xyz_a => 'Test::ORM::Table::XYZ';

        table clone_xyz_b => 'Test::ORM::Table::XYZ', sub {
            column zzz => sub { affinity 'string' };
        };
    };

    like(
        schema('xyz_a')->{tables},
        {
            xyz => {
                name      => 'xyz',
                row_class => 'Test::ORM::Table::XYZ',
                compiled  => T(),
                created   => T(),
                columns   => {
                    xyz => {
                        name     => 'xyz',
                        affinity => 'string',
                        compiled => T(),
                        created  => T(),
                    },
                },
            },
            clone_xyz_a => {
                name      => 'xyz',
                row_class => 'Test::ORM::Table::XYZ',
                compiled  => T(),
                created   => T(),
                columns   => {
                    xyz => {
                        name     => 'xyz',
                        affinity => 'string',
                        compiled => T(),
                        created  => T(),
                    },
                }
            },
            clone_xyz_b => {
                name      => 'xyz',
                row_class => 'Test::ORM::Table::XYZ',
                compiled  => T(),
                created   => T(),
                columns   => {
                    zzz => {
                        name     => 'zzz',
                        affinity => 'string',
                        compiled => T(),
                        created  => T(),
                    },
                    xyz => {
                        name     => 'xyz',
                        affinity => 'string',
                        compiled => T(),
                        created  => T(),
                    },
                },
            },
        },
        "Got the table data from the table class"
    );

    schema table_mods => sub {
        tables 'Test::ORM::Table' => sub {
            my $table = shift;
            return if $table->{name} eq 'abc';
            $table->{meta}->{foo} = 'added';
            return ($table->{name} . "2", $table);
        };

        # This comes second to make sure the change to $table above does not bleed.
        tables 'Test::ORM::Table';
    };

    like(
        schema('table_mods')->{tables},
        {
            abc => {
                name      => 'abc',
                row_class => 'Test::ORM::Table::ABC',
                columns   => {
                    abc => {
                        name     => 'abc',
                        affinity => 'string',
                    },
                },
            },
            xyz => {
                foo       => DNE,                       # Make sure it did not bleed in
                name      => 'xyz',
                row_class => 'Test::ORM::Table::XYZ',
                columns   => {
                    xyz => {
                        name     => 'xyz',
                        affinity => 'string',
                    },
                },
            },
            xyz2 => {
                foo       => 'added',
                name      => 'xyz',
                row_class => 'Test::ORM::Table::XYZ',
                columns   => {
                    xyz => {
                        name     => 'xyz',
                        affinity => 'string',
                    },
                },
            },
        },
        "Found both tables under the specified parent namespace, also added just xyz as xyz2 with modification"
    );

    schema test_column => sub {
        table test_column => sub {
            column a => (qw/MyType identity nullable omit numeric/);
            column b => (\'VARCHAR(20)', identity, nullable, omit, affinity('numeric'));
            column c => (bless({x => 1}, 'DBIx::QuickORM::Type::MyType'), identity, nullable, omit, affinity('numeric'));
            column d => ('DBIx::QuickORM::Type::MyType',  identity(0), nullable(0), omit(0), affinity('numeric'));
            column e => ('+DBIx::QuickORM::Type::MyType', identity, not_null, omit, affinity('numeric'));
            column f => (type('DBIx::QuickORM::Type::MyType'), identity, nullable, omit, affinity('numeric'));
            column g => sub {
                type 'MyType';
                identity;
                nullable;
                omit;
                affinity('numeric');
            };

            columns qw/h i j/ => {
                type     => \'VARCHAR(20)',
                nullable => 1,
                omit     => 0,
            };

            like(
                dies { column x => bless({}, 'Fake::Thing') },
                qr/'Fake::Thing.*' does not implement 'DBIx::QuickORM::Role::Type'/,
                "Must be a subclass of 'DBIx::QuickORM::Type'"
            );

            like(
                dies { column x => [] },
                qr/Not sure what to do with column argument /,
                "Arrayref is not valid"
            );

            like(
                dies { column x => 'invalid' },
                qr/Column arg 'invalid' does not appear to be pure-sql \(scalar ref\), affinity, or an object implementing DBIx::QuickORM::Role::Type/,
                "Not a valid class"
            );

            like(
                dies { column x => '+Test2::API' },
                qr/Class 'Test2::API' does not implement DBIx::QuickORM::Role::Type/,
                "Not a type class"
            );

            like(
                dies {
                    local @INC = (sub { die "Exception!" });
                    column x => '+Fake::Class'
                },
                qr/Error loading class for type '\+Fake::Class': Exception!/,
                "Errors encountered when loading a class are passed on"
            );

            like(
                dies { columns x => {}, {} },
                qr/Cannot provide multiple hashrefs/,
                "Cannot have multiple hashes"
            );

            like(
                dies {
                    columns x => sub { }
                },
                qr/Not sure what to do with/,
                "Cannot use a sub"
            );
        };
    };

    like(
        schema('test_column')->{tables}->{test_column}->{columns},
        {
            a => {
                name     => 'a',
                omit     => 1,
                nullable => 1,
                identity => 1,
                nullable => 1,
                affinity => 'numeric',
                type     => 'DBIx::QuickORM::Type::MyType',
            },
            b => {
                name     => 'b',
                omit     => 1,
                identity => 1,
                nullable => 1,
                affinity => 'numeric',
                type     => \'VARCHAR(20)',
            },
            c => {
                name     => 'c',
                omit     => 1,
                identity => 1,
                nullable => 1,
                affinity => 'numeric',
                type     => {x => 1},
            },
            d => {
                name     => 'd',
                omit     => FDNE,
                identity => FDNE,
                nullable => FDNE,
                affinity => 'numeric',
                type     => 'DBIx::QuickORM::Type::MyType',
            },
            e => {
                name     => 'e',
                omit     => 1,
                identity => 1,
                nullable => FDNE,
                affinity => 'numeric',
                type     => 'DBIx::QuickORM::Type::MyType',
            },
            f => {
                name     => 'f',
                omit     => 1,
                identity => 1,
                nullable => 1,
                affinity => 'numeric',
                type     => 'DBIx::QuickORM::Type::MyType',
            },
            g => {
                name     => 'g',
                omit     => 1,
                identity => 1,
                nullable => 1,
                affinity => 'numeric',
                type     => 'DBIx::QuickORM::Type::MyType',
            },
            h => {
                name     => 'h',
                omit     => 0,
                nullable => 1,
                type     => \'VARCHAR(20)',
            },
            i => {
                name     => 'i',
                omit     => 0,
                nullable => 1,
                type     => \'VARCHAR(20)',
            },
            j => {
                name     => 'j',
                omit     => 0,
                nullable => 1,
                type     => \'VARCHAR(20)',
            },
        },
        "Got expected columns",
    );

    schema sql_test => sub {
        sql prefix  => "schema sql prefix 1";
        sql postfix => "schema sql postfix 1";
        sql prefix  => "schema sql prefix 2";
        sql postfix => "schema sql postfix 2";

        like(
            dies { sql infix => 'NO!' },
            qr/'infix' sql is not supported in SCHEMA, use prefix or postfix/,
            "No infix for schema"
        );

        table sql_test => sub {
            sql prefix  => "table sql prefix 1";
            sql postfix => "table sql postfix 1";
            sql infix   => "table sql infix";
            sql prefix  => "table sql prefix 2";
            sql postfix => "table sql postfix 2";

            like(
                dies { sql infix => 'NO!' },
                qr/'infix' sql has already been set for/,
                "Can only have 1 infix"
            );

            column blank_infix => sub {
                sql infix => "";
            };

            column sql_test => sub {
                sql prefix  => "column sql prefix 1";
                sql postfix => "column sql postfix 1";
                sql infix   => "column sql infix";
                sql prefix  => "column sql prefix 2";
                sql postfix => "column sql postfix 2";

                like(
                    dies { sql infix => 'NO!' },
                    qr/'infix' sql has already been set for/,
                    "Can only have 1 infix"
                );
            };
        };
    };

    like(
        schema('sql_test'),
        {
            name => 'sql_test',
            sql  => {
                postfix => ['schema sql postfix 1', 'schema sql postfix 2'],
                prefix  => ['schema sql prefix 1',  'schema sql prefix 2'],
            },
            tables => {
                sql_test => {
                    columns => {
                        sql_test => {
                            name => 'sql_test',
                            sql  => {
                                infix   => 'column sql infix',
                                postfix => ['column sql postfix 1', 'column sql postfix 2'],
                                prefix  => ['column sql prefix 1',  'column sql prefix 2'],
                            }
                        },
                        blank_infix => {
                            name => 'blank_infix',
                            sql  => {
                                infix => '',    # Make sure it never gets wiped out
                            },
                        },
                    },
                    name => 'sql_test',
                    sql  => {
                        infix   => 'table sql infix',
                        postfix => ['table sql postfix 1', 'table sql postfix 2'],
                        prefix  => ['table sql prefix 1',  'table sql prefix 2'],
                    },
                },
            },
        },
        "Can set SQL",
    );

    is(affinity('string'), 'string', "In non-void context it returns the value");
    like(
        dies { affinity("string"); return },
        qr/DBIx::QuickORM::affinity\(\) can only be used inside one of the following builders: column/,
        "Error if not in builder and in void context"
    );
    like(
        dies { affinity('nope'); return },
        qr/'nope' is not a valid affinity/,
        "Must be a valid affinity"
    );
    is(affinity($_), $_, "$_ is a valid affinity") for qw/string numeric binary boolean/;

    is([omit(0)],     [],           "No omit, scalar context");
    is([omit(1)],     ['omit'],     "Omit, scalar context");
    is([identity(0)], [],           "No identity, scalar context");
    is([identity(1)], ['identity'], "Identity, scalar context");
    is([nullable(0)], ['not_null'], "Not nullable, scalar context");
    is([nullable(1)], ['nullable'], "Nullable, scalar context");
    is([not_null(0)], ['nullable'], "No not_null, scalar context");
    is([not_null(1)], ['not_null'], "not_null, scalar context");

    like(
        dies { $_->(); return },
        qr/can only be used inside one of the following builders: column/,
        "Cannot use outside of a builder in void context"
    ) for \&omit, \&identity, \&nullable, \&not_null;

    schema ctest => sub {
        table ctest => sub {
            column ctesta => sub {
                omit(0);
                identity(0);
                nullable(0);
            };
            column ctestb => sub {
                omit(1);
                identity(1);
                nullable(1);
            };
            column ctestc => sub {
                not_null(0);
            };
            column ctestd => sub {
                not_null(1);
            };
        };
    };

    like(
        schema('ctest')->{tables}->{ctest}->{columns},
        {
            'ctesta' => {
                'name'     => 'ctesta',
                'identity' => 0,
                'nullable' => 0,
                'omit'     => 0,
            },
            'ctestb' => {
                'name'     => 'ctestb',
                'identity' => 1,
                'nullable' => 1,
                'omit'     => 1,
            },
            'ctestc' => {
                'name'     => 'ctestc',
                'nullable' => 1,
            },
            'ctestd' => {
                'name'     => 'ctestd',
                'nullable' => 0,
            },
        },
        "Got expected settings"
    );

    like(dies { type() }, qr/Not enough arguments/, "Need args");
    like(
        dies { type('Fake::Thing') },
        qr/Type must be a scalar reference, or a class that implements 'DBIx::QuickORM::Role::Type', got: Fake::Thing/,
        "Must be a valid type"
    );

    like(
        dies { type(\'foo', 'arg') },
        qr/Too many arguments/,
        "Too many args",
    );

    ok(type('DBIx::QuickORM::Type::MyType'), 'DBIx::QuickORM::Type::MyType', "Returns class in scalar context");

    schema typetest => sub {
        table typetest => sub {
            column ref  => sub { type \'varchar' };
            column type => sub { type 'DBIx::QuickORM::Type::MyType' };
        };
    };

    like(
        schema('typetest')->{tables}->{typetest}->{columns},
        {
            ref  => {type => \'varchar'},
            type => {type => 'DBIx::QuickORM::Type::MyType'},
        },
        "Got correct types"
    );

    db name_test => sub { db_name 'foo'; dialect 'SQLite' };
    is(db('name_test')->{db_name}, 'foo', "DB Name different from qorm name");

    schema name_test => sub {
        table lookup_name => sub {
            db_name 'db_alt_name';
            column lookup_name => sub {
            };
        };
    };

    is(schema('name_test')->{tables}->{lookup_name}->{name},                           'lookup_name', "Name correct");
    is(schema('name_test')->{tables}->{lookup_name}->{db_name},                        'db_alt_name', "DB Name different from qorm name");
    is(schema('name_test')->{tables}->{lookup_name}->{columns}->{lookup_name}->{name}, 'lookup_name', "Name correct");

    schema test_row_class => sub {
        row_class 'DBIx::QuickORM::Row::ClassA';
        table test_row_class => sub {
            row_class 'DBIx::QuickORM::Row::ClassB';
        };
        table test_row_class2 => sub { };

        like(
            dies { row_class 'A Fake Class' },
            qr/Could not load class 'A Fake Class': Can't locate/,
            "Must be a valid row class"
        );
    };

    is(schema('test_row_class')->{row_class},                              'DBIx::QuickORM::Row::ClassA', "Set row class for schema");
    is(schema('test_row_class')->{tables}->{test_row_class}->{row_class},  'DBIx::QuickORM::Row::ClassB', "Set row class for table");
    is(schema('test_row_class')->{tables}->{test_row_class2}->{row_class}, 'DBIx::QuickORM::Row::ClassA', "Table inherited from schema");

    orm orm_test_a => sub {
        db orm_test_db => sub {
            dialect 'SQLite';
        };

        autofill;
        handle_class 'DBIx::QuickORM::Handle';

        schema orm_test_schema => sub {
        };
    };

    like(
        orm('orm_test_a'),
        {
            name     => 'orm_test_a',
            compiled => T(),
            created  => T(),
            autofill => T(),
            db       => {
                name     => 'orm_test_db',
                compiled => T(),
                created  => T(),
            },
            schema => {
                name     => 'orm_test_schema',
                compiled => T(),
                created  => T(),
            },
            default_handle_class => 'DBIx::QuickORM::Handle',
        },
        "Got the orm with schema and db",
    );

    orm orm_test_b => sub {
        db 'variable.db_one';
        schema 'xyz_a';

        handle_class 'DBIx::QuickORM::Handle::TestHandle';

        like(
            $bld->{stack}->[-1],
            {
                name     => 'orm_test_b',
                building => 'ORM',
                meta     => {
                    name => 'orm_test_b',
                    db   => {
                        name     => 'db_one',
                        building => 'DB',
                        server   => 'variable',
                    },
                    schema => {
                        name     => 'xyz_a',
                        building => 'SCHEMA',
                    },
                    default_handle_class => 'DBIx::QuickORM::Handle::TestHandle',
                },
            },
            "Added db and schema to the orm, not compiled"
        );
    };

    like(
        orm('orm_test_b'),
        {
            name => 'orm_test_b',
            db   => {
                name => 'db_one',
                pass => 'foo',
            },
            schema => {
                name   => 'xyz_a',
                tables => {
                    clone_xyz_a => T(),
                    clone_xyz_b => T(),
                    xyz         => T(),
                }
            },
            default_handle_class => 'DBIx::QuickORM::Handle::TestHandle',
        },
        "Got vanilla db in orm"
    );

    like(
        orm('orm_test_b:mysql'),
        {
            name => 'orm_test_b',
            db   => {
                host => 'mysql',
                name => 'db_one',
                pass => 'foo',
                port => 1234,
                user => 'my_user',
            },
            schema => {
                name   => 'xyz_a',
                tables => {
                    clone_xyz_a => T(),
                    clone_xyz_b => T(),
                    xyz         => T(),
                },
            },
        },
        "Got mysql variant"
    );

    like(
        orm('orm_test_b:postgresql'),
        {
            name => 'orm_test_b',
            db   => {
                host => 'postgresql',
                name => 'db_one',
                pass => 'foo',
                port => 2345,
                user => 'pg_user',
            },
            schema => {
                name   => 'xyz_a',
                tables => {
                    clone_xyz_a => T(),
                    clone_xyz_b => T(),
                    xyz         => T(),
                }
            },
        },
        "Got postgresql variant"
    );

    schema test_pk_and_unique => sub {
        table foo => sub {
            column foo => sub {
                primary_key;
                unique;

                like(dies { primary_key('xxx') }, qr/Too many arguments/, "No args when used in column");
                like(dies { unique('xxx') },      qr/Too many arguments/, "No args when used in column");
            };

            like(
                $bld->{stack}->[-1]->{meta},
                {
                    primary_key => ['foo'],
                    unique      => {foo => ['foo']},
                },
                "Added pk and unique"
            );

            like(dies { primary_key() }, qr/Not enough arguments/, "Need to specify args");
            like(dies { unique() },      qr/Not enough arguments/, "Need to specify args");
        };
    };

    my $def = sub { 1 };
    schema test_default => sub {
        table foo => sub {
            column x => sub {
                default \'NOW()';
                default $def;
            };

            column y => default(\'NOW()'), default($def);

            like(
                $bld->{stack}->[-1]->{meta}->{columns}->{x}->{meta},
                {
                    sql_default  => 'NOW()',
                    perl_default => $def,
                },
                "Set both default types"
            );

            like(
                $bld->{stack}->[-1]->{meta}->{columns}->{y}->{meta},
                {
                    sql_default  => 'NOW()',
                    perl_default => $def,
                },
                "Set both default types"
            );

        };
    };

    like(
        {default(\'NOW()'), default($def)},
        {sql_default => 'NOW()', perl_default => $def},
        "non-void context"
    );
}

{

    package Test::Consumer;
    use Test2::V0;

    Test::ORM->import;
    imported_ok('qorm');

    Test::ORM->import('other_qorm');
    imported_ok('other_qorm');

    ref_is(qorm(), Test::ORM->builder, "shortcut to the 'DBIx::QuickORM' instance");

    isa_ok(qorm(orm => 'orm_test_b:postgresql'), ['DBIx::QuickORM::ORM'], "Got the orm by name");

    ref_is(qorm(orm => 'orm_test_b:postgresql'), qorm(orm => 'orm_test_b:postgresql'), "Cached the reference");

    isa_ok(qorm(db => 'somesql.somedb'),             ['DBIx::QuickORM::DB'], "Got the db by name");
    isa_ok(qorm(db => 'variable.db_one:postgresql'), ['DBIx::QuickORM::DB'], "Got the db by name and variation");

    like(dies { qorm(1 .. 10) },         qr/Too many arguments/,                                             "Too many args");
    like(dies { qorm('fake') },          qr/'fake' is not a defined ORM/,                                    "Need to provide a valid orm name");
    like(dies { qorm('fake' => 'foo') }, qr/'fake' is not a valid item type to fetch from 'Test::Consumer'/, "We do not define any 'fake's here");

    no warnings 'once';
    local *DBIx::QuickORM::ORM::connection = sub { 'connected!' };
    is(qorm('orm_test_b:postgresql'), 'connected!', "qorm(name) gets the connection");
}

done_testing;
