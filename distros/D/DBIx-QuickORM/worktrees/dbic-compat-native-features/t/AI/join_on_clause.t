use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Link;
use DBIx::QuickORM::Join;

# A join link between tables with ASYMMETRIC column names (users.id ->
# posts.user_id) must pair the joined table's alias with the OTHER columns
# and the from-alias with the LOCAL columns. Every same-named-column join
# masks getting this backwards.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $C = 'DBIx::QuickORM::Schema::Table::Column';

my $users = DBIx::QuickORM::Schema::Table->new(
    name    => 'users',
    columns => {
        id   => $C->new(name => 'id',   order => 1, affinity => 'numeric'),
        name => $C->new(name => 'name', order => 2, affinity => 'string'),
    },
    primary_key => ['id'],
);

my $posts = DBIx::QuickORM::Schema::Table->new(
    name    => 'posts',
    columns => {
        post_id => $C->new(name => 'post_id', order => 1, affinity => 'numeric'),
        user_id => $C->new(name => 'user_id', order => 2, affinity => 'numeric'),
        title   => $C->new(name => 'title',   order => 3, affinity => 'string'),
    },
    primary_key => ['post_id'],
);

my $schema = DBIx::QuickORM::Schema->new(name => 's', tables => {users => $users, posts => $posts});

my $link = DBIx::QuickORM::Link->new(
    local_table   => 'users',
    other_table   => 'posts',
    local_columns => ['id'],
    other_columns => ['user_id'],
    unique        => 0,
);

subtest on_clause_sides => sub {
    my $join    = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $users)->left_join($link);
    my $moniker = ${$join->source_db_moniker};

    like($moniker, qr/\bON \("b"\."user_id" = "a"\."id"\)/, "ON clause pairs the joined alias with the other columns");
    unlike($moniker, qr/"b"\."id"|"a"\."user_id"/, "no swapped alias/column pairings appear");
};

subtest runtime_sqlite => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:SQLite:dbname=$dir/join_on_clause.sqlite";

    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)');
        $dbh->do('CREATE TABLE posts (post_id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER REFERENCES users(id), title TEXT NOT NULL)');
        $dbh->disconnect;
    }

    my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});

    my $alice = $con->handle('users')->insert({name => 'alice'});
    my $bob   = $con->handle('users')->insert({name => 'bob'});

    $con->handle('posts')->insert({user_id => $alice->field('id'), title => 'a1'});
    $con->handle('posts')->insert({user_id => $alice->field('id'), title => 'a2'});
    $con->handle('posts')->insert({user_id => $bob->field('id'),   title => 'b1'});

    my $h = $con->handle('users')->left_join('posts')->order_by(qw/a.id b.post_id/);

    my @rows = map { +{user => $_->field('a.name'), title => $_->field('b.title')} } $h->all;

    is(
        \@rows,
        [
            {user => 'alice', title => 'a1'},
            {user => 'alice', title => 'a2'},
            {user => 'bob',   title => 'b1'},
        ],
        "asymmetric-column join associates each post with its own user"
    );

    ref_ok($h->fields, 'ARRAY', "a join handle's field list is an arrayref");
    ok(lives { $h->fields(\"1 AS extra")->data_only->all }, "the additive fields() form works on a join handle")
        or note $@;
};

done_testing;
