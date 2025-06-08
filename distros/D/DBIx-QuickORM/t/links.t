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
            autoname link => sub {
                my %params = @_;
                return "get_$params{fetch_table}";
            };
        };
    };

    ok(my $con = orm('my_orm')->connect, "Got a connection");

    my $foo_a = $con->insert('foo' => {name => 'a'});
    my $foo_b = $con->insert('foo' => {name => 'b'});

    my $has_foo_a1 = $con->insert('has_foo' => {foo_id => $foo_a->field('foo_id')});
    my $has_foo_a2 = $con->insert('has_foo' => {foo_id => $foo_a->field('foo_id')});
    my $has_foo_b  = $con->insert('has_foo' => {foo_id => $foo_b->field('foo_id')});

    my $sel = $foo_a->follow('get_has_foo');
    is([$sel->order_by('foo_id')->all], [$has_foo_a1, $has_foo_a2], "Got both has_foo rows");

    is($has_foo_a1->obtain('get_foo'), $foo_a, "Got foo_a");

    like(
        dies { $foo_a->obtain('get_has_foo') },
        qr/The specified link does not point to a unique row/,
        "Cannot obtain on a non unique link",
    );

    my $has_foo_a3 = $foo_a->insert_related('get_has_foo', {});
    my $has_foo_a4 = $foo_a->insert_related('get_has_foo', {});

    like(
        dies { $foo_a->insert_related('get_has_foo', {foo_id => undef}) },
        qr/field 'foo_id' already exists in provided row data/,
        "Cannot pre-populate the fields from the link",
    );

    my $h = $has_foo_a4->siblings(['foo_id']);
    is($has_foo_a4->siblings('get_foo')->count,      4, "Got all 4 siblings (including self)");
    is($has_foo_a4->siblings(['foo_id'])->count,     4, "Got all 4 siblings (including self)");
    is($has_foo_a4->siblings(['has_foo_id'])->count, 1, "Only self");

};

done_testing;
