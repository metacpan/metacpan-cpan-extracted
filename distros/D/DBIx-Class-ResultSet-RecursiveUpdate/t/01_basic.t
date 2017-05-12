use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Trap;
use DBIx::Class::ResultSet::RecursiveUpdate;

use lib 't/lib';
use DBSchema;

my $schema = DBSchema->get_test_schema();

# moosified tests
#use DBSchemaMoose;
#my $schema = DBSchemaMoose->get_test_schema('dbi:SQLite:dbname=:memory:');
# pg tests
#my ( $dsn, $user, $pass ) = @ENV{ map {"DBICTEST_PG_${_}"} qw/DSN USER PASS/ };
#my $schema = DBSchema->get_test_schema( $dsn, $user, $pass );

my $dvd_rs  = $schema->resultset('Dvd');
my $user_rs = $schema->resultset('User');

my $owner               = $user_rs->next;
my $another_owner       = $user_rs->next;
my $initial_user_count  = $user_rs->count;
my $expected_user_count = $initial_user_count;
my $initial_dvd_count   = $dvd_rs->count;
my $updates;

# pre 0.21 api
$dvd_rs->search( { dvd_id => 1 } )
  ->recursive_update( { owner => { username => 'aaa' } }, ['dvd_id'] );

my $u = $user_rs->find( $dvd_rs->find(1)->owner->id );
is( $u->username, 'aaa', 'fixed_fields pre 0.21 api ok' );

# 0.21+ api
$dvd_rs->search( { dvd_id => 1 } )
  ->recursive_update( { owner => { username => 'bbb' } },
    { fixed_fields => ['dvd_id'], } );

$u = $user_rs->find( $dvd_rs->find(1)->owner->id );
is( $u->username, 'bbb', 'fixed_fields 0.21+ api ok' );

{

    # try to create with a not existing rel
    my $updates = {
        name        => 'Test for nonexisting rel',
        username    => 'nonexisting_rel',
        password    => 'whatever',
        nonexisting => { foo => 'bar' },
    };

    warning_like {
        my $user = $user_rs->recursive_update($updates);
    }
qr/No such column, relationship, many-to-many helper accessor or generic accessor 'nonexisting'/,
      'nonexisting column, accessor, relationship warns';
    $expected_user_count++;
    is( $user_rs->count, $expected_user_count, 'User created' );

}

{

    # try to create with a not existing rel but suppressed warning
    my $updates = {
        name        => 'Test for nonexisting rel with suppressed warning',
        username    => 'suppressed_nonexisting_rel',
        password    => 'whatever',
        nonexisting => { foo => 'bar' },
    };

    warning_is {
        my $user =
          $user_rs->recursive_update( $updates, { unknown_params_ok => 1 } );
    }
    "",
"nonexisting column, accessor, relationship doesn't warn with unknown_params_ok";
    $expected_user_count++;
    is( $user_rs->count, $expected_user_count, 'User created' );
}

{

# try to create with a not existing rel, suppressed warning but storage debugging
    my $updates = {
        name =>
'Test for nonexisting rel with suppressed warning but storage debugging',
        username    => 'suppressed_nonexisting_rel_with_storage_debug',
        password    => 'whatever',
        nonexisting => { foo => 'bar' },
    };

    my $debug = $user_rs->result_source->storage->debug;
    $user_rs->result_source->storage->debug(1);

    my $user;
    my @r = trap {
        $user =
          $user_rs->recursive_update( $updates, { unknown_params_ok => 1 } );
    };
    like(
        $trap->stderr,
qr/No such column, relationship, many-to-many helper accessor or generic accessor 'nonexisting'/,
"nonexisting column, accessor, relationship doesn't warn with unknown_params_ok"
    );
    $expected_user_count++;
    is( $user_rs->count, $expected_user_count, 'User created' );

    $user_rs->result_source->storage->debug($debug);
}

# creating new record linked to some old record
$updates = {
    name     => 'Test name 2',
    viewings => [ { user_id => $owner->id } ],
    owner => { id => $another_owner->id },
};

my $new_dvd = $dvd_rs->recursive_update($updates);

is( $dvd_rs->count, $initial_dvd_count + 1, 'Dvd created' );

is( $schema->resultset('User')->count,
    $expected_user_count, "No new user created" );
is( $new_dvd->name,            'Test name 2',      'Dvd name set' );
is( $new_dvd->owner->id,       $another_owner->id, 'Owner set' );
is( $new_dvd->viewings->count, 1,                  'Viewing created' );

# creating new records
$updates = {
    tags             => [ '2', { id => '3' } ],
    name             => 'Test name',
    owner            => $owner,
    current_borrower => {
        name     => 'temp name',
        username => 'temp name',
        password => 'temp name',
    },
    liner_notes => { notes => 'test note', },
    like_has_many  => [ { key2 => 1 } ],
    like_has_many2 => [
        {
            onekey => { name => 'aaaaa' },
            key2   => 1
        }
    ],
};

my $dvd = $dvd_rs->recursive_update($updates);
$expected_user_count++;

is( $dvd_rs->count, $initial_dvd_count + 2, 'Dvd created' );
is( $schema->resultset('User')->count,
    $expected_user_count, "One new user created" );
is( $dvd->name, 'Test name', 'Dvd name set' );
is_deeply( [ map { $_->id } $dvd->tags ], [ '2', '3' ], 'Tags set' );
is( $dvd->owner->id, $owner->id, 'Owner set' );

is( $dvd->current_borrower->name, 'temp name', 'Related record created' );
is( $dvd->liner_notes->notes,     'test note', 'might_have record created' );
ok(
    $schema->resultset('Twokeys')
      ->find( { dvd_name => 'Test name', key2 => 1 } ),
    'Twokeys created'
);
my $onekey = $schema->resultset('Onekey')->search( { name => 'aaaaa' } )->first;
ok( $onekey, 'Onekey created' );
ok(
    $schema->resultset('Twokeys_belongsto')
      ->find( { key1 => $onekey->id, key2 => 1 } ),
    'Twokeys_belongsto created'
);
TODO: {
    local $TODO = 'value of fk from a multi relationship';
    is( $dvd->twokeysfk, $onekey->id, 'twokeysfk in Dvd' );
}
is( $dvd->name, 'Test name', 'Dvd name set' );

# changing existing records
my $num_of_users = $user_rs->count;
$updates = {
    dvd_id           => $dvd->dvd_id,
    name             => undef,
    tags             => [],
    owner            => $another_owner->id,
    current_borrower => {
        username => 'new name a',
        name     => 'new name a',
        password => 'new password a',
    },
    liner_notes => { notes => 'test note changed', },

};
my $dvd_updated = $dvd_rs->recursive_update($updates);

is( $dvd_updated->dvd_id, $dvd->dvd_id, 'Pk from "dvd_id"' );
is( $schema->resultset('User')->count,
    $expected_user_count, "No new user created" );
is( $dvd_updated->name, undef, 'Dvd name deleted' );
is( $dvd_updated->get_column('owner'), $another_owner->id, 'Owner updated' );
is( $dvd_updated->current_borrower->name,
    'new name a', 'Related record modified' );
is( $dvd_updated->tags->count, 0, 'Tags deleted' );
is(
    $dvd_updated->liner_notes->notes,
    'test note changed',
    'might_have record changed'
);

my $dvd_with_tags =
  $dvd_rs->recursive_update( { dvd_id => $dvd->dvd_id, tags => [ 1, 2 ] } );
is_deeply( [ map { $_->id } $dvd_with_tags->tags ], [ 1, 2 ], 'Tags set' );
my $dvd_without_tags =
  $dvd_rs->recursive_update( { dvd_id => $dvd->dvd_id, tags => undef } );
is( $dvd_without_tags->tags->count,
    0, 'Tags deleted when m2m accessor set to undef' );

$new_dvd->update( { name => 'New Test Name' } );
$updates = {
    dvd_id => $new_dvd->dvd_id,
    like_has_many => [ { dvd_name => $dvd->name, key2 => 1 } ],
};
$dvd_updated = $dvd_rs->recursive_update($updates);
ok(
    $schema->resultset('Twokeys')
      ->find( { dvd_name => 'New Test Name', key2 => 1 } ),
    'Twokeys updated'
);
ok(
    !$schema->resultset('Twokeys')
      ->find( { dvd_name => $dvd->name, key2 => 1 } ),
    'Twokeys updated'
);

# repeatable
$updates = {
    name       => 'temp name',
    username   => 'temp username',
    password   => 'temp username',
    owned_dvds => [
        {
            'name' => 'temp name 1',
            'tags' => [ 1, 2 ],
        },
        {
            'name' => 'temp name 2',
            'tags' => [ 2, 3 ],
        }
    ]
};

my $user = $user_rs->recursive_update($updates);
$expected_user_count++;

is( $schema->resultset('User')->count,
    $expected_user_count, "New user created" );
is( $dvd_rs->count, $initial_dvd_count + 4, 'Dvds created' );
my %owned_dvds = map { $_->name => $_ } $user->owned_dvds;
is( scalar keys %owned_dvds, 2, 'Has many relations created' );
ok( $owned_dvds{'temp name 1'}, 'Name in a has_many related record saved' );
my @tags = $owned_dvds{'temp name 1'}->tags;
is( scalar @tags, 2, 'Tags in has_many related record saved' );
ok( $owned_dvds{'temp name 2'},
    'Second name in a has_many related record saved' );

# update has_many where foreign cols aren't nullable
$updates = {
    id      => $user->id,
    address => {
        street => "101 Main Street",
        city   => "Podunk",
        state  => "New York"
    },
    owned_dvds => [ { dvd_id => 1, }, ]
};
$user = $user_rs->recursive_update($updates);
is( $schema->resultset('Address')->search( { user_id => $user->id } )->count,
    1, 'the right number of addresses' );
$dvd = $dvd_rs->find(1);
is( $dvd->get_column('owner'), $user->id, 'foreign key set' );

# has_many where foreign cols are nullable
my $available_dvd_rs = $dvd_rs->search( { current_borrower => undef } );
$dvd_rs->update( { current_borrower => $user->id } );
ok( $user->borrowed_dvds->count > 1, 'Precond' );
$updates = {
    id            => $user->id,
    borrowed_dvds => [ { dvd_id => $dvd->id }, ]
};
$user = DBIx::Class::ResultSet::RecursiveUpdate::Functions::recursive_update(
    resultset        => $user_rs,
    updates          => $updates,
    if_not_submitted => 'set_to_null',
);
is( $user->borrowed_dvds->count,
    1, 'borrowed_dvds update with if_not_submitted => set_to_null ok' );
is( $available_dvd_rs->count, 5, "previously borrowed dvds weren't deleted" );

$dvd_rs->update( { current_borrower => $user->id } );
$user = DBIx::Class::ResultSet::RecursiveUpdate::Functions::recursive_update(
    resultset => $user_rs,
    updates   => $updates,
);
is( $user->borrowed_dvds->count,
    1, 'borrowed_dvds update without if_not_submitted ok' );
is( $available_dvd_rs->count, 5, "previously borrowed dvds weren't deleted" );

$dvd_rs->update( { current_borrower => $user->id } );
$user = DBIx::Class::ResultSet::RecursiveUpdate::Functions::recursive_update(
    resultset        => $user_rs,
    updates          => $updates,
    if_not_submitted => 'delete',
);
is( $user->borrowed_dvds->count,
    1, 'borrowed_dvds update with if_not_submitted => delete ok' );
is( $dvd_rs->count, 1,
    'all dvds except the one borrowed by the user were deleted' );

@tags = $schema->resultset('Tag')->all;
$dvd_updated =
  DBIx::Class::ResultSet::RecursiveUpdate::Functions::recursive_update(
    resultset => $schema->resultset('Dvd'),
    updates   => {
        dvd_id => $dvd->dvd_id,
        tags => [
            { id => $tags[0]->id, file => 'file0' },
            { id => $tags[1]->id, file => 'file1' }
        ],
    }
  );
$tags[$_]->discard_changes for 0 .. 1;
is( $tags[0]->file, 'file0', 'file set in tag' );
is( $tags[1]->file, 'file1', 'file set in tag' );
my @rel_tags = $dvd_updated->tags;
is( scalar @rel_tags, 2, 'tags related' );
ok( $rel_tags[0]->file eq 'file0' || $rel_tags[0]->file eq 'file1',
    'tags related' );

my $new_person = {
    name     => 'Amiri Barksdale',
    username => 'amiri',
    password => 'amiri',
};
ok( my $new_user = $user_rs->recursive_update($new_person) );

# delete has_many where foreign cols aren't nullable
my $rs_user_dvd = $user->owned_dvds;
my @user_dvd_ids = map { $_->dvd_id } $rs_user_dvd->all;
is( $rs_user_dvd->count, 1, 'user owns 1 dvd' );
$updates = {
    id         => $user->id,
    owned_dvds => undef,
};
$user = $user_rs->recursive_update($updates);
is( $user->owned_dvds->count, 0, 'user owns no dvds' );
is( $dvd_rs->search( { dvd_id => { -in => \@user_dvd_ids } } )->count,
    0, 'owned dvds deleted' );

done_testing;
