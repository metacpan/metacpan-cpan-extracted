# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Aggregates.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test qw/do_for_all_dbs db_sets/;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);
    $db->connect->do($SCHEMA);
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    my %id;
    $id{$_->[0]} = $orm->insert(users => {name => $_->[0], referred_by => $_->[1] && $id{$_->[1]}, created => $_->[2]})->field('id')
        for ['Alice', undef, '2024-01-02 03:04:05'], ['Bob', 'Alice', '2025-02-03 04:05:06'], ['Carol', 'Alice', '2025-03-04 05:06:07'], ['Dave', undef, '2026-04-05 06:07:08'];
    $orm->insert(posts => {user_id => $id{$_->[0]}, title => $_->[1], views => $_->[2]}) for ['Alice', 'Hello', 10], ['Alice', 'Again', 5], ['Bob', 'Bob post', 7], ['Carol', 'Carol post', 1];
    my $alice_id = $id{Alice};

    # COUNTING
    my $total = $orm->handle('posts')->count;                                   # SELECT COUNT(*)
    my $alice = $orm->handle('posts')->where({user_id => $alice_id})->count;    # with its WHERE

    is($total, 4, "count counts the table");
    is($alice, 2, "and the where applies");

    # GROUPING
    use DBIx::QuickORM::Value qw/sql/;

    my @per_user = $orm->handle('posts')->group_by('user_id')->fields({
        user_id => 'user_id',
        posts   => [count => '*'],
        views   => [sum   => 'views'],
    })->order_by('user_id')->all;

    for my $stat (@per_user) {
        my $posts = $stat->field('posts');
        my ($user_id, $views) = $stat->fields(qw/user_id views/);
        my $user = $stat->follow_fk('users')->only;    # user_id keeps its foreign key
    }

    # Without group_by the whole table is one group.
    my $all = $orm->handle('posts')->fields({
        posts => [count => '*'],
        top   => [max   => 'views'],
    })->only;

    my ($count, $top) = $all->fields(qw/posts top/);

    # group_by alone selects the grouped fields.
    my @groups = $orm->handle('posts')->group_by('user_id')->order_by('user_id')->all;

    # Several fields: pass them all. One row per user and title.
    my @per_title = $orm->handle('posts')->group_by('user_id', 'title')->fields({
        user_id => 'user_id',
        title   => 'title',
        posts   => [count => '*'],
    })->order_by(['user_id', 'title'])->all;

    isa_ok($per_user[0], ['DBIx::QuickORM::AggregateRow'], "computed rows are aggregate rows");
    is([map { [$_->fields(qw/user_id posts views/)] } @per_user], [[$id{Alice}, 2, 15], [$id{Bob}, 1, 7], [$id{Carol}, 1, 1]], "one row per group, with the counts and sums");
    my @seen = map { [$_->follow_fk('users')->only->field('name'), $_->field('posts'), $_->fields(qw/user_id views/)] } @per_user;
    is(\@seen,                                 [['Alice', 2, $id{Alice}, 15], ['Bob', 1, $id{Bob}, 7], ['Carol', 1, $id{Carol}, 1]], "field, fields, and follow_fk on each aggregate row");
    is([$count, $top],                         [4, 10],                                                                              "no group_by: one row for the whole table");
    is([map { $_->field('user_id') } @groups], [$id{Alice}, $id{Bob}, $id{Carol}],                                                   "group_by alone selects the grouped field");
    like(dies { $orm->handle('posts')->group_by('user_id')->count }, qr/count\(\) cannot count groups/, "count croaks on a grouped handle");
    is([map { [$_->fields(qw/user_id title posts/)] } @per_title], [[$id{Alice}, 'Again', 1], [$id{Alice}, 'Hello', 1], [$id{Bob}, 'Bob post', 1], [$id{Carol}, 'Carol post', 1]], "group_by takes several fields");

    # HAVING
    my @busy = $orm->handle('posts')->where({views => {'>' => 0}})    # filters rows, before grouping
        ->group_by('user_id')->fields({
        user_id => 'user_id',
        posts   => [count => '*'],
        })->having({posts => {'>' => 1}})                             # filters groups
        ->all;

    my @later = $orm->handle('posts')->group_by('user_id')->having({user_id => {'>' => 1}})->all;

    my @two = $orm->handle('posts')->group_by('user_id')->having(sql('COUNT(*) > ?', 1))->all;

    is([map { $_->field('user_id') } @busy],       [$id{Alice}],           "having names a computed column; PostgreSQL gets its SQL");
    is([map { $_->field('user_id') } @two],        [$id{Alice}],           "sql() writes the condition, with binds");
    is([sort map { $_->field('user_id') } @later], [$id{Bob}, $id{Carol}], "having can name a grouped field");
    like(dies { $orm->handle('posts')->having(sql('COUNT(*) > 1'))->all }, qr/having\(\) needs group_by\(\) or fields/, "having alone croaks on fetch");

    # COLUMN SPECS
    {
        my $stat = $orm->handle('posts')->group_by('user_id')->fields({
            # the field itself: its type and single-column foreign keys come along
            user_id => 'user_id',
            posts   => [count => '*'],                  # COUNT(*): '*' stands for the whole row
            titles  => sql('COUNT(DISTINCT title)'),    # any SQL: no type, no foreign key
            chars   => \'SUM(LENGTH(title))',           # short for sql('SUM(LENGTH(title))')

            # MAX(views): min and max keep the field's type and single-column keys
            top   => [max => 'views'],
            views => [sum => 'views'],                  # SUM(views): other functions keep neither

            # MAX(id), declared a foreign key to posts
            latest => {
                agg => [max => 'id'],
                fk  => 'posts',
            },
        })->order_by('user_id')->first;

        my $author = $stat->follow_fk('users')->only;    # user_id kept its key
        my $latest = $stat->follow_fk('posts')->only;    # latest was given one

        is([$stat->fields(qw/posts titles top views latest/)], [2, 2, 10, 15, 2], "every column form selects");
        is($author->field('name'),                             'Alice',           "a plain field keeps its foreign key");
        is($latest->field('title'),                            'Again',           "fk gives a computed column one");
        is($stat->field('chars'),                              10,                "\\'SQL' is short for sql('SQL')");

        my $keyed = $orm->handle('posts')->group_by('user_id')->fields({n => [count => 'user_id'], m => [max => 'user_id']})->order_by('m')->first;
        is($keyed->follow_fk('users', link => {m => 'id'})->only->field('name'), 'Alice', "max keeps a keyed field's key");
        like(dies { $keyed->follow_fk('users', link => {n => 'id'}) }, qr/matches no foreign key/, "a function other than min or max keeps none");
    }

    # TYPES
    my $signups = $orm->handle('users')->fields({
        newest => [max   => 'created'],
        total  => [count => '*'],
    })->only;
    my $year = $signups->field('newest')->datetime_ref->year;    # MAX kept created's type: a DateTime
    my $text = $signups->raw_field('newest');                    # the value as fetched

    my $span = $orm->handle('users')->fields({
        # an sql() column inflates only when told: like takes created's type and keys
        first => {
            sql  => sql("date_trunc('day', MIN(created))"),
            like => 'created',
        },
        # or name the type by hand
        last => {
            sql     => sql("date_trunc('day', MAX(created))"),
            type    => 'DateTime',
            db_type => 'timestamp',
        },
    })->only;

    my ($first, $last) = map { $_->datetime_ref->ymd } $span->fields(qw/first last/);

    is($year,                    2026,                         "max keeps the DateTime type");
    is($text,                    '2026-04-05 06:07:08',        "raw_field reads the text as fetched");
    is($signups->field('total'), 4,                            "an untyped column reads as fetched");
    is([$first, $last],          ['2024-01-02', '2026-04-05'], "like and an explicit type both inflate");

    # LIKE_AGGREGATES
    SKIP: {
        skip "ANY_VALUE needs PostgreSQL 16", 2 if $orm->connection->dialect->server_version < 160000;

        my $orm = DBIx::QuickORM->new(
            credentials => {
                dsn  => $dsn,
                user => $user,
                pass => $pass,
            },
            like_aggregates => ['any_value'],
        );

        # ANY_VALUE (PostgreSQL 16 and later) gives one of the group's values, so the
        # column keeps the field's type and keys.
        my @groups = $orm->handle('users')->group_by('referred_by')->fields({
            referred_by => 'referred_by',
            joined      => [any_value => 'created'],
        })->order_by('referred_by')->all;

        my $year = $groups[0]->field('joined')->datetime_ref->year;    # a DateTime, like created

        is($groups[0]->field('referred_by'), $id{Alice}, "the first group is the users Alice referred");
        is($year,                            2025,       "any_value keeps the type once listed in like_aggregates");
    }

    # OVER A JOIN
    my @by_name = $orm->handle('posts')->join('users')->group_by('users.id', 'users.name')    # several fields: a list
        ->fields({
        name   => 'users.name',
        posts  => [count => '*'],
        newest => [max   => 'users.created'],
        })->order_by('name')->all;

    my ($name, $posts) = $by_name[0]->fields(qw/name posts/);

    isa_ok($by_name[0], ['DBIx::QuickORM::AggregateRow'], "a grouped join returns aggregate rows, not join rows");
    is([$name, $posts], ['Alice', 2], "read through fields");
    is([map { [$_->field('name'), $_->field('posts'), $_->field('newest')->datetime_ref->year] } @by_name], [['Alice', 2, 2024], ['Bob', 1, 2025], ['Carol', 1, 2025]], "aggregates over a join name table.field and keep types");

    # AGGREGATE ROWS
    {
        my $stat = $per_user[0];    # from GROUPING

        my $posts = $stat->field('posts');
        my ($id, $n) = $stat->fields(qw/user_id posts/);
        my $pk = $stat->pk;         # undef: no primary key

        # Plain hashrefs instead.
        my @data = $orm->handle('posts')->group_by('user_id')->data_only->all;

        isa_ok($stat, ['DBIx::QuickORM::AggregateRow'], "aggregate rows");
        is($posts,        2,                                  "field reads a column");
        is([$id, $n],     [$id{Alice}, 2],                    "fields reads several");
        is($pk,           undef,                              "no primary key");
        is(scalar(@data), 3,                                  "data_only gives one hashref per group");
        is($data[0],      hash { field user_id => D(); end }, "as hashrefs of the grouped field");
        like(dies { $stat->update({posts => 0}) }, qr/Cannot update a row without a primary key/,   "update croaks");
        like(dies { $stat->is_canon },             qr/Cannot is_canon a row without a primary key/, "and so does is_canon");
    }
};

# HAVING on MySQL and MariaDB: a computed column can be named.
{
    local $ENV{QORM_TEST_SETS} = join ',' => map { $_->{name} } grep { $_->{family} eq 'MySQL' || $_->{family} eq 'MariaDB' } db_sets();
    do_for_all_dbs {
        my ($db) = @_;
        my $dbh = $db->connect;
        $dbh->do("CREATE TABLE users (id INTEGER PRIMARY KEY AUTO_INCREMENT, name TEXT NOT NULL)");
        $dbh->do("CREATE TABLE posts (id INTEGER PRIMARY KEY AUTO_INCREMENT, user_id INTEGER NOT NULL REFERENCES users (id), title TEXT NOT NULL)");
        my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

        my $alice = $orm->insert(users => {name => 'Alice'})->field('id');
        my $bob   = $orm->insert(users => {name => 'Bob'})->field('id');
        $orm->insert(posts => {user_id => $_->[0], title => $_->[1]}) for [$alice, 'Hello'], [$alice, 'Again'], [$bob, 'Bob post'];

        my @busy = $orm->handle('posts')->group_by('user_id')->fields({
            user_id => 'user_id',
            posts   => [count => '*'],
        })->having({posts => {'>' => 1}})->all;

        is([map { $_->field('user_id') } @busy], [$alice], "having names the computed column");
    }
    if $ENV{QORM_TEST_SETS};
}

# HAVING on SQLite: a bind compares as text, so the page says to cast it.
{
    local $ENV{QORM_TEST_SETS} = join ',' => map { $_->{name} } grep { $_->{family} eq 'SQLite' } db_sets();
    do_for_all_dbs {
        my ($db) = @_;
        my $dbh = $db->connect;
        $dbh->do("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)");
        $dbh->do("CREATE TABLE posts (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users (id), title TEXT NOT NULL)");
        my $orm = DBIx::QuickORM->new(dbh => $dbh);

        my $alice = $orm->insert(users => {name => 'Alice'})->field('id');
        my $bob   = $orm->insert(users => {name => 'Bob'})->field('id');
        $orm->insert(posts => {user_id => $_->[0], title => $_->[1]}) for [$alice, 'Hello'], [$alice, 'Again'], [$bob, 'Bob post'];

        my $minimum = 1;
        my $busy    = $orm->handle('posts')->group_by('user_id')->fields({user_id => 'user_id', posts => [count => '*']});
        is([map { $_->field('user_id') } $busy->having(sql('COUNT(*) > ?',                  $minimum))->all], [],       "a plain bind compares as text and matches no group");
        is([map { $_->field('user_id') } $busy->having(sql('COUNT(*) > CAST(? AS INTEGER)', $minimum))->all], [$alice], "cast, the bind compares as a number");
    }
    if $ENV{QORM_TEST_SETS};
}

done_testing;
