# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Row.pm. Whenever an example there
# changes, change its copy here to match: t/acceptance/Examples.t fails while any example has no copy
# in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);

    my %credentials = (dsn => $db->connect_string, user => $db->username, pass => $db->password);
    my $orm         = DBIx::QuickORM->new(credentials => \%credentials);

    my $id  = $orm->insert(users => {name => 'Alice', email => 'alice@example.com', prefs => {theme => 'dark'}})->field('id');
    my $bob = $orm->insert(users => {name => 'Bob',   email => 'bob@example.com'});
    $orm->insert(posts => {user_id => $bob->field('id'), title => $_->[0], views => $_->[1]}) for ['Hello', 5], ['Popular', 500];

    # SYNOPSIS
    {
        my $bob  = $orm->insert(users => {name => 'Bob'});
        my $name = $bob->field('name');
        $bob->update({name => 'Robert'});

        is($name,               'Bob',    "insert returns a row");
        is($bob->field('name'), 'Robert', "update changes it");
    }

    # Read fields
    my $user = $orm->find(users => $id);

    my $name = $user->field('name');
    my ($nick, $email) = $user->fields('name', 'email');
    my $theme = $user->field('prefs')->{theme};                 # inflated: JSON as Perl data
    my $json  = $user->raw_field('prefs');                      # as the database returned it
    my $year  = $user->field('created')->datetime_ref->year;    # a DateTime, built on first use

    is([$name, $nick, $email], ['Alice', 'Alice', 'alice@example.com'], "field and fields");
    is($theme,                 'dark',                                  "JSON inflates");
    like($json, qr/^\{"theme"\s*:\s*"dark"\}$/, "raw_field gives the JSON text");
    like($year, qr/^\d{4}$/,                    "a timestamp inflates to a DateTime");

    # Change a row
    # a copy: changing it changes neither the row nor the database
    my $prefs = $user->field('prefs');
    $prefs->{theme} = 'light';
    $user->update({
        prefs => $prefs,
        name  => 'Alice Smith',
    });

    # Only while email still holds what this row read. Undef otherwise.
    my $ok = $user->update({email => 'alice@example.org'}, cas => ['email']);

    $user->refresh;                 # read it again from the database
    my $deleted = $user->delete;    # 1

    is($user->field('prefs'), {theme => 'light'}, "update wrote the changed data");
    is($user->field('name'),  'Alice Smith',      "with the other changes");
    ok($ok, "compare-and-swap succeeded: nothing else changed the row");
    is($user->field('email'),                            'alice@example.org', "and its change was written");
    is($deleted,                                         1,                   "delete returns the count");
    is($orm->handle('users')->where({id => $id})->count, 0,                   "and the row is gone");

    # Fields not fetched yet
    {
        my $slim = $orm->handle('users')->fields(['name'])->where({name => 'Bob'})->only;

        my $email = $slim->field('email');    # fetched now

        is($email, 'bob@example.com', "a field not fetched is fetched when read");
    }

    # Follow foreign keys
    my $post   = $orm->handle('posts')->where({title => 'Hello'})->only;
    my $author = $post->follow_fk('users')->only;                                  # one row
    my @posts  = $author->follow_fk('posts')->all;                                 # many rows
    my @busy   = $author->follow_fk('posts')->and({views => {'>' => 100}})->all;

    is($author->field('name'),             'Bob',       "a single foreign key gives one row");
    is(scalar(@posts),                     2,           "a reverse one gives many");
    is([map { $_->field('title') } @busy], ['Popular'], "and narrows with and");

    # Insert linked rows
    {
        my $reply = $author->insert_fk('posts', {title => 'Reply'});                    # user_id is filled in
        my $more  = $author->insert_many_fk('posts', {title => 'A'}, {title => 'B'});

        is($reply->field('user_id'),                 $author->field('id'),         "insert_fk fills the link field");
        is([map { $_->field('user_id') } @$more],    [($author->field('id')) x 2], "insert_many_fk fills it in every row");
        is([sort map { $_->field('title') } @$more], ['A', 'B'],                   "and returns the rows");
        $orm->handle('posts')->where({id => [map { $_->field('id') } $reply, @$more]})->delete;
    }

    # Keys and canonical data
    $orm->clear_cache;

    my $pk   = $post->pk;          # {id => 1}
    my $data = $post->row_data;    # the row's data as a hashref: read it, never change it

    unless ($post->is_canon) {
        $post->refresh;
    }

    is($pk, {id => 1}, "pk");
    ok(!$orm->is_canon(posts => $data), "the old data is no longer canonical");
    ok($post->is_canon,                 "the refreshed row is");

    # Add your own methods
    {

        package My::User;
        use parent 'DBIx::QuickORM::Row';

        sub display_name {
            my $self  = shift;
            my $email = $self->field('email');
            return $self->field('name') . (defined($email) ? " <$email>" : '');
        }

        package main;

        my $orm = DBIx::QuickORM->new(
            credentials => \%credentials,
            row_classes => {users => 'My::User'},
        );

        my $who = $orm->insert(users => {name => 'Carol'})->display_name;

        is($who,                                                         'Carol',                 "the row class's method works");
        is($orm->handle('users')->find($bob->field('id'))->display_name, 'Bob <bob@example.com>', "on every row of the table");
    }
};

done_testing;
