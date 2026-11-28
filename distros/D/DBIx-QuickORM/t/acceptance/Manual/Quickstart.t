# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Quickstart.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBI;
use File::Path qw/make_path/;
use File::Temp qw/tempdir/;

# The DEFINING THE ORM IN PACKAGES modules, written where Perl finds them, since an ORM class finds
# its table classes on disk.
my $LIB;

BEGIN {
    $LIB = tempdir(CLEANUP => 1);
    my %modules = (
        'My/ORM.pm' => <<'PERL',
package My::ORM;
use DBIx::QuickORM::DSL ':orm';

orm {
    tables 'My::Tables';    # the modules directly under My::Tables
};

1;
PERL
        'My/Tables/Users.pm' => <<'PERL',
package My::Tables::Users;
use DBIx::QuickORM::DSL qw/:table :row/;

table {
    name 'users';
    omit qw/prefs/;    # selected only when asked for
};

row { parent };

sub display_name { $_[0]->field('name') . ' <' . $_[0]->field('email') . '>' }

1;
PERL
    );

    for my $file (sort keys %modules) {
        make_path("$LIB/" . ($file =~ s{/[^/]+$}{}r));
        open(my $fh, '>', "$LIB/$file") or die "Could not write $file: $!";
        print $fh $modules{$file};
        close($fh);
    }
}

use lib $LIB;

use DBIx::QuickORM::Test::Examples;

my $polls = 0;
sub do_something_else { $polls++ }

do_for_pg {
    my ($db) = @_;
    my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);
    $db->connect->do($SCHEMA);
    $db->connect->do(<<'SQL');
CREATE TABLE audit_log (
    id      SERIAL PRIMARY KEY,
    user_id INTEGER,
    action  TEXT NOT NULL
);
SQL

    # CONNECTING
    {
        use DBIx::QuickORM;

        my $orm = DBIx::QuickORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
        );

        ok($orm->connection->dbh->ping, "credentials connect");
    }
    {
        my $orm = DBIx::QuickORM->new(
            connect => sub { DBI->connect($dsn, $user, $pass, {RaiseError => 1}) },
        );

        ok($orm->connection->dbh->ping, "a connect sub connects");
    }
    {
        my $dbh = $db->connect;

        my $orm = DBIx::QuickORM->new(dbh => $dbh);

        ref_is($orm->connection->dbh, $dbh, "the ORM uses the handle it was given");
        like(dies { $orm->handle('users')->aside }, qr/given a 'dbh'/, "and aside croaks with it");
    }

    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
    );

    # CREATE, READ, UPDATE, DELETE, FIND
    my $alice = $orm->insert(
        users => {
            name  => 'Alice',
            email => 'alice@example.com',
            prefs => {theme => 'dark'},
        }
    );

    my $id    = $alice->field('id');                             # the key the database generated
    my $theme = $alice->field('prefs')->{theme};                 # JSON comes back as Perl data
    my $json  = $alice->raw_field('prefs');                      # '{"theme":"dark"}': the value as stored
    my $year  = $alice->field('created')->datetime_ref->year;    # timestamps come back as lazy DateTimes

    my $found = $orm->find(users => $id);                        # by primary key

    # undef: no such user
    my $bob = $orm->handle('users')->where({email => 'bob@example.com'})->only;

    $alice->update({name => 'Alice Smith'});
    $alice->refresh;                                             # read it again from the database

    my $temp = $orm->insert(users => {name => 'Temp'});
    $temp->delete;

    is($id,    1,                  "insert returns the row with its new key");
    is($theme, 'dark',             "JSON inflates");
    is($json,  '{"theme":"dark"}', "raw_field reads the value as stored");
    like($year, qr/^\d{4}$/, "a timestamp inflates to a DateTime");
    is($found->field(q{email}),                               q{alice@example.com}, "find looks a row up by primary key");
    is($bob,                                                  undef,                "only is undef when nothing matches");
    is($alice->field('name'),                                 'Alice Smith',        "update changes the row");
    is($orm->handle('users')->where({name => 'Temp'})->count, 0,                    "delete removes the row");

    my $gil = $orm->find_or_insert(
        users => {
            name  => 'Gil',
            email => 'gil@example.com',
        },
        by => ['email'],    # the fields to find by (the primary key by default)
    );

    my $same = $orm->find_or_insert(users => {name => 'Other', email => 'gil@example.com'}, by => ['email']);
    is($same->field('name'), 'Gil',             "find_or_insert finds the row it inserted");
    is($same->field('id'),   $gil->field('id'), "the same row, not a second insert");
    $gil->delete;

    use DBIx::QuickORM::Value qw/raw/;

    my $hal = $orm->insert(
        users => {
            name  => 'Hal',
            prefs => raw('{"theme":"light"}'),    # already JSON text: sent as is
        }
    );

    is($hal->raw_field('prefs'), '{"theme":"light"}', "raw() sends one value as given");
    is($hal->field('prefs'),     {theme => 'light'},  "and it inflates on read");
    $hal->delete;

    # HANDLES
    my @numbered = map { sprintf('User %02d', $_) } 1 .. 22;
    $orm->insert(users => {name => $_}) for 'Alice Jones', 'Zed', @numbered;

    my $users  = $orm->handle('users');
    my $sorted = $users->order_by('name');                       # $users is unchanged
    my $page   = $sorted->limit(10)->offset(20);
    my $alices = $users->where({name => {-like => 'Alice%'}});

    my $count = $users->count;
    my @all   = $sorted->all;
    my @data  = $sorted->data_only->all;                         # plain hashrefs, not row objects

    is($users->order_by,                              undef,                                               "a modifier leaves the handle unchanged");
    is([map { $_->field('name') } @all],              ['Alice Jones', 'Alice Smith', @numbered, 'Zed'],    "order_by sorts");
    is([map { $_->field('name') } $page->all],        ['User 19', 'User 20', 'User 21', 'User 22', 'Zed'], "limit and offset page: rows 21 on");
    is([sort map { $_->field('name') } $alices->all], ['Alice Jones', 'Alice Smith'],                      "where filters");
    is($count,                                        25,                                                  "count counts");
    is($data[0],                                      hash { field name => 'Alice Jones'; etc },           "data_only gives hashrefs");
    like(dies { $users->order_by('name'); 1 }, qr/void context/, "a modifier croaks in void context");

    $users->where({name => {-like => 'User %'}})->delete;

    my $carol = $users->insert({name => 'Carol'});
    my $again = $users->find($carol->field('id'));
    $users->update_row($carol, {email => 'carol@example.com'});
    $users->delete_row($carol);

    is($again->field('name'),                   'Carol',             "find returns the row");
    is($carol->field('email'),                  'carol@example.com', "update_row updates the given row");
    is($users->where({name => 'Carol'})->count, 0,                   "delete_row deletes it");

    my $added   = $users->insert_many([{name => 'Dan'}, {name => 'Erin'}]);    # an arrayref of rows
    my $renamed = $users->where({name => 'Dan'})->update({name => 'Daniel'});
    my $removed = $users->where({name => 'Erin'})->delete;

    is([scalar(@$added), $renamed, $removed],    [2, 1, 1], "insert_many returns the rows, bulk writes counts");
    is($users->where({name => 'Daniel'})->count, 1,         "the bulk update happened");

    # ITERATING
    $orm->insert(posts => {user_id => $alice->field('id'), title => $_}) for 'Hello', 'Again';

    my $posts = $orm->handle('posts')->order_by('id');
    while (my $row = $posts->next) {
        my $title = $row->field('title');
    }

    my $it = $posts->iter;    # its own position over the same rows
    $posts->clear;            # forget the rows, so the next read queries again

    is($posts->next->field('title'), 'Hello', "after clear the handle starts over");
    is($it->next->field('title'),    'Hello', "iter has its own position");
    ok($posts->iter != $posts->iter, "iter returns a new iterator each call");
    $it->reset;
    is([map { $_->field('title') } $it->all], ['Hello', 'Again'], "in order");

    my $post   = $posts->first;
    my $author = $post->follow_fk('users')->only;    # single: the key points at one row
    my @posts  = $alice->follow_fk('posts')->all;    # multi: any number of rows

    is($author->field('name'), 'Alice Smith', "a single handle gives the one row");
    is(scalar(@posts),         2,             "a multi handle gives every row");
    like(dies { $alice->follow_fk('posts')->only }, qr/cannot be used on a multi-row iterator/, "only croaks on a multi handle");

    my $entry = $orm->insert(audit_log => {user_id => $alice->field('id'), action => 'login'});
    my $who   = $entry->follow_fk('users', via => {user_id => 'id'})->only;                       # Alice

    is($who->field('name'), 'Alice Smith', "via follows fields with no key");

    # JOINS
    $users->where({name => 'Zed'})->update({referred_by => $alice->field('id')});
    my @pairs = $orm->handle('posts')->join('users')->where({'users.name' => 'Alice Smith'})->all;

    for my $pair (@pairs) {
        my $title  = $pair->row('posts')->field('title');
        my $author = $pair->row('users')->field('name');
    }

    my @everyone = $orm->handle('users')->left_join('posts')->all;

    my @referred = $orm->handle('users')->join(
        'users',
        as   => 'referrer',
        link => {referred_by => 'id'},
    )->order_by('referrer.name')->all;

    for my $pair (@referred) {
        my $who = $pair->row('users')->field('name');
        my $by  = $pair->row('referrer')->field('name');
    }

    is([map { [$_->row('users')->field('name'), $_->row('referrer')->field('name')] } @referred], [['Zed', 'Alice Smith']], "a self join pairs each referred user with the referrer, known by its alias");

    is([map { $_->row('users')->field('name') } @pairs], ['Alice Smith', 'Alice Smith'], "the join matched both posts");
    is(scalar(grep { !$_->row('posts') } @everyone),     3,                              "users without posts have no post row");
    is(scalar(grep { $_->row('posts') } @everyone),      2,                              "and a user with two posts appears twice");

    # AGGREGATES
    my @stats = $orm->handle('posts')->group_by('user_id')->fields({
        user_id => 'user_id',
        posts   => [count => '*'],              # COUNT(*)
        titles  => \'COUNT(DISTINCT title)',    # or any SQL
        views   => [sum => 'views'],
    })->order_by('user_id')->all;

    for my $stat (@stats) {
        my $count  = $stat->field('posts');
        my $poster = $stat->follow_fk('users')->only;    # user_id keeps its foreign key
    }

    is(scalar(@stats),                                     1,             "one group per user with posts");
    is($stats[0]->field('posts'),                          2,             "counted");
    is($stats[0]->follow_fk('users')->only->field('name'), 'Alice Smith', "and its user_id follows to the user");
    is($stats[0]->field('views'),                          0,             "sum adds the views");
    is($stats[0]->field('titles'),                         2,             "an SQL column");

    # TRANSACTIONS
    $orm->txn(sub {
        my $dave = $orm->insert(users => {name => 'Dave'});
        $orm->insert(
            posts => {
                user_id => $dave->field('id'),
                title   => 'First post',
            }
        );
    });    # commits when the block returns. An exception rolls back and is rethrown

    my $txn = $orm->txn;
    $orm->insert(users => {name => 'Nobody'});
    $txn->rollback;    # or $txn->commit

    is($users->where({name => 'Dave'})->count, 1, "the block committed");

    like(
        dies {
            $orm->txn(sub { $orm->insert(users => {name => 'Oops'}); die "boom\n" })
        },
        qr/^boom$/,
        "an exception in the block is rethrown",
    );
    is($users->where({name => 'Oops'})->count,   0, "after rolling the block back");
    is($users->where({name => 'Nobody'})->count, 0, "the rollback undid the insert");

    {
        my $post_id = $post->field('id');
        my $views   = sub { $db->connect->selectrow_array("SELECT views FROM posts WHERE id = $post_id") };

        $orm->txn(
            sub {
                $post->refresh;    # $post was read before the transaction
                $post->update({views => 2});
            },
            isolation => 'serializable',
            retry     => 3,
        );

        is($views->(),            2, "refresh, then update, wrote the row inside the transaction");
        is($post->field('views'), 2, "and the row has the change");

        like(
            dies {
                $orm->txn(sub { $post->update({views => 5}) })
            },
            qr/is not canon \(not the ORM's current copy/,
            "a plain update of a row read before the transaction croaks there"
        );
        is($views->(), 2, "leaving the row alone");
    }

    # COMPARE-AND-SWAP
    # cas_update writes only while views still holds the value this row read, and
    # returns undef when it changed elsewhere first: read the row again and retry.
    while (1) {
        last if $post->cas_update({views => $post->field('views') + 1});
        $post->refresh;
    }

    is($post->field('views'), 3, "the loop increments views once while nothing else writes the row");

    {
        # Another writer sets views as the first cas_update runs: that one fails, the refresh reads 7, the retry writes 8.
        my $other   = $db->connect;
        my $post_id = $post->field('id');
        my $tries   = 0;
        my $watch   = on_execute { $other->do("UPDATE posts SET views = 7 WHERE id = $post_id") if $_[0] =~ m/^UPDATE/ && !$tries++ };

        # cas_update writes only while views still holds the value this row read, and
        # returns undef when it changed elsewhere first: read the row again and retry.
        while (1) {
            last if $post->cas_update({views => $post->field('views') + 1});
            $post->refresh;
        }
        undef $watch;

        is($post->field('views'),                                                  8, "the loop ends once this process is the one that incremented views");
        is($other->selectrow_array("SELECT views FROM posts WHERE id = $post_id"), 8, "and the database agrees");
    }

    $post->update({views => 10}, auto_cas => 1);

    is($post->field('views'), 10, "auto_cas updates while the changed fields still hold what the row read");

    $db->connect->do("UPDATE posts SET views = 3 WHERE id = " . $post->field('id'));
    is($post->update({views => 10}, auto_cas => 1), undef, "auto_cas fails once a changed field changed elsewhere");
    is($post->refresh->field('views'),              3,     "and leaves the row alone");
    $post->update({views => 10});

    $orm->txn(sub {
        $post->cas_update({views => 11}) or die "Changed elsewhere\n";
    });

    is($post->field('views'), 11, "cas_update writes a row read before the transaction while the database matches");
    $db->connect->do("UPDATE posts SET views = 4 WHERE id = " . $post->field('id'));
    like(
        dies {
            $orm->txn(sub { $post->cas_update({views => 12}) or die "Changed elsewhere\n" })
        },
        qr/^Changed elsewhere/,
        "and returns undef once it changed elsewhere"
    );
    is($post->field('views'), 11, "leaving the row alone");
    $post->refresh->update({views => 10});

    # ASYNC, ASIDE, AND FORKED QUERIES
    my $later = $orm->handle('posts')->async->iter;    # starts the query and returns at once

    do_something_else() until $later->ready;

    # waits for the rows when they are not there yet
    my @fetched = $later->all;

    is(scalar(@fetched), 3, "an async query returns its rows");

    my $aside  = $orm->handle('users')->aside->iter;     # on a second connection
    my $forked = $orm->handle('users')->forked->iter;    # in a child process
    my @found  = ($aside->all, $forked->all);

    is(scalar(@found), 2 * $users->count, "aside and forked queries return their rows");

    # DEFINING THE ORM IN PACKAGES
    {
        my $id = $alice->field('id');

        use My::ORM;

        my $app = My::ORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
        );

        my $label = $app->find(users => $id)->display_name;    # a My::Tables::Users row

        is($label, 'Alice Smith <alice@example.com>', "tables loads the namespace's table classes as row classes");
        isa_ok($app->find(users => $id), ['My::Tables::Users', 'DBIx::QuickORM::Row'], "with the default row class as parent");
        is($app->db_map->table('users')->{default_fields}, [qw/created email id name referred_by/], "the table block's omit applies");
    }
    {
        {

            package My::Rows::Users;
            use parent 'DBIx::QuickORM::Row';
        }

        my $named = DBIx::QuickORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
            row_namespace => 'My::Rows',
        );

        isa_ok($named->find(users => $alice->field('id')), ['My::Rows::Users'],     "row_namespace names the class after the table");
        isa_ok($named->handle('posts')->first,             ['DBIx::QuickORM::Row'], "and a table without a module keeps the default row class");
        ok(!$named->handle('posts')->first->isa('My::Rows::Users'), "not another table's class");
    }

    # FORKING
    my $parent = $orm->connection;

    my $pid = fork // die "Could not fork: $!";
    unless ($pid) {
        my $count = $orm->handle('users')->count;    # the ORM reconnects in the child by itself
        exit($count ? 0 : 1);
    }
    waitpid($pid, 0);

    is($?, 0, "the child queried through its own connection");
    ref_is($orm->connection, $parent, "and the parent kept its own");
    ok($orm->connection->dbh->ping, "which still works");
};

done_testing;
