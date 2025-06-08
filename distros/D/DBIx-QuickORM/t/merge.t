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
    is($orm->schema->{merged}, 'foo', "Schemas were merged");
    is($orm->schema->{tables}->{example}->{merged}, 'bar', "Tables were merged");
    ok($orm->schema->{tables}->{example}->{columns}->{data}->{merged}, "Columns were merged");
    ok($orm->schema->{tables}->{example}->{columns}->{data}->{omit}, "omit was merged into the autofill schema");
};

done_testing;


