use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

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
            autorow 'My::Test::Row';
            autoname link => sub {
                my %params = @_;
                return "get_$params{fetch_table}";
            };
        };
    };

    ok(my $con = orm('my_orm')->connect, "Got a connection");

    my $foo_a = $con->insert(foo => {name => 'a'});
    my $foo_b = $con->insert(foo => {name => 'b'});
    my $foo_c = $con->insert(foo => {name => 'c'});

    my $bar_a  = $con->insert(bar => {name => 'a',  foo_id => $foo_a->foo_id});
    my $bar_a2 = $con->insert(bar => {name => 'a2', foo_id => $foo_a->foo_id});
    my $bar_a3 = $con->insert(bar => {name => 'a3', foo_id => $foo_a->foo_id});
    my $bar_b  = $con->insert(bar => {name => 'b',  foo_id => $foo_b->foo_id});
    my $bar_c  = $con->insert(bar => {name => 'c',  foo_id => $foo_c->foo_id});

    my $baz = $con->insert(baz => {name => 'a', foo_id => $foo_a->foo_id, bar_id => $bar_a->bar_id});

    my $sel = $con->handle('foo')->join('bar', type => 'left')->join('get_baz', from => 'foo', type => 'left')->order_by(qw/a.foo_id b.bar_id c.baz_id/);
    my $iter = $sel->iterator;
    my $one = $iter->next;
    isa_ok($one, ['DBIx::QuickORM::Join::Row'], "Correct row type");
    ref_is($one->by_alias('a'), $foo_a, "Got the foo_a reference");
    ref_is($one->by_alias('b'), $bar_a, "Got the bar_a reference");
    ref_is($one->by_alias('c'), $baz, "Got the baz reference");

    my $two = $iter->next;
    isa_ok($two, ['DBIx::QuickORM::Join::Row'], "Correct row type");
    ref_is($two->by_alias('a'), $foo_a, "Got the foo_a reference");
    ref_is($two->by_alias('b'), $bar_a2, "Got the bar_a2 reference");
    ref_is($two->by_alias('c'), $baz, "Got the baz reference");

    my $three = $iter->next;
    isa_ok($three, ['DBIx::QuickORM::Join::Row'], "Correct row type");
    ref_is($three->by_alias('a'), $foo_a, "Got the foo_a reference");
    ref_is($three->by_alias('b'), $bar_a3, "Got the bar_a3 reference");
    ref_is($three->by_alias('c'), $baz, "Got the baz reference");

    my $four = $iter->next;
    isa_ok($four, ['DBIx::QuickORM::Join::Row'], "Correct row type");
    ref_is($four->by_alias('a'), $foo_b, "Got the foo_b reference");
    ref_is($four->by_alias('b'), $bar_b, "Got the bar_b reference");
    ok(!defined($four->by_alias('c')), "No baz reference");

    my $five = $iter->next;
    isa_ok($five, ['DBIx::QuickORM::Join::Row'], "Correct row type");
    ref_is($five->by_alias('a'), $foo_c, "Got the foo_c reference");
    ref_is($five->by_alias('b'), $bar_c, "Got the bar_c reference");
    ok(!defined($five->by_alias('c')), "No baz reference");

    ok(!$iter->next, "Got all rows");

    $sel = $con->handle('foo')->left_join('bar')->left_join('bar:get_baz')->left_join('foo:get_baz')->order_by(qw/a.foo_id b.bar_id c.baz_id d.baz_id/);
    ok(lives { $sel->data_only->all }, "Should come back and finish this");

};

done_testing;

__END__

These need to be refactored:

    my $link = bless({}, 'DBIx::QuickORM::Link');
    ref_is($foo_a->parse_link($link), $link, "If it is already a link just return it");

    $link = $foo_a->parse_link({table => 'has_foo', local_columns => ['foo_id'], other_columns => ['foo_id']});
    isa_ok($link, ['DBIx::QuickORM::Link'], "Created a link object");
    like(
        $link,
        {local_table => 'foo', other_table => 'has_foo', local_columns => ['foo_id'], other_columns => ['foo_id'], unique => F()},
        "Created link, and set unique"
    );

    $link = $has_foo_a1->parse_link({table => 'foo', local_columns => ['foo_id'], other_columns => ['foo_id']});
    isa_ok($link, ['DBIx::QuickORM::Link'], "Created a link object");
    like(
        $link,
        {local_table => 'has_foo', other_table => 'foo', local_columns => ['foo_id'], other_columns => ['foo_id'], unique => T()},
        "Created link, and set unique"
    );

    is(
        $foo_a->parse_link(\'has_foo'),
        $con->schema->table('foo')->links_by_alias->{get_has_foo},
        "Got the only link to the specified table",
    );

    like(
        $foo_a->parse_link({has_foo => 'foo_id'}),
        {local_table => 'foo', other_table => 'has_foo', local_columns => ['foo_id'], other_columns => ['foo_id'], unique => F()},
        "Super simple search"
    );

    like(
        $foo_a->parse_link({has_foo => ['foo_id']}),
        {local_table => 'foo', other_table => 'has_foo', local_columns => ['foo_id'], other_columns => ['foo_id'], unique => F()},
        "Super simple search, multi-col"
    );

    like(
        $foo_a->parse_link({has_foo => {local => 'foo_id', other => 'foo_id'}}),
        {local_table => 'foo', other_table => 'has_foo', local_columns => ['foo_id'], other_columns => ['foo_id'], unique => F()},
        "Another form"
    );

    like(
        $foo_a->parse_link({local_table => 'foo', other_table => 'has_foo', fields => 'foo_id', has_foo => 'foo_id'}),
        {local_table => 'foo', other_table => 'has_foo', local_columns => ['foo_id'], other_columns => ['foo_id'], unique => F()},
        "Long form"
    );

    like(
        $foo_a->parse_link({local_table => 'foo', other_table => 'has_foo', local_fields => 'foo_id', has_foo => 'foo_id'}),
        {local_table => 'foo', other_table => 'has_foo', local_columns => ['foo_id'], other_columns => ['foo_id'], unique => F()},
        "Long form 2"
    );

    like(
        $foo_a->parse_link({table => 'has_foo', fields => ['foo_id']}),
        {local_table => 'foo', other_table => 'has_foo', local_columns => ['foo_id'], other_columns => ['foo_id'], unique => F()},
        "Long form 3"
    );

