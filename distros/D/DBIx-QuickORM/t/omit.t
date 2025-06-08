use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;
use Carp::Always;

use lib 't/lib';
use DBIx::QuickORM::Test;

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm my_orm => sub {
        db 'mydb';
        autofill sub {
            autotype 'JSON';
        };

        schema my_schema => sub {
            meta->{merged} = 'foo';
            table example => sub {
                meta->{merged} = 'bar';
                column data => sub {
                    meta->{merged} = 'baz';
                    type 'JSON';
                    omit;
                };
            };
        }
    };

    ok(my $orm = orm('my_orm')->connect, "Got a connection");
    ok(my $row = $orm->handle('example')->insert({name => 'a', data => {foo => 'bar'}}), "Inserted a row");
    ok($orm->schema->{tables}->{example}->{columns}->{data}->{omit}, "omit was merged into the autofill schema");
    $row = undef; $row = $orm->handle('example')->one(name => 'a');
    ok(!exists($row->row_data->{stored}->{data}), "did not fetch data");

    is($row->field('data'), {foo => 'bar'}, "Can fetch data");
    my $addr = "$row";
    $row = undef;
    $row = $orm->handle('example')->one({name => 'a'});

    return;

    ok($row, "got row");
    isnt("$row", $addr, "uncached copy");
    ok(!exists($row->row_data->{stored}->{data}), "did not fetch data");

    $row = undef;

    $row = $orm->handle('example')->one({name => 'a'}, omit => {'name' => 1});
    ok(!exists($row->row_data->{stored}->{name}), "Did not fetch name");

    like(
        dies { $orm->handle('example')->one({name => 'a'}, omit => {id => 1}) },
        qr/Cannot omit primary key field 'id'/,
        "Cannot omit a primary key field"
    );
};

done_testing;
