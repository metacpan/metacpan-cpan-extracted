# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Handle.pm. Whenever an example
# there changes, change its copy here to match: t/acceptance/Examples.t fails while any example has
# no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

my $polls = 0;
sub do_something_else { $polls++ }

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);

    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    my $alice = $orm->insert(users => {name => 'Alice', email => 'alice@example.com'});
    my $id    = $alice->field('id');
    $orm->insert(users => {name    => 'Amy'});
    $orm->insert(users => {name    => 'Bob', email => 'bob@example.com'});
    $orm->insert(posts => {user_id => $id, title => "Hello $_", views => $_ * 10}) for 0 .. 2;

    # SYNOPSIS
    {
        my $h = $orm->handle('users')->where({name => {-like => 'A%'}})->order_by('name')->limit(10);

        my $n   = $h->count;
        my @all = $h->all;

        my $user = $orm->handle('users')->find($id);
        $orm->handle('posts')->where({views => 0})->delete;

        is($n,                               2,                "count");
        is([map { $_->field('name') } @all], ['Alice', 'Amy'], "all");
        is($user->field('name'),             'Alice',          "find");
        is($orm->handle('posts')->count,     2,                "delete");
    }

    # EXAMPLES: Filter, sort, and page
    {
        # Two A names a day with an email (Abe and Ann), and on the same days rows the filter drops: an A
        # name without one (Ada) and a B name (Ben). With Alice (created now) first, 45 rows match, and
        # rows 41 to 45 are the last page.
        $db->connect->do(q{
            INSERT INTO users (name, email, created)
            SELECT v.n || ' ' || i, CASE WHEN v.e THEN lower(v.n) || i || '@example.com' END, timestamp '2000-01-01' + i * interval '1 day'
              FROM generate_series(1, 22) AS i, (VALUES ('Ann', true), ('Abe', true), ('Ada', false), ('Ben', true)) AS v(n, e)
        });

        my @page = $orm->handle('users')->where({
            name  => {-like => 'A%'},
            email => {'!='  => undef},
        })->order_by([{-desc => 'created'}, 'name'])->limit(20)->offset(40)->all;

        is([map { $_->field('name') } @page], ['Ann 3', 'Abe 2', 'Ann 2', 'Abe 1', 'Ann 1'], "the filtered rows, newest first and then by name, from row 41");

        $db->connect->do("DELETE FROM users WHERE created < '2001-01-01'");
    }

    # EXAMPLES: Narrow or widen a condition
    {
        my $alice   = $orm->handle('users')->where({name => 'Alice'});
        my $emailed = $alice->and({email => {'!=' => undef}});           # both conditions
        my $either  = $alice->or({name => 'Bob'});                       # either condition
        my $bob     = $alice->where({name => 'Bob'});                    # where replaces the condition

        is([map { $_->field('name') } $emailed->all],                      ['Alice'],        "and");
        is([sort map { $_->field('name') } $either->all],                  ['Alice', 'Bob'], "or");
        is([map { $_->field('name') } $bob->all],                          ['Bob'],          "where");
        is([map { $_->field('name') } $alice->and({email => undef})->all], [],               "and needs both");
    }

    # EXAMPLES: Compare with SQL
    {
        use DBIx::QuickORM::Value qw/sql/;

        my @old = $orm->handle('users')->where({created => {'<' => sql("now() - interval '30 days'")}})->all;

        is(\@old, [], "an sql() marker in a where");
    }

    # EXAMPLES: Read only some fields
    {
        $orm->clear_cache;

        my @users = $orm->handle('users')->fields(['name'])->all;    # name, plus the primary key

        # a field not fetched loads on first read
        my $email = $users[0]->field('email');

        ok(!exists($users[1]->row_data->{email}), "only the fields asked for are fetched");
        ok(exists($users[0]->row_data->{email}),  "a missing field loads when read");
    }

    # EXAMPLES: Get plain hashrefs instead of row objects
    {
        my @data = $orm->handle('users')->data_only->all;
        my $name = $data[0]->{name};

        is(ref($data[0]), 'HASH', "rows are hashrefs");
        ok(length($name), "holding the row data");
    }

    # EXAMPLES: Query with your own SQL
    {
        $orm->insert(users => {name => 'Alice'});

        my $dupes = $orm->handle(
            \['SELECT name, COUNT(*) AS n FROM users GROUP BY name HAVING COUNT(*) > ?', 1],
        );
        my @dupes = $dupes->all;
        my @named = $dupes->where({name => 'Alice'})->all;    # the query becomes a subquery

        is([map { [$_->field('name'), $_->field('n')] } @dupes], [['Alice', 2]], "the query runs as written");
        is(scalar(@named),                                       1,              "and narrows as a subquery");
    }

    # EXAMPLES: Insert many rows and get them back
    {
        my $posts = $orm->handle('posts')->insert_many(
            [
                map {
                    +{
                        user_id => $id,
                        title   => "Post $_",
                    }
                } 1 .. 3
            ],
        );    # an arrayref of the new rows

        is([map { $_->field('title') } @$posts], ['Post 1', 'Post 2', 'Post 3'], "insert_many gives the rows");
        ok($posts->[0]->is_canon, "canonical");
    }

    # EXAMPLES: Loop over the same rows twice at once
    {
        my $h = $orm->handle('posts')->order_by('id');

        my @pairs;
        my $outer = $h->iter;
        while (my $left = $outer->next) {
            my $inner = $h->iter;    # the same rows, no second query
            while (my $right = $inner->next) {
                push @pairs => [$left->field('id'), $right->field('id')];
            }
        }

        is(scalar(@pairs), 25, "every pair of the five posts");
    }

    # Modifiers
    {
        my $users  = $orm->handle('users');
        my $recent = $users->order_by({-desc => 'created'})->limit(5);    # $users is unchanged

        # 5: without an argument, the setting
        my $limit = $recent->limit;

        is($limit,           5,     "a modifier without an argument returns the setting");
        is($users->limit,    undef, "the original handle is unchanged");
        is($users->order_by, undef, "entirely");
    }

    # Computed columns
    {
        use DBIx::QuickORM::Value qw/sql/;

        my @per_user = $orm->handle('posts')->group_by('user_id')->order_by('user_id')->fields({
            # the field itself, with its type and foreign key
            user_id => 'user_id',
            # COUNT(*)
            posts => [count => '*'],
            # an SQL expression: no type, no foreign key
            titles => sql('COUNT(DISTINCT title)'),
            # SUM(views)
            views => [sum => 'views'],
            # MAX(id), followed to that post
            latest => {
                agg => [max => 'id'],
                fk  => 'posts',
            },
        })->all;

        my $count  = $per_user[0]->field('posts');
        my $user   = $per_user[0]->follow_fk('users')->only;
        my $latest = $per_user[0]->follow_fk('posts')->only;

        is($count,                        5,        "a computed count");
        is($per_user[0]->field('views'),  30,       "a sum");
        is($per_user[0]->field('titles'), 5,        "an sql() column");
        is($user->field('name'),          'Alice',  "a grouped field follows its foreign key");
        is($latest->field('title'),       'Post 3', "a column given a foreign key follows it");
    }

    # Running elsewhere
    {
        # the query starts, and iter() returns at once
        my $it = $orm->handle('posts')->async->iter;
        do_something_else() until $it->ready;
        my @posts = $it->all;

        my $aside  = $orm->handle('posts')->aside->iter;     # on a second connection
        my $forked = $orm->handle('posts')->forked->iter;    # in a child process
        $orm->insert(users => {name => 'Busy'});             # the ORM's own connection stays free
        my @all = ($aside->all, $forked->all);

        is(scalar(@posts), 5,     "async rows");
        is(scalar(@all),   5 + 5, "aside and forked rows");
    }

    # Joins
    {
        $orm->handle('posts')->where({title => 'Post 3'})->update({views => 50});

        my @rows = $orm->handle('posts')->join('users', as => 'author')->where({
            'author.name' => 'Alice',
            'posts.views' => {'>' => 10},
        })->order_by('posts.id')->all;

        for my $row (@rows) {
            my $post   = $row->row('posts');
            my $author = $row->row('author');
            my $title  = $row->data->{'posts.title'};
        }

        # Every user and their posts, keeping users without any.
        my @users = $orm->handle('users')->left_join('posts', link => {id => 'user_id'})->order_by('users.name')->all;

        is([map { [$_->row('posts')->field('title'), $_->row('author')->field('name')] } @rows],          [['Hello 2', 'Alice'], ['Post 3', 'Alice']], "the joined rows");
        is($rows[0]->data->{'posts.title'},                                                               'Hello 2',                                   "and their raw data");
        is([map { $_->row('posts') ? 1 : 0 } grep { $_->row('users')->field('name') ne 'Alice' } @users], [0, 0, 0],                                   "users without posts");
        is(scalar(@users),                                                                                5 + 4,                                       "one row per post, and one per user without any");
    }

    # Fetching
    {
        my $h = $orm->handle('users')->order_by('name');

        my $first = $h->first;    # runs the query
        my $last  = $h->last;     # same rows, no second query
        my @all   = $h->all;

        my $bob = $h->where({email => 'bob@example.com'})->only;    # one row or undef, croaks on more

        my @names;
        while (my $user = $h->next) {                               # the handle's own position
            push @names => $user->field('name');
        }

        my $it = $h->iter;                                          # a new position over the same rows
        $h->clear;                                                  # forget the rows, so the next read runs the query again

        is($first->field('name'),    'Alice',                                  "first");
        is($last->field('name'),     'Busy',                                   "last");
        is(scalar(@all),             5,                                        "all");
        is(\@names,                  ['Alice', 'Alice', 'Amy', 'Bob', 'Busy'], "next on the handle");
        is($it->next->field('name'), 'Alice',                                  "iter starts at the first row");
        is($bob->field('name'),      'Bob',                                    "only");
        like(dies { $h->where({name => 'Alice'})->only }, qr/more than one/, "only croaks on more than one row");
    }

    # Writing
    {
        my $posts = $orm->handle('posts');

        my $post = $posts->insert({
            user_id => $id,
            title   => 'Draft',
        });
        $posts->update_row($post, {title => 'Final'});
        $posts->delete_row($post);

        my $changed = $posts->where({user_id => $id})->update({views => 0});    # how many rows changed
        my $deleted = $posts->where({views   => 0})->delete;                    # how many rows went

        is($post->field('title'), 'Final', "update_row changes the row");
        is([$changed, $deleted],  [5, 5],  "the bulk writes report their counts");
        is($posts->count,         0,       "and every post is gone");

        my $post_id = $posts->insert({user_id => $id, title => 'Quiet'})->field('id');
        $posts->insert({user_id => $id, title => 'Read', views => 3});

        my $stale = $posts->find($post_id);
        $posts->where({views => 0})->delete(mark_deleted => 1);
        my $gone = $stale->was_deleted;                                         # true if that post had no views

        ok($gone, "mark_deleted marks the held row of a deleted post");
        is($posts->count, 1, "and deletes only the matching rows");
    }

    # find
    {
        my $users = $orm->handle('users');
        my $user  = $users->find({id => $id});                                  # a hashref of the key fields (row data works)
        $user = $users->find([$id]);                                            # an arrayref of the values
        $user = $users->find($id);                                              # a single value, for a single-field key

        is($user->field('name'), 'Alice', "find takes the key in each form");
    }
};

done_testing;
