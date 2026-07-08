use Test2::V0 '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;

# dsl I6: an `autoname link` callback that declines (returns a falsy value)
# must NOT claim the link. Previously the falsy return was pushed onto the link
# pair anyway, marking it "already aliased" and suppressing the default derived
# accessor names. Reuse the links schema (foo <- has_foo via foo_id).

sub SCHEMA_DIR { 't/links' }

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
            autorow 'DSLI6AutoRow';             # so link accessors get installed
            autoname link => sub { return };    # always "no opinion"
        };
    };

    my $con = orm('my_orm')->connect;

    my $foo = $con->insert('foo'     => {name => 'a'});
    my $hf  = $con->insert('has_foo' => {foo_id => $foo->field('foo_id')});

    # has_foo -> foo is a unique FK: the default accessor is the linked table
    # name ('foo'), installed as an obtain()-backed method on the row class.
    my $got_foo;
    ok(lives { $got_foo = $hf->foo }, "default unique-link accessor 'foo' still installed") or note $@;
    is($got_foo, $foo, "\$has_foo->foo returned the linked foo row");

    # foo -> has_foo is non-unique: the default accessor is the pluralized table
    # name ('has_foos'), installed as a follow()-backed method.
    my @got_hf;
    ok(lives { @got_hf = $foo->has_foos->all }, "default non-unique-link accessor 'has_foos' still installed") or note $@;
    is(\@got_hf, [$hf], "\$foo->has_foos returned the related has_foo row");
} 'sqlite';

done_testing;
