use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# Correctness fixes for the DSL:
#  I3: quick() rejects unknown credentials keys instead of silently ignoring them.
#  B13: columns(@names, sub {...}) applies the builder to each named column.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

subtest quick_rejects_unknown_credentials => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:SQLite:dbname=$dir/x.sqlite";
    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY)');
        $dbh->disconnect;
    }

    like(
        dies { DBIx::QuickORM->quick(credentials => {dsn => $dsn, passsword => 'typo'}) },
        qr/Unknown credentials key\(s\): passsword/,
        "a misspelled credentials key croaks instead of connecting wrong",
    );

    ok(lives { DBIx::QuickORM->quick(credentials => {dsn => $dsn}) }, "valid credentials still connect");
};

subtest columns_with_trailing_builder => sub {
    {
        package My::Test::DSL::B13;
        use DBIx::QuickORM;

        schema b13 => sub {
            table t => sub {
                column id => sub { affinity 'numeric'; primary_key };
                columns(qw/a b/, sub { affinity 'string' });
            };
        };
    }

    my $cols = My::Test::DSL::B13->can('schema')->('b13')->{tables}->{t}->{columns};
    is($cols->{a}->{affinity}, 'string', "columns() applied the builder to column a");
    is($cols->{b}->{affinity}, 'string', "columns() applied the builder to column b");
};

subtest schema_link_requires_two_nodes => sub {
    like(
        dies {
            package My::Test::DSL::B10;
            use DBIx::QuickORM;
            schema b10 => sub {
                table a => sub { column id  => sub { primary_key; affinity 'numeric' } };
                table b => sub { column bid => sub { primary_key; affinity 'numeric' } };
                link {table => 'a', columns => ['id']};    # only one node
            };
        },
        qr/exactly two nodes/,
        "a schema-context link with only one node croaks instead of an undef-deref",
    );
};

subtest primary_key_redefine_croaks => sub {
    like(
        dies {
            package My::Test::DSL::I1;
            use DBIx::QuickORM;
            schema i1 => sub {
                table t => sub {
                    column a => sub { affinity 'numeric'; primary_key };
                    column b => sub { affinity 'numeric'; primary_key };    # second key
                };
            };
        },
        qr/primary_key is already defined/,
        "declaring primary_key twice croaks instead of silently last-wins",
    );

    ok(
        lives {
            package My::Test::DSL::I1b;
            use DBIx::QuickORM;
            schema i1b => sub {
                table t => sub {
                    column a => sub { affinity 'numeric'; primary_key };
                    column b => sub { affinity 'numeric'; primary_key({override => 1}) };
                };
            };
        },
        "primary_key({override => 1}) intentionally replaces the previous key",
    );
};

subtest view_vs_table_class_kind_mismatch => sub {
    {
        package My::Test::DSL::I5::Tbl;
        $INC{'My/Test/DSL/I5/Tbl.pm'} = __FILE__;
        use DBIx::QuickORM type => 'table';
        table i5tbl => sub {
            column id => sub { affinity 'numeric'; primary_key };
        };
    }

    like(
        dies {
            package My::Test::DSL::I5::S;
            use DBIx::QuickORM;
            schema i5s => sub {
                view 'My::Test::DSL::I5::Tbl';    # it defines a Table, not a View
            };
        },
        qr/defines a \S+::Table, not a \S+::View/,
        "referencing a table class through view() croaks on the kind mismatch",
    );

    ok(
        lives {
            package My::Test::DSL::I5::S2;
            use DBIx::QuickORM;
            schema i5s2 => sub {
                table 'My::Test::DSL::I5::Tbl';    # correct kind
            };
        },
        "referencing the same class through table() still works",
    );
};

done_testing;
