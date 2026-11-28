# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/ORM.pm. Whenever an example
# there changes, change its copy here to match: t/acceptance/Examples.t fails while any example has
# no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my $dbh = $db->connect;

    package My::ORM;
    use DBIx::QuickORM::DSL ':orm';

    orm {
        retain_cache 1;
    };

    package main;

    my $orm = My::ORM->new(
        dbh   => $dbh,
        types => {users => {prefs => undef}},
    );

    isa_ok($orm, ['DBIx::QuickORM::ORM', 'DBIx::QuickORM'], "an ORM class builds the ORM");
    is($orm->retain_cache,                                1,     "with its orm block's settings");
    is($orm->db_map->field(users => 'prefs')->{orm_type}, undef, "and the arguments to new");
};

done_testing;
