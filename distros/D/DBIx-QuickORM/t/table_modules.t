use Test2::V0;
use lib 't/lib';
use DBIx::QuickORM::Tester qw/dbs_do all_dbs/;
use DBIx::QuickORM;

dbs_do db => sub {
    my ($dbname, $dbc, $st) = @_;

    my $orm = orm sub {
        db sub {
            db_class $dbname;
            db_name 'quickdb';
            db_connect sub { $dbc->connect };
        };

        schema sub { tables 'DBIx::QuickORM::Test::Tables' };
    };

    ok(lives { $orm->generate_and_load_schema() }, "Generate and load schema");

    is([sort $orm->connection->tables], bag { item 'aaa'; item 'bbb'; etc }, "Tables aaa and bbb were added");

    for my $set ([aaa => 'DBIx::QuickORM::Test::Tables::TestA'], [bbb => 'DBIx::QuickORM::Test::Tables::TestB']) {
        my ($tname, $class) = @$set;

        my $table = $orm->schema->table($tname);
        like($table,            $class->orm_table, "Got table data");
        is($table->row_class, $class,            "row class is set");

        my $row = $orm->source($tname)->insert(foo => 123);
        isa_ok(
            $row,
            [$class, $tname eq 'aaa' ? ('DBIx::QuickORM::Row::AutoAccessors') : (), 'DBIx::QuickORM::Row'],
            "Rows have all the right inheritence"
        );

        is($row->id, $row->column("${tname}_id"), "Added our own method to the row class");
        is($row->id, 1,                           "Got correct value");

        isa_ok($row, ['DBIx::QuickORM::Row', $class], "Got properly classed row");

        ok(
            lives { is($row->foo, 123, "Accessor 'foo' works") },
            "Accessor foo did not throw an exception"
        ) or return;

        $row->foo(18);
        is($row->foo, 18, "Set the value for 'foo'");
        is($row->stored_foo, 123, "Did not update storage yet");
        $row->save;
        is($row->foo, 18, "Still correct");
        is($row->stored_foo, 18, "New value is in storage");
        my $ref = "$row";

        $row = undef;
        $orm->source($tname)->cache->clear();

        $row = $orm->source($tname)->find(1);
        isnt($row, $ref, "New reference");
        is($row->foo, 18, "Still correct");
        is($row->stored_foo, 18, "New value is in storage");
    }
};

done_testing;
