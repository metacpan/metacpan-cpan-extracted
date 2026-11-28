# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;

do_for_all_dbs {
    my ($db, $set) = @_;

    my $dbh = $db->connect;
    $dbh->do("CREATE TABLE orgs (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(20))");
    $dbh->do("CREATE TABLE users (id INTEGER NOT NULL PRIMARY KEY, org_id INTEGER, manager_id INTEGER, email VARCHAR(40) UNIQUE, name VARCHAR(20), FOREIGN KEY (org_id) REFERENCES orgs(id))");
    $dbh->do("CREATE TABLE badges (id INTEGER NOT NULL PRIMARY KEY, user_email VARCHAR(40), FOREIGN KEY (user_email) REFERENCES users(email))");
    $dbh->do("CREATE TABLE profiles (user_id INTEGER NOT NULL PRIMARY KEY, bio VARCHAR(20), FOREIGN KEY (user_id) REFERENCES users(id))");

    # Table-level FOREIGN KEY clauses: older MySQL ignores inline REFERENCES. The self-reference is a
    # virtual key, since not every backend declares one.
    my $orm = DBIx::QuickORM->new(dbh => $dbh, omit => {users => ['name']}, fks => {users => {users => [{manager_id => 'id'}]}});

    $orm->insert(orgs     => {id      => 1, name => 'acme'});
    $orm->insert(users    => {id      => $_->[0], org_id => $_->[1], manager_id => $_->[2], email => "u$_->[0]\@x", name => "u$_->[0]"}) for [1, 1, undef], [2, 1, 1], [3, undef, 1];
    $orm->insert(users    => {id      => 4});                         # no email
    $orm->insert(badges   => {id      => 3, user_email => undef});    # and no owner
    $orm->insert(badges   => {id      => $_, user_email => 'u2@x'}) for 1, 2;
    $orm->insert(profiles => {user_id => 2, bio => 'hi'});

    my $two = $orm->handle('users')->find(2);

    subtest forward => sub {
        my $h = $two->follow_fk('orgs');
        isa_ok($h, ['DBIx::QuickORM::Handle'], "follow_fk returns a handle");
        is($h->state,               'single', "single when the link reaches the other table's primary key");
        is($h->only->field('name'), 'acme',   "finding the linked row");

        my $none = $orm->handle('users')->find(3)->follow_fk('orgs');
        is($none->state,                                               'single', "a NULL link is still single");
        is($none->only,                                                undef,    "and finds nothing");
        is([$orm->handle('badges')->find(3)->follow_fk('users')->all], [],       "A NULL link matches no row, not the rows whose key is NULL");

        my $badge = $orm->handle('badges')->find(1);
        my $owner = $badge->follow_fk('users');
        is($owner->state,             'single', "single when the link reaches a unique key");
        is($owner->only->field('id'), 2,        "finding the row");
    };

    subtest reverse => sub {
        my $members = $orm->handle('orgs')->find(1)->follow_fk('users');
        is($members->state,                              'multi', "A link back from another table's key is multi");
        is([sort map { $_->field('id') } $members->all], [1, 2],  "and finds the rows pointing here");
        like(dies { $members->only }, qr/^only\(\) cannot be used on a multi-row iterator/, "only croaks under multi");

        is($two->follow_fk('badges')->state, 'multi', "multi when the other side is not unique");
        my $profile = $two->follow_fk('profiles');
        is($profile->state,                                             'single', "single when the other side is its table's primary key");
        is($profile->only->field('bio'),                                'hi',     "finding it");
        is($orm->handle('users')->find(1)->follow_fk('profiles')->only, undef,    "or nothing, whatever the data");
    };

    subtest narrow_and_join => sub {
        my $members = $orm->handle('orgs')->find(1)->follow_fk('users');
        is([sort map { $_->field('id') } $members->and({manager_id => 1})->all], [2],       "and narrows a follow_fk handle to that parent's rows");
        is([sort map { $_->field('id') } $members->or({id => 4})->all],          [1, 2, 4], "or widens it");

        my @joined = $two->follow_fk('orgs')->join('users')->order_by('users.id')->all;
        is([map { $_->row('users')->field('id') } @joined],  [1,      2],      "A follow_fk handle can be joined: its link fields are qualified");
        is([map { $_->row('orgs')->field('name') } @joined], ['acme', 'acme'], "with the followed row in each result");

        my $reports = $orm->handle('users')->find(1)->follow_fk('users', link => {id => 'manager_id'});
        is([sort map { $_->field('id') } $reports->and({org_id => 1})->all], [2], "and narrows a self-referencing follow too");
    };

    subtest self_reference => sub {
        like(dies { $two->follow_fk('users') }, qr/^There is more than one foreign key between 'users' and 'users'/, "A self-reference is ambiguous without a link");
        is($two->follow_fk('users', link => {manager_id => 'id'})->only->field('id'), 1, "{manager_id => 'id'} follows to the manager");
        my $reports = $orm->handle('users')->find(1)->follow_fk('users', link => {id => 'manager_id'});
        is($reports->state,                                                                        'multi', "{id => 'manager_id'} follows to the reports");
        is([sort map { $_->field('id') } $reports->all],                                           [2, 3],  "and finds them");
        is($orm->handle('users')->find(1)->follow_fk('users', link => {manager_id => 'id'})->only, undef,   "A NULL link finds nothing");
    };

    subtest missing_fields => sub {
        $orm->clear_cache;
        my $data = {id => 2};
        my $h    = $orm->follow_fk(users => $data, 'orgs');
        is($h->where,               {'orgs.id' => 1}, "A link field missing from the row data is fetched first");
        is($h->only->field('name'), 'acme',           "and followed");
        like(dies { $orm->follow_fk(users => {id => 99}, 'orgs') }, qr/^Cannot follow the foreign key: the row is no longer in the table 'users'/, "a row that is gone croaks");
    };

    subtest via => sub {
        my $plain = DBIx::QuickORM->new(dbh => $dbh);    # no virtual manager_id key
        my $two   = $plain->handle('users')->find(2);
        like(dies { $two->follow_fk('users', link => {manager_id => 'id'}) }, qr/^The link \(manager_id => id\) matches no foreign key/, "link needs a key in the map");

        my $up = $two->follow_fk('users', via => {manager_id => 'id'});
        is($up->state,             'single', "via follows without a key; single when it reaches the primary key");
        is($up->only->field('id'), 1,        "to the manager");
        my $down = $plain->handle('users')->find(1)->follow_fk('users', via => {id => 'manager_id'});
        is($down->state,                                                                                   'multi', "multi when the other side is not unique");
        is([sort map { $_->field('id') } $down->all],                                                      [2, 3],  "the reports");
        is($plain->follow_fk(users => {id => 2}, 'users', via => {manager_id => 'id'})->only->field('id'), 1,       "the ORM form fetches a missing field first");

        my @joined = $plain->handle('users')->join('users', as => 'boss', via => {manager_id => 'id'})->where({'users.id' => 2})->all;
        is([map { $_->row('boss')->field('id') } @joined], [1], "a join takes via");

        like(dies { $two->follow_fk('users', via => {manger_id => 'id'}) },  qr/^'via' names 'manger_id', which is not a field of 'users'/, "a field missing from this table croaks");
        like(dies { $two->follow_fk('orgs',  via => {org_id    => 'idd'}) }, qr/^'via' names 'idd', which is not a field of 'orgs'/,        "so does one missing from the other");
        like(dies { $two->follow_fk('nope',  via => {org_id    => 'id'}) },  qr/^The table 'nope' is not in the database map/,              "and an unknown table");
        like(dies { $two->follow_fk('users', via => {}) }, qr/^'via' must be a hashref of field => field/, "via needs a mapping");
        like(dies { $two->follow_fk('orgs', link => {org_id => 'id'}, via => {org_id => 'id'}) }, qr/^Give 'link' or 'via', not both/, "link and via together croak");
    };
};

done_testing;
