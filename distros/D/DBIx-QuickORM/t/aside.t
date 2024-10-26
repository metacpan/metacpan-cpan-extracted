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

        schema sub {
            table person => sub {
                column person_id => sub {
                    primary_key;
                    serial('BIG');
                };

                column name => sub {
                    unique;
                    sql_spec(type => 'VARCHAR(128)');
                };
            };
        };
    };

    skip_all "$dbname does not support async" unless $orm->connection->supports_async;

    ok(lives { $orm->generate_and_load_schema() }, "Generate and load schema");

    is([$orm->connection->tables], ['person'], "Table person was added");

    my $s = $orm->source('person');
    my $bob = $s->insert(name => 'bob');
    my $ted = $s->insert(name => 'ted');
    my $ann = $s->insert(name => 'ann');

    my $as = $orm->source('person')->aside({}, 'name')->start;

    ok(!$as->{rows}, "No rows yet");
    ok($as->started, "Query has been started");

    ok(!$s->busy, "First source is not currently busy");
    ok($as->busy, "Select is currently busy");

    ok($s->first, "Now we still do other queries on the initial source");

    sleep(1) while !$as->ready;

    ok($as->ready, "We are ready!");

    is(
        [$as->all],
        [$ann, $bob, $ted],
        "Got all 3 rows"
    );

    is(
        $as->first->real_source,
        exact_ref($ann->real_source),
        "Correct source in the end"
    );
};

done_testing;
