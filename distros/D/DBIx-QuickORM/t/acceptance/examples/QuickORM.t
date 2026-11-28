# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM.pm. Whenever an example there
# changes, change its copy here to match: t/acceptance/Examples.t fails while any example has no copy
# in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);
    $db->connect->do($SCHEMA);

    # SYNOPSIS
    use DBIx::QuickORM;

    my $orm = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
    );

    my $bob = $orm->insert(users => {name => 'Bob'});
    my $row = $orm->find(users => $bob->field('id'));

    $bob->update({name => 'Robert'});

    my @roberts = $orm->handle('users')
        ->where({name => 'Robert'})
        ->all;

    $orm->txn(sub {
        $orm->insert(users => {name => 'Ann'});
        $orm->insert(users => {name => 'Cy'});
    });

    $bob->delete;

    is($row->field('name'),                                  'Bob',    "find read Bob before the update");
    is(scalar(@roberts),                                     1,        "the handle finds the updated row");
    is($bob->field('name'),                                  'Robert', "update changed it");
    is($orm->handle('users')->where({name => 'Ann'})->count, 1,        "the transaction inserted Ann");
    is($orm->handle('users')->where({name => 'Cy'})->count,  1,        "and Cy");
    ok($bob->was_deleted, "delete removed Bob");

    # The examples below start from Bob, renamed Robert, and no Ann or Cy.
    $orm->handle('users')->where({name => $_})->delete for qw/Ann Cy/;
    $bob = $orm->insert(users => {name => 'Robert'});

    # new
    {
        my $orm = DBIx::QuickORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
            omit         => {users => ['prefs']},    # selected only when asked for
            row_classes  => {posts => undef},        # posts come back as plain hashrefs
            retain_cache => 1,                       # keep rows cached until clear_cache()
        );

        is($orm->db_map->table('users')->{default_fields}, [qw/created email id name referred_by/], "omit sets the default fields");
        is($orm->retain_cache,                             1,                                       "retain_cache");
        my $post = $orm->insert(posts => {user_id => $bob->field('id'), title => 'Hi'});
        is(ref($post), 'HASH', "posts are hashrefs");
        $orm->delete_row(posts => $post);
    }

    # datetime_parsers
    {
        use DateTime::Format::Strptime;

        my $orm = DBIx::QuickORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
            datetime_parsers => [
                DateTime::Format::Strptime->new(pattern => '%d/%m/%Y %H:%M'),
                # epoch seconds
                sub { $_[0] =~ m/^\d+\z/ ? DateTime->from_epoch(epoch => $_[0]) : undef },
            ],
        );

        my $field = {affinity => 'string', type => 'timestamp'};
        my $type  = 'DBIx::QuickORM::Type::DateTime';
        is($type->inflate('03/02/2024 04:05', $field, $orm->connection)->datetime_ref->ymd, '2024-02-03', "the Strptime object reads its pattern");
        is($type->inflate('86400',            $field, $orm->connection)->datetime_ref->ymd, '1970-01-02', "and the code reference epoch seconds");
    }

    # clear_cache
    {
        my $id = $bob->field('id');

        my $user = $orm->find(users => $id);
        my $held = $orm->is_canon(users => $user);    # true: $user's data is the canonical copy

        $orm->clear_cache(users => $id);              # or clear_cache('users'), or clear_cache()
        my $still = $orm->is_canon(users => $user);   # false
        $user->refresh;                               # canonical again

        ok($held,           "a row found is canonical");
        ok(!$still,         "not once the cache forgets it");
        ok($user->is_canon, "and canonical again after refresh");
    }

    # CRUD operations
    {
        # a row object
        my $ann = $orm->insert(
            users => {
                name  => 'Ann',
                prefs => {theme => 'dark'},
            },
        );

        # row data: a hashref
        my $ben = $orm->insert(
            users => {name => 'Ben'},
            data  => 1,
        );

        $orm->insert(users => {name => 'Cy'});    # void: nothing read back

        # an arrayref of rows, or with count => 1, how many went in
        my $rows = $orm->insert_many(users => [{name => 'Di'}, {name => 'Ed'}]);
        my $n    = $orm->insert_many(
            users => [{name => 'Flo'}],
            count => 1,
        );

        $orm->update_row(users => $ann, {name => 'Anne'});    # updates the row object given

        my $fresh = $orm->update_row(
            users => $ben,
            {email => 'ben@example.com'},
            cas => ['email'],
        );

        my $again = $orm->refresh_row(users => {id => $ben->{id}});    # a row object, from the cache
        my $gone  = $orm->delete_row(users => $fresh);                 # 1

        # rows have the same operations as methods
        $ann->update({email => 'ann@example.com'});    # $orm->update_row(users => $ann, {...})
        $ann->refresh;                                 # $orm->refresh_row(users => $ann, cache => 0)
        $ann->delete;                                  # $orm->delete_row(users => $ann)

        isa_ok($ann, ['DBIx::QuickORM::Row'], "insert returns a row object");
        is(ref($ben),                 'HASH',            "data => 1 returns row data");
        is($rows->[1]->field('name'), 'Ed',              "insert_many returns the rows");
        is($n,                        1,                 "or the count");
        is($ann->field('name'),       'Anne',            "update_row updates the row object");
        is($fresh->field('email'),    'ben@example.com', "and returns a row for row data");
        ref_is($again->row_data, $fresh->row_data, "refresh_row uses the cache");
        is($gone,                                               1, "delete_row returns the count");
        is($ann->field('email'), 'ann@example.com', "the row method updates");
        ok($ann->was_deleted, "and deletes");
        is($orm->handle('users')->where({name => 'Cy'})->count, 1, "a void insert still inserts");
    }

    # CRUD operations: value markers
    {
        use DBIx::QuickORM::Value qw/raw inflated sql/;

        my $dee = $orm->insert(
            users => {
                name    => 'Dee',
                prefs   => raw('{"theme":"dark"}'),    # already JSON text: sent as is
                created => sql('now()'),               # literal SQL
            },
        );

        # raw => 1 for every value, but deflate this one
        my $eli = $orm->insert(
            users => {
                name  => 'Eli',
                prefs => inflated({theme => 'light'}),
            },
            raw => 1,
        );

        is($dee->raw_field('prefs'), '{"theme":"dark"}', "raw() sends one value as given");
        is($dee->field('prefs'),     {theme => 'dark'},  "and it inflates on read");
        isa_ok($dee->field('created'), ['DBIx::QuickORM::Type::DateTime::Lazy'], "sql() set the value the database computed");
        is($eli->raw_field('prefs'), '{"theme":"light"}', "inflated() deflates one value under raw => 1");
    }

    # Finding by primary key
    {
        my $id = $bob->field('id');

        my $user = $orm->find(users => $id);
        my $data = $orm->find(users => $id, data => 1);    # row data
        my $none = $orm->find(users => -1);                # undef

        is($user->field('name'), 'Robert', "find returns the row");
        is(ref($data),           'HASH',   "data => 1 returns row data");
        is($none,                undef,    "a missing key returns undef");
    }

    # Finding or inserting
    {
        my $gil = $orm->find_or_insert(
            users => {
                name  => 'Gil',
                email => 'gil@example.com',
            },
            by => ['email'],
        );
        my $same = $orm->find_or_insert(
            users => {email => 'gil@example.com'},
            by    => ['email'],
        );

        is($gil->field('name'), 'Gil', "find_or_insert inserts a missing row");
        ref_is($same->row_data, $gil->row_data, "and finds it the next time");
    }

    # Following foreign keys
    {
        my $id = $bob->field('id');

        my $post = $orm->insert(
            posts => {
                user_id => $id,
                title   => 'Hi',
            },
        );

        my $author = $orm->follow_fk(posts => $post,   'users')->only;
        my @posts  = $orm->follow_fk(users => $author, 'posts')->order_by('id')->all;

        # the same, as a row method: no table needed
        my $writer = $post->follow_fk('users')->only;

        is($author->field('name'),              'Robert', "a foreign key to one row");
        is([map { $_->field('title') } @posts], ['Hi'],   "and back to many");
        ref_is($writer->row_data, $author->row_data, "the row method follows the same link");
    }

    # Inserting linked rows
    {
        my $alice = $bob;

        my $post  = $orm->insert_fk(users => $alice, 'posts', {title => 'One'});
        my $posts = $orm->insert_many_fk(users => $alice, 'posts', {title => 'A'}, {title => 'B'});

        # the same, as row methods
        my $draft = $alice->insert_fk('posts', {title => 'Draft'});

        $alice->insert_fk('posts', link => {id => 'user_id'}, {title => 'Linked'});

        is($post->field('user_id'),              $alice->field('id'), "insert_fk fills the link from the row");
        is([map { $_->field('title') } @$posts], ['A', 'B'],          "insert_many_fk returns the rows");
        is($draft->field('user_id'),             $alice->field('id'), "the row method links to the row");
        $orm->handle('posts')->where({title => ['One', 'A', 'B', 'Draft', 'Linked']})->delete;
    }

    # Handles
    {
        $orm->insert_many(users => [map { +{name => "Extra $_"} } 1 .. 5]);    # ids past 10 for the query

        my @bobs = $orm->handle('users')
            ->where({name => 'Bob'})
            ->order_by('id')
            ->all;
        my @rows = $orm->handle(\['SELECT id, name FROM users WHERE id > ?', 10])->all;

        is(scalar(@bobs), 0, "Bob was renamed, so the table handle finds none");
        my @over = grep { $_->field('id') > 10 } $orm->handle('users')->all;
        ok(scalar(@over), "some ids are past 10");
        is(scalar(@rows), scalar(@over), "the SQL handle runs with its binds");
    }

    # Transactions
    {
        $orm->txn(sub {
            $orm->insert(users => {name => 'Outer'});
            eval {
                $orm->txn(sub {
                    $orm->insert(users => {name => 'Inner'});
                    die "undo only the inner work\n";
                });
            };
        });    # Outer is committed, Inner was rolled back with its savepoint

        my $count = $orm->txn(
            sub { $orm->handle('users')->count },    # the block's return value
            isolation => 'serializable',
            retry     => 3,
        );

        is($orm->handle('users')->where({name => 'Outer'})->count, 1, "the outer transaction committed");
        is($orm->handle('users')->where({name => 'Inner'})->count, 0, "the savepoint rolled back");
        is($count, $orm->handle('users')->count, "txn returns the block's value");
    }
};

done_testing;
