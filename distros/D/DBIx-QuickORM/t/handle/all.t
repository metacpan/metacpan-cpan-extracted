use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;
use Carp::Always;

use lib 't/lib';
use DBIx::QuickORM::Test;

sub SCHEMA_DIR { 't/handle/schema' }

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm my_orm => sub {
        db 'mydb';
        autofill;
    };

    ok(my $orm = orm('my_orm')->connect, "Got a connection");
    my $h = $orm->handle('example');
    ok($h->insert({name => 'a'}), "Inserted a row");
    ok($h->insert({name => 'b'}), "Inserted a row");
    ok($h->insert({name => 'c'}), "Inserted a row");
    ok($h->insert({name => 'd'}), "Inserted a row");
    ok($h->insert({name => 'e'}), "Inserted a row");

    is($h->all, 5, "Got all 5 rows");

    like(
        [map { $_->stored_data } $h->all],
        [
            {id => 1, name => 'a'},
            {id => 2, name => 'b'},
            {id => 3, name => 'c'},
            {id => 4, name => 'd'},
            {id => 5, name => 'e'},
        ],
        "5 rows meet expectation"
    );

    like(
        [$h->data_only->all],
        [
            {id => 1, name => 'a'},
            {id => 2, name => 'b'},
            {id => 3, name => 'c'},
            {id => 4, name => 'd'},
            {id => 5, name => 'e'},
        ],
        "5 rows (data-only) meet expectation"
    );

    # sqlite does not support async
    unless (curdialect() =~ m/sqlite/i) {
        subtest async => sub {
            like(
                dies { $h->async->all },
                qr/all\(\) cannot be used asynchronously, use iterate\(\) to get an async iterator instead/,
                "all() cannot be used with async"
            );
        };

        subtest aside => sub {
            like(
                dies { $h->aside->all },
                qr/all\(\) cannot be used asynchronously, use iterate\(\) to get an async iterator instead/,
                "all() cannot be used with aside"
            );
        };

        subtest forked => sub {
            like(
                dies { $h->forked->all },
                qr/all\(\) cannot be used asynchronously, use iterate\(\) to get an async iterator instead/,
                "all() cannot be used with forked"
            );
        };
    }
};

done_testing;

