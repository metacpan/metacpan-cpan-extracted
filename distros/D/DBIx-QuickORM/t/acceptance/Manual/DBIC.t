# Test origin: AI
# This test runs copies of the DBIx::QuickORM code examples in lib/DBIx/QuickORM/Manual/DBIC.pm.
# Whenever an example there changes, change its copy here to match: t/acceptance/Examples.t fails
# while any example has no copy in an example test. The DBIx::Class examples on that page are not
# run (DBIx::Class is not a dependency). t/acceptance/Examples.t lists them in %SKIP.
use Test2::V0;
use lib 't/lib';

use DBI;
use File::Path qw/make_path/;
use File::Temp qw/tempdir/;

# The ROW METHODS section's DSL modules, written where Perl finds them, since an ORM class finds its
# table classes on disk.
my $LIB;

BEGIN {
    $LIB = tempdir(CLEANUP => 1);
    my %modules = (
        'My/ORM.pm' => <<'PERL',
package My::ORM;
use DBIx::QuickORM::DSL ':orm';

orm { tables 'My::Tables' };

1;
PERL
        'My/Tables/Users.pm' => <<'PERL',
package My::Tables::Users;
use DBIx::QuickORM::DSL qw/:table :row/;

table { name 'users' };
row { parent };

sub display_name {
    my $self = shift;
    return $self->field('name') . ' <' . $self->field('email') . '>';
}

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

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

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

    # DEFINING THE SCHEMA
    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        }
    );    # scans the tables, columns, keys, and types

    my $alice = $orm->insert(
        users => {
            name  => 'Alice',
            email => 'alice@example.com',
            prefs => {theme => 'dark'},
        }
    );
    my $post = $orm->insert(
        posts => {
            user_id => $alice->field('id'),
            title   => 'Hello',
        }
    );
    my $author = $post->follow_fk('users')->only;                 # the foreign key was scanned, not declared
    my $year   = $alice->field('created')->datetime_ref->year;    # a lazy DateTime, from the column's type

    is($author->field('name'), 'Alice', "the scanned foreign key links the post to its author");
    like($year, qr/^\d{4}$/, "the timestamp column inflates to a DateTime");

    {
        my $entry = $orm->insert(
            audit_log => {
                user_id => $alice->field('id'),
                action  => 'login',
            }
        );

        my $by = $entry->follow_fk('users', via => {user_id => 'id'})->only;

        is($by->field('name'), 'Alice', "via follows a key nobody declared");
        $entry->delete;
    }

    {
        my $logged = DBIx::QuickORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
            fks => {audit_log => {users => [{user_id => 'id'}]}},    # audit_log.user_id points at users.id
        );

        my $entry = $logged->insert(
            audit_log => {
                user_id => $alice->field('id'),
                action  => 'login',
            }
        );

        my $who = $entry->follow_fk('users')->only;
        my @log = $logged->find(users => $alice->field('id'))->follow_fk('audit_log')->all;

        is($who->field('name'),                'Alice',   "a key given with fks is followed like a scanned one");
        is([map { $_->field('action') } @log], ['login'], "both ways");
    }

    my $id = $alice->field('id');

    # CONNECTING
    {
        my $dbh = $db->connect;

        my $orm = DBIx::QuickORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            }
        );
        # a new handle each call
        $orm = DBIx::QuickORM->new(
            connect => sub { DBI->connect($dsn, $user, $pass, {RaiseError => 1}) },
        );
        $orm = DBIx::QuickORM->new(dbh => $dbh);    # a handle you already have

        ref_is($orm->connection->dbh, $dbh, "the dbh form uses the handle it was given");
        ok($orm->connection->dbh->{RaiseError}, "with RaiseError on");
        like(dies { $orm->handle('users')->aside }, qr/given a 'dbh'/, "and aside croaks with it");
    }

    # CREATE, READ, UPDATE, DELETE
    {
        my $alice = $orm->insert(users => {name => 'Alice'});
        my $found = $orm->find(users => $alice->field('id'));
        # undef when there is none, and croaks on more than one
        my $bob = $orm->handle('users')->where({email => 'bob@example.com'})->only;

        my $name = $alice->field('name');
        $alice->update({name => 'Alice Smith'});    # written now
        $alice->refresh;
        $alice->delete;

        is($found->field('name'),                                        'Alice', "find looks the row up by primary key");
        is($bob,                                                         undef,   "only is undef when nothing matches");
        is($name,                                                        'Alice', "field reads a field");
        is($orm->handle('users')->where({name => 'Alice Smith'})->count, 0,       "update wrote at once, and delete removed the row");
        $orm->insert(users => {name => 'Bob'});
        like(dies { $orm->handle('users')->only }, qr/found more than one row/, "only croaks on more than one row");

        my $carol = $orm->find_or_insert(
            users => {
                name  => 'Carol',
                email => 'carol@example.com',
            },
            by => ['email'],
        );
        my $again = $orm->find_or_insert(users => {name => 'Carol', email => 'carol@example.com'}, by => ['email']);
        is($again->field('id'), $carol->field('id'), "find_or_insert inserts once, then finds");

        my $draft = $orm->vivify(users => {name => 'Draft'});    # not in the database yet
        $draft->modify({email => 'draft@example.com'});
        $draft->insert;
        my $stored = $draft->is_in_db;                           # true

        is($stored,                                                              1,                   "a vivified row is in the database once inserted");
        is($orm->find(users => $draft->field('id'), cache => 0)->field('email'), 'draft@example.com', "with what modify set");
        $_->delete for $carol, $draft;
    }

    # QUERIES
    $orm->insert_many(posts => [map { {user_id => $id, title => "Hello $_", views => $_ + 5} } 1 .. 25]);
    {
        my $h = $orm->handle('posts')->where({views => {'>' => 5}})->order_by({-desc => 'views'})->limit(10)->offset(20);
        # and() adds to the condition, but where() replaces it
        my $hellos = $h->and({title => {-like => 'Hello%'}});

        my $count = $h->count;    # ignores limit and offset: every matching row
        my @all   = $h->all;      # runs the query and fetches every row
        while (my $post = $h->next) {
            my $title = $post->field('title');
        }
        my $first = $h->first;
        my $it    = $h->iter;     # an independent cursor over the same rows

        is($h->next,                  undef, "next on the handle walked the page");
        is($it->next->field('views'), 10,    "iter starts at the first row");

        is($count,                              25,               "count counts every match, ignoring limit and offset");
        is([map { $_->field('views') } @all],   [10, 9, 8, 7, 6], "limit and offset page the ordered rows");
        is($first->field('views'),              10,               "first is the first row of the page");
        is($hellos->count,                      25,               "and() keeps the first condition");
        is($hellos->where({views => 0})->count, 1,                "where() replaces it: the views > 5 condition is gone");

        sub popular {
            my ($posts) = @_;
            return $posts->and({views => {'>' => 5}});
        }

        my $n = popular($hellos)->count;

        is($n, 25, "a sub narrows the handle it is given");

        use DBIx::QuickORM::Value qw/sql/;

        my $titled = $h->and("title <> ''");
        my $short  = $h->and(sql('length(title) < ?', 8));

        is($titled->count,                                                                    25, "a plain string is SQL as written");
        is($short->count,                                                                     9,  "sql() takes binds");
        is($orm->handle('posts')->where({views => {'<' => 0}})->and("1 = 1 OR 1 = 1")->count, 0,  "and() parenthesizes a string, so its OR stays grouped");
    }

    # LITERAL SQL
    {
        my $post_id = $orm->insert(posts => {user_id => $id, title => 'Literal'})->field('id');

        use DBIx::QuickORM::Value qw/sql/;

        my $ida = $orm->insert(users => {name => 'Ida', created => sql('now()')});
        $orm->handle('posts')->where({id => $post_id})->update({views => sql('views + ?', 2)});

        like($ida->field('created')->datetime_ref->year, qr/^\d{4}$/, "sql() is sent as SQL in an insert");
        is($orm->find(posts => $post_id, cache => 0)->field('views'), 2, "and in an update, with binds");
        $orm->handle('posts')->where({id => $post_id})->delete;
        $ida->delete;
    }

    # PLAIN HASHREFS
    {
        my @data  = $orm->handle('posts')->data_only->all;    # row_class(undef)
        my $title = $data[0]->{title};

        ref_ok($data[0], 'HASH', "data_only gives hashrefs");
        like($title, qr/^Hello/, "with the row's data");
    }

    # RELATIONSHIPS
    {
        # single: user_id reaches the users primary key
        my $author = $post->follow_fk('users')->only;
        my @posts  = $author->follow_fk('posts')->all;                 # multi: any number of posts
        my $h      = $author->follow_fk('posts');                      # a handle
        my $busy   = $h->and({views => {'>' => 5}})->count;
        my $new    = $author->insert_fk('posts', {title => 'New'});    # user_id is filled in

        is($new->field('user_id'), $author->field('id'), "insert_fk links the new post to the author");
        $new->delete;
        my $more = $author->insert_many_fk('posts', {title => 'A'}, {title => 'B'});
        is(scalar(@$more), 2, "insert_many_fk inserts several");
        $_->delete for @$more;

        is($author->field('name'), 'Alice', "follow_fk reaches the author");
        is(scalar(@posts),         26,      "and every post of the author");
        is($h->state,              'multi', "a has_many-like key gives a multi handle");
        is($busy,                  25,      "which and() narrows");
    }

    # JOINS AND PREFETCH
    {
        my @pairs = $orm->handle('posts')->join('users')->where({'users.name' => 'Alice'})->order_by('posts.id')->all;

        for my $pair (@pairs) {
            my $title  = $pair->row('posts')->field('title');
            my $author = $pair->row('users')->field('name');
        }

        is(scalar(@pairs),                          26,      "one join row per post");
        is($pairs[0]->row('posts')->field('title'), 'Hello', "each with its post");
        is($pairs[0]->row('users')->field('name'),  'Alice', "and its author");
        ref_is($pairs[0]->row('users'), $pairs[1]->row('users'), "the same user row object in every row");
    }

    # INFLATION
    {
        my $year  = $alice->field('created')->datetime_ref->year;    # a lazy DateTime
        my $theme = $alice->field('prefs')->{theme};                 # JSON as Perl data
        my $text  = $alice->raw_field('created');                    # as the database returned it

        my $plain = DBIx::QuickORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
            types => {users => {prefs => undef}},    # prefs stays text
        );

        like($year, qr/^\d{4}$/, "created inflates to a DateTime");
        is($theme, 'dark', "prefs inflates to Perl data");
        like($text,                                      qr/^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d/, "raw_field gives the database's text");
        like($plain->find(users => $id)->field('prefs'), qr/^\{.*"theme".*\}$/,               "with the type removed, prefs is JSON text");
    }

    # TRANSACTIONS
    {
        $orm->txn(sub {
            $orm->insert(users => {name => 'Dave'});
        });    # commits on return. An exception rolls back and is rethrown

        my $txn = $orm->txn;
        $orm->insert(users => {name => 'Eve'});
        # or rollback. Unfinished when it goes out of scope: rolled back, with a warning
        $txn->commit;

        is($orm->handle('users')->where({name => ['Dave', 'Eve']})->count, 2, "both forms committed");
        like(
            dies {
                $orm->txn(sub { $orm->insert(users => {name => 'Oops'}); die "boom\n" })
            },
            qr/^boom$/,
            "an exception in the block is rethrown"
        );
        is($orm->handle('users')->where({name => 'Oops'})->count, 0, "after rolling back");
        like(warnings { my $dropped = $orm->txn; $orm->insert(users => {name => 'Dropped'}) }, [match qr/rolled back/], "an unfinished transaction object warns");
        is($orm->handle('users')->where({name => 'Dropped'})->count, 0, "and is rolled back");
    }

    # BULK WRITES
    {
        $orm->insert_many(users => [{name => 'Fay'}, {name => 'Gus'}]);    # void context: nothing read back
        my $changed = $orm->handle('posts')->where({views => 0})->update({views => 1});
        my $removed = $orm->handle('posts')->where({views => {'<' => 0}})->delete;

        is($orm->handle('users')->where({name => ['Fay', 'Gus']})->count, 2,      "a void insert_many inserts");
        is([$changed, $removed],                                          [1, 0], "bulk writes return counts");
        ok(!$post->is_canon, "a bulk update leaves the rows you hold not canonical");
        like(dies { $post->update({title => 'Changed'}) }, qr/not canon/, "so writing through one croaks");
        is($post->refresh->field('views'), 1, "until refresh, which reads the new data");
    }

    # COUNTS AND AGGREGATES
    {
        use DBIx::QuickORM::Value qw/sql/;

        my $n   = $orm->handle('posts')->count;
        my $top = $orm->handle('posts')->fields({top => [max => 'views']})->only->field('top');

        my @per_user = $orm->handle('posts')->group_by('user_id')->fields({
            user_id => 'user_id',
            posts   => [count => '*'],
            views   => sql('SUM(views)'),    # any SQL
        })->order_by('user_id')->all;
        my $posts = $per_user[0]->field('posts');

        is($n,                           26,                         "count counts the rows");
        is($top,                         30,                         "a computed column holds the aggregate");
        is(scalar(@per_user),            1,                          "one group per user with posts");
        is($posts,                       26,                         "with the group's count");
        is($per_user[0]->field('views'), 1 + 25 * 5 + (25 * 26) / 2, "and a sql() column");
    }

    # ONE COPY PER ROW
    {
        my $first = $orm->find(users => $id);

        # a second object over the same canonical copy of the data
        my $second = $orm->find(users => $id);

        $first->update({name => 'Ann'});

        # still the name $second read
        my $old = $second->field('name');

        # false: $first's write superseded the data $second holds
        my $current = $second->is_canon;

        # croaks: $second is not canonical
        my $ok = eval { $second->update({email => 'b@example.com'}); 1 };

        # Ann, and canonical again
        $second->refresh;
        $second->update({email => 'b@example.com'});

        ok($first != $second, "two row objects");
        is($old, 'Alice', "the second still holds the name it read");
        ok(!$current, "and is not canonical after the first one's write");
        ok(!$ok,      "so its write croaks");
        is($second->field('name'),  'Ann',           "refresh takes the canonical data");
        is($second->field('email'), 'b@example.com', "and the write goes through");
    }

    # ROW METHODS
    {

        package My::User;
        use parent 'DBIx::QuickORM::Row';

        sub display_name {
            my $self = shift;
            return $self->field('name') . ' <' . $self->field('email') . '>';
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

        my $label = $orm->find(users => $id)->display_name;

        is($label, 'Ann <b@example.com>', "rows of the table get the class's methods");
        isa_ok($orm->find(users => $id), ['My::User', 'DBIx::QuickORM::Row'], "as a subclass of the default row class");

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

        isa_ok($named->find(users => $id), ['My::Rows::Users'], "row_namespace names the class after the table");

        require My::ORM;
        my $dsl = My::ORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
        );
        my $ann = $dsl->find(users => $id);
        isa_ok($ann, ['My::Tables::Users', 'DBIx::QuickORM::Row'], "tables loads the namespace's table classes as row classes");
        is($ann->display_name, 'Ann <b@example.com>', "with their methods");
    }

    # DEPLOYING
    {
        my $dbh               = $db->connect;
        my @create_statements = ("CREATE TABLE deployed (id SERIAL PRIMARY KEY)");

        $dbh->do($_) for @create_statements;           # your own SQL, or your migration tool
        my $orm = DBIx::QuickORM->new(dbh => $dbh);    # scans what is there

        ok($orm->db_map->table('deployed'), "the ORM scans the tables the SQL created");
    }

    # WHAT YOU WRITE YOURSELF
    {
        my $zed = $orm->txn(sub {
            my $zed = $orm->insert(users => {name => 'Zed'});
            $zed->insert_many_fk('posts', {title => 'One'}, {title => 'Two'});
            return $zed;
        });

        is($zed->field('name'),             'Zed', "txn returns what the block returns");
        is($zed->follow_fk('posts')->count, 2,     "with the related rows inserted");

        my $ok = eval { $zed->delete; 1 };
        ok(!$ok, "the database refuses to delete a referenced row");
        like($@, qr/violates foreign key constraint/, "with a foreign key violation");

        $orm->txn(sub {
            $zed->refresh;    # read before the transaction, so not canonical in it
            $zed->follow_fk('posts')->delete;
            $zed->delete;
        });

        is($orm->handle('users')->where({name => 'Zed'})->count, 0, "deleting the posts first lets the user go");
    }
};

done_testing;
