use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# A row-bound handle must only accept rows from the same source and connection.
# Otherwise the row's primary key can be applied to the wrong table.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/row-source.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    $dbh->do('CREATE TABLE posts (id INTEGER PRIMARY KEY, title TEXT NOT NULL)');
    $dbh->disconnect;
}

my $con   = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $users = $con->handle('users');
my $posts = $con->handle('posts');

my $user = $users->insert({id => 1, name => 'alice'});
my $post = $posts->insert({id => 1, title => 'hello'});

subtest row_source_must_match_handle_source => sub {
    like(
        dies { $users->delete($post) },
        qr/The row is from source 'posts', but this handle uses source 'users'/,
        "delete() rejects a row from another source",
    );

    ok($users->one({id => 1}), "the user row was not deleted");
    ok($posts->one({id => 1}), "the post row was not deleted");

    like(
        dies { $users->data_only->one($post) },
        qr/The row is from source 'posts', but this handle uses source 'users'/,
        "data_only one() rejects a row from another source",
    );
};

subtest row_connection_must_match_handle_connection => sub {
    my $other = DBIx::QuickORM->quick(credentials => {dsn => $dsn});

    like(
        dies { $other->handle('users')->one($user) },
        qr/The row is bound to a different connection than this handle/,
        "one() rejects a row from another connection",
    );
};

subtest matching_row_is_still_accepted => sub {
    ref_is($con->handle($user)->one, $user, "a matching row can still bind a handle");
};

done_testing;
