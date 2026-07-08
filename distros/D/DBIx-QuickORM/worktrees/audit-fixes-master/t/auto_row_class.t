use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;
use DBIx::QuickORM::Row;

use lib 't/lib';
use DBIx::QuickORM::Test;

sub SCHEMA_DIR { 't/handle/schema' }

BEGIN {
    package My::AutoRowClass;
    use parent 'DBIx::QuickORM::Row';
    $INC{'My/AutoRowClass.pm'} = __FILE__;
}

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
        schema my_schema => sub {
            row_class '+My::AutoRowClass';
        };
    };

    ok(my $orm = orm('my_orm')->connect, "Got a connection");

    ok(my $row = $orm->handle('example')->insert({name => 'a'}), "Inserted a row");
    isa_ok($row, ['DBIx::QuickORM::Row', 'My::AutoRowClass'], "schema-level row_class applies to the autofilled table");

    $row = undef;
    ok(my $fetched = $orm->handle('example')->one({name => 'a'}), "Fetched the row back");
    isa_ok($fetched, ['My::AutoRowClass'], "a fetched row is also the schema row_class");
};

done_testing;
