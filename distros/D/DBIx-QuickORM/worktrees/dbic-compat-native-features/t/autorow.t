use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib', 't/autorow/';
use DBIx::QuickORM::Test;

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm myorm => sub {
        db 'mydb';
        autofill sub {
            autorow 'MyAutoRow';

            autoname link_accessor => sub {
                my %params = @_;
                my $link = $params{link};

                return "obtain_" . $link->other_table if $params{link}->unique;
                return "select_" . $link->other_table . "s";
            };

            autoname field_accessor => sub {
                my %params = @_;
                return "get_$params{name}";
            };
        };
    };

    my $con = orm('myorm')->connect;
    note "Using dialect '" . $con->dialect->dialect_name . "'";

    ok(my $one = $con->insert('foo' => {name => 'one'}), "Got one");
    isa_ok($one, ['DBIx::QuickORM::Row', 'MyAutoRow::Foo'], "Isa row, and the correct row class");
    is($one->field('name'), 'one', "Can access field");
    is($one->get_name, 'one', "get_name() generated");
    is([$one->select_bazs->all], [], "Empty set, but accessor created");

    ok(my $baz_a = $con->insert('baz' => {name => 'a', foo_id => $one->get_foo_id}), "Got a baz");
    ok(my $baz_b = $con->insert('baz' => {name => 'b', foo_id => $one->get_foo_id}), "Got a baz");

    is([$one->select_bazs->all], [$baz_a, $baz_b], "Got both baz instances");
    ref_is($baz_a->obtain_foo, $one, "Got the foo from the baz");
};

done_testing;
