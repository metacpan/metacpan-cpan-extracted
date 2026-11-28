# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/RowClasses.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);
    $db->connect->do($SCHEMA);

    # ONE TABLE
    package My::User;
    use parent 'DBIx::QuickORM::Row';

    sub posts { $_[0]->follow_fk('posts') }    # a handle on this user's posts

    sub theme { ($_[0]->field('prefs') // {})->{theme} }    # from the inflated JSON

    sub change_email {
        my ($self, $email) = @_;
        # rows have no setters: writes go through update
        return $self->update({email => $email});
    }

    package main;

    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_classes => {users => 'My::User'},
    );

    my $ann = $orm->insert(
        users => {
            name  => 'Ann',
            prefs => {theme => 'dark'},
        }
    );
    my $theme = $ann->theme;    # 'dark'

    # a DBIx::QuickORM::Row: posts has no row class here
    my $post = $orm->insert(
        posts => {
            user_id => $ann->field('id'),
            title   => 'Hi',
        }
    );

    my $count = $ann->posts->count;    # 1
    $ann->change_email('ann@example.com');

    isa_ok($ann,  ['My::User'],            "users rows are the table's class");
    isa_ok($post, ['DBIx::QuickORM::Row'], "posts rows are the default class");
    ok(!$post->isa('My::User'), "and not the users class");
    is($theme,               'dark',            "a method over the inflated field");
    is($count,               1,                 "a method returning a handle");
    is($ann->field('email'), 'ann@example.com', "a method writing through update");
    isa_ok($orm->find(users => $ann->field('id')),                   ['My::User'], "find gives the class");
    isa_ok($orm->handle('users')->where({name => 'Ann'})->only,      ['My::User'], "so does a handle");
    isa_ok($post->follow_fk('users')->only,                          ['My::User'], "and follow_fk");
    isa_ok($orm->handle('posts')->join('users')->only->row('users'), ['My::User'], "and a join's component row");
    is($orm->find(users => $ann->field('id'), cache => 0)->field('email'), 'ann@example.com', "the update reached the database");

    # EVERY TABLE
    package My::Row;
    use parent 'DBIx::QuickORM::Row';

    sub id { $_[0]->field('id') }    # every table here has one

    package main;

    my $app = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_class   => 'My::Row',                # the default for every table
        row_classes => {users => 'My::User'},    # but users
    );

    my $hi = $app->handle('posts')->where({title => 'Hi'})->only;
    my $id = $hi->id;

    isa_ok($hi, ['My::Row'], "the ORM's row class covers a table without one of its own");
    is($id, $post->field('id'), "and its method works");
    isa_ok($app->find(users => $ann->field('id')), ['My::User'], "the table's class wins over the ORM's");
    ok(!$app->find(users => $ann->field('id'))->isa('My::Row'), "and does not get the ORM's unless it extends it");

    # HASHREFS
    my @data = $app->handle('users')->data_only->all;    # the row data itself
    my $name = $data[0]->{name};
    # as the database returned it: JSON text
    my $json = $data[0]->{prefs};

    my $plain = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_class => undef,    # hashrefs for every table
    );

    # a hashref: {id => ..., name => 'Bob', email => undef, ...}
    my $bob  = $plain->insert(users => {name => 'Bob'});
    my $same = $plain->find(users => $bob->{id});
    # new row data ($bob is unchanged)
    my $new  = $plain->update_row(users => $bob, {name => 'Robert'});
    my $gone = $plain->delete_row(users => $new);                       # 1

    is(ref($data[0]), 'HASH',             "row_class(undef) on a handle gives hashrefs");
    is($name,         'Ann',              "holding the row data");
    is($json,         '{"theme":"dark"}', "not inflated");
    is(ref($bob),     'HASH',             "row_class undef on the ORM gives hashrefs from every primitive");
    is($bob->{id},    2,                  "with the key");
    is($bob->{name},  'Bob',              "and the values");
    ok(exists($bob->{email}) && !defined($bob->{email}), "NULL is undef");
    is($same,                                                     {%$bob},  "find gives the same row data");
    is($new->{name},                                              'Robert', "update_row returns the new row data");
    is($bob->{name},                                              'Bob',    "and leaves the given hashref alone");
    is($gone,                                                     1,        "delete_row deletes by the row data's key");
    is($plain->handle('users')->where({name => 'Robert'})->count, 0,        "and the row is gone");
    isa_ok($plain->handle('users')->row_class('My::Row')->first, ['My::Row'], "a handle row_class gives rows again");
    ref_ok($plain->handle('posts')->fields({n => [count => '*']})->first, 'HASH', "computed rows are hashrefs when the table's class is undef");
    like(dies { $app->handle('posts')->join('users')->row_class('My::Row')->all }, qr/row_class can only be undef/, "a join handle takes no class but undef");

    # ROWS NOT IN THE DATABASE
    my $draft = $orm->vivify(users => {name => 'Draft'});    # nothing written yet
    $draft->modify({email => 'draft@example.com'});
    my $stored = $draft->is_in_db;                           # false

    $draft->insert;                                          # now it is
    $draft->update({name => 'Final'});

    $draft->delete;
    my $deleted = $draft->was_deleted;                       # true
    $draft->insert;                                          # back in, with the same key

    is($stored,  0, "a vivified row is not in the database");
    is($deleted, 1, "a deleted row was_deleted");
    ok($draft->is_in_db, "inserted again");
    is($orm->find(users => $draft->field('id'), cache => 0)->field('email'), 'draft@example.com', "with what modify set");
    like(dies { $orm->vivify(users => {name => 'X'})->update({name => 'Y'}) }, qr/not in the database|insert/i, "update croaks on a row not in the database");
    like(dies { $draft->modify({name => 'Z'}) },                               qr/use update/,                  "modify croaks on a stored row");
    $draft->delete;

    # THE ROLE
    package My::RawRow;
    use Object::HashBase qw{<orm <table row_data};
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Row';

    # raw by default, but inflated_field still inflates
    sub field  { my $self = shift; $self->raw_field(@_) }
    sub fields { my $self = shift; $self->raw_fields(@_) }

    package main;

    # one query's rows
    my $raw = $app->handle('users')->where({id => $ann->field('id')})->row_class('My::RawRow')->only;

    my $text  = $raw->field('prefs');             # '{"theme":"dark"}'
    my $prefs = $raw->inflated_field('prefs');    # {theme => 'dark'}

    isa_ok($raw, ['My::RawRow'], "a handle row_class builds the class");
    is($text,                                         '{"theme":"dark"}', "field gives the raw form");
    is($prefs,                                        {theme => 'dark'},  "inflated_field still inflates");
    is($raw->update({name => 'Anne'})->field('name'), 'Anne',             "the role's update works");
    is($raw->pk,                                      {id => 1},          "and pk");
    $raw->update({name => 'Ann'});

    package My::Bare;
    # new, orm, table, row_data, set_row_data: all the ORM needs
    use Object::HashBase qw{<orm <table row_data};

    package main;

    my $bare = $app->handle('users')->row_class('My::Bare')->first;
    # field(), update(), and the rest are yours to add
    my $data = $bare->row_data;

    isa_ok($bare, ['My::Bare'], "a class with only the attributes works");
    is($data->{name}, 'Ann', "holding the row data");
    ok(!$bare->can('field'), "with nothing the class did not add");
    ref_is($app->update_row(users => $bare, {name => 'Annie'}), $bare, "update_row returns the given row");
    is($bare->row_data->{name}, 'Annie', "after set_row_data gave it the new data");
    ref_is($bare->orm, $app, "orm");
    is($bare->table, 'users', "table");

    # A CLASS PER TABLE, BY NAME
    package My::Rows::Users;
    use parent 'DBIx::QuickORM::Row';

    sub name { $_[0]->field('name') }

    package main;

    my $named = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_namespace => 'My::Rows',
    );

    my $ned  = $named->insert(users => {name => 'Ned'});    # a My::Rows::Users
    my $who  = $ned->name;
    my $note = $named->insert(
        posts => {
            user_id => $ned->field('id'),
            title   => 'Note',
        }
    );                                                      # no My::Rows::Posts: a DBIx::QuickORM::Row

    isa_ok($ned, ['My::Rows::Users'], "row_namespace gives users its class by name");
    is($who,       'Ned',                 "and its method works");
    is(ref($note), 'DBIx::QuickORM::Row', "a table without a class there keeps the default");
    $named->delete_row(posts => $note);
    $named->delete_row(users => $ned);

    package My::Rows::Person;
    use parent 'DBIx::QuickORM::Row';

    package main;

    my $people = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        row_namespace  => 'My::Rows',
        row_class_name => sub {
            my ($table) = @_;
            return 'Person' if $table eq 'users';
            return undef;    # the default row class
        },
    );

    my $pat = $people->insert(users => {name => 'Pat'});    # a My::Rows::Person

    isa_ok($pat,                                                                    ['My::Rows::Person'],    "row_class_name names the class part");
    isa_ok($people->insert(posts => {user_id => $pat->field('id'), title => 'Hi'}), ['DBIx::QuickORM::Row'], "undef keeps the default");
};

done_testing;
