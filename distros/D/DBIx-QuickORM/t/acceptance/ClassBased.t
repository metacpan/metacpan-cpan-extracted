# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM::Test;
use DBIx::QuickORM::Test::ORM;
use DBIx::QuickORM::Test::ListORM;

do_for_all_dbs {
    my ($db, $set) = @_;

    my $dbh = $db->connect;
    $dbh->do("CREATE TABLE orgs (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(20))");
    $dbh->do("CREATE TABLE users (id INTEGER NOT NULL PRIMARY KEY, org_ref INTEGER, name VARCHAR(20), bio VARCHAR(40), prefs VARCHAR(100))");
    $dbh->do("CREATE TABLE audit (id INTEGER NOT NULL PRIMARY KEY, payload VARCHAR(40))");

    my $orm = DBIx::QuickORM::Test::ORM->new(dbh => $dbh);

    my $org  = $orm->insert(orgs  => {id => 1, name    => 'acme'});
    my $user = $orm->insert(users => {id => 1, org_ref => 1, name => 'bob', bio => 'hi', prefs => {theme => 'dark'}});

    isa_ok($user, ['DBIx::QuickORM::Test::ORM::Users', 'DBIx::QuickORM::Row'], "A table and row class builds its table's rows");
    is($user->display_name, 'user bob', "with its methods");
    isa_ok($org, ['DBIx::QuickORM::Test::ORM::OrgRow'], "A table class's row_class builds its rows");
    is($org->label, 'org acme', "with that class's methods");
    isa_ok($orm->insert(audit => {id => 1, payload => 'x'}), ['DBIx::QuickORM::Test::Row'], "Other tables use the orm block's row class");

    is($user->follow_fk('orgs')->only->label, 'org acme', "A virtual foreign key from a table class can be followed");
    ok(!exists($user->row_data->{bio}), "An omitted field is not fetched");
    is($user->field('bio'), 'hi', "until it is read");

    $orm->clear_cache;
    is($orm->handle('users')->find(1)->field('prefs'), {theme => 'dark'}, "A type from a table class round-trips");

    # DuckDB allows one connection to a database file.
    $dbh->disconnect;
    my $list = DBIx::QuickORM::Test::ListORM->new(dbh => $db->connect);
    is($list->handle('users')->find(1), {id => 1, org_ref => 1, name => 'bob', bio => 'hi', prefs => '{"theme":"dark"}'}, "An ORM listing other table classes leaves this table alone");
    isa_ok($list->handle('orgs')->find(1), ['DBIx::QuickORM::Test::ORM::OrgRow'], "and uses the ones it lists");
};

done_testing;
