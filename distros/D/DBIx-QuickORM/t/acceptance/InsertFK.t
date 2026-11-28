# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;

do_for_all_dbs {
    my ($db, $set) = @_;

    my $dbh = $db->connect;
    $dbh->do("CREATE TABLE users (id INTEGER NOT NULL PRIMARY KEY, manager_id INTEGER, email VARCHAR(40) UNIQUE, name VARCHAR(20))");
    $dbh->do("CREATE TABLE posts (id INTEGER NOT NULL PRIMARY KEY, user_id INTEGER NOT NULL, title VARCHAR(20), FOREIGN KEY (user_id) REFERENCES users(id))");
    $dbh->do("CREATE TABLE reviews (id INTEGER NOT NULL PRIMARY KEY, author_id INTEGER, editor_id INTEGER, FOREIGN KEY (author_id) REFERENCES users(id), FOREIGN KEY (editor_id) REFERENCES users(id))");
    $dbh->do("CREATE TABLE badges (id INTEGER NOT NULL PRIMARY KEY, user_email VARCHAR(40), FOREIGN KEY (user_email) REFERENCES users(email))");

    # Table-level FOREIGN KEY clauses: older MySQL ignores inline REFERENCES. The self-reference is a
    # virtual key, since not every backend declares one.
    my $orm = DBIx::QuickORM->new(dbh => $dbh, fks => {users => {users => [{manager_id => 'id'}]}});

    my $ann = $orm->insert(users => {id => 1, email => 'ann@x', name => 'Ann'});
    my $bob = $orm->insert(users => {id => 2, name  => 'Bob'});    # no email

    subtest insert_fk => sub {
        my $post = $ann->insert_fk('posts', {id => 1, title => 'One'});
        isa_ok($post, ['DBIx::QuickORM::Row'], "insert_fk returns the row");
        is($post->field('user_id'), 1,     "with the link field filled from the parent");
        is($post->field('title'),   'One', "and the given fields");

        my $data = $orm->insert_fk(users => {id => 1}, 'posts', data => 1, {id => 2, title => 'Two'});
        is(ref($data),                                         'HASH', "the ORM form takes row data; data => 1 returns row data");
        is($orm->find(posts => $data->{id})->field('user_id'), 1,      "linked to that row");                                        # MySQL's data holds only the key

        like(dies { $ann->insert_fk('posts', {id => 3}, {id => 4}) }, qr/^insert_fk\(\) inserts one row; use insert_many_fk\(\) for more at \Q${\__FILE__}\E line \d+\.$/, "insert_fk croaks on more than one row, at the caller");
        like(dies { $ann->insert_fk('posts') },                       qr/^insert_fk\(\) inserts one row/,                                                                  "and on none");
    };

    subtest insert_many_fk => sub {
        my $rows = $ann->insert_many_fk('posts', {id => 10, title => 'A'}, {id => 11, title => 'B'});
        is(ref($rows),                                 'ARRAY', "insert_many_fk returns an arrayref");
        is([sort map { $_->field('user_id') } @$rows], [1, 1],  "of rows linked to the parent");

        is($ann->insert_many_fk('posts', count => 1, {id => 12}, {id => 13}), 2,  "count => 1 returns the count");
        is($ann->insert_many_fk('posts'),                                     [], "no rows: an empty arrayref");
        is($ann->insert_many_fk('posts', count => 1),                         0,  "or 0 with count");

        $ann->insert_many_fk('posts', {id => 14});
        is($orm->handle('posts')->where({id => 14})->only->field('user_id'), 1, "void context inserts");

        my $mixed = $ann->insert_many_fk('posts', {id => 15}, count => 0, {id => 16});
        is(scalar(@$mixed), 2, "options may sit among the rows");
    };

    subtest links => sub {
        like(dies { $ann->insert_fk('reviews', {id => 1}) }, qr/^There is more than one foreign key between 'users' and 'reviews'; choose one with 'link'/, "two keys need a link");

        my $review = $ann->insert_fk('reviews', link => {id => 'editor_id'}, {id => 1});
        is($review->field('editor_id'), 1,     "link chooses the key");
        is($review->field('author_id'), undef, "and fills only it");

        my $report = $ann->insert_fk('users', {id => 3, name => 'Cat'});
        is($report->field('manager_id'), 1, "a self-reference needs no link: only the key pointing back counts");

        like(
            dies { $ann->insert_fk('users', link => {manager_id => 'id'}, {id => 4}) },
            qr/^insert_fk\(\) inserts rows that point at the 'users' row; the link \(manager_id => id\) points from it/,
            "a link pointing from the row croaks, naming the direction",
        );

        my $post = $orm->handle('posts')->find(1);
        like(dies { $post->insert_fk('users', {id => 5}) },                          qr/^insert_fk\(\) inserts rows that point at the 'posts' row, and 'users' has no foreign key to 'posts'/, "so does a table the row points at");
        like(dies { $ann->insert_fk('reviews', link => {id => 'nope'}, {id => 2}) }, qr/^The link \(id => nope\) matches no foreign key/,                                                      "a link matching no key croaks");

        my $plain = DBIx::QuickORM->new(dbh => $dbh);                                                   # no virtual manager_id key
        my $boss  = $plain->find(users => 1);
        my $hire  = $boss->insert_fk('users', via => {id => 'manager_id'}, {id => 6, name => 'Dee'});
        is($hire->field('manager_id'), 1, "via links a new row without a key in the map");
        my $two = $boss->insert_many_fk('reviews', via => {id => 'author_id'}, {id => 3}, {id => 4});
        is([map { $_->field('author_id') } @$two], [1, 1], "insert_many_fk takes via too");
        like(dies { $boss->insert_fk('users', via => {id => 'manager_id'}, {id => 7, manager_id => 1}) }, qr/^insert_fk\(\) sets the link field\(s\) itself/, "a row may not set a via field either");
    };

    subtest croaks => sub {
        like(dies { $ann->insert_fk('posts', {id => 20, user_id => 1}) },              qr/^insert_fk\(\) sets the link field\(s\) itself; remove user_id from the row/, "a row setting a link field croaks, even to the same value");
        like(dies { $ann->insert_fk('posts', nope => 1, {id => 20}) },                 qr/^Unknown argument to insert_fk\(\): nope/,                                    "unknown options croak");
        like(dies { $ann->insert_fk('posts', as_given => 1, count => 1, {id => 20}) }, qr/^Unknown argument to insert_fk\(\): count/,                                   "insert_fk takes insert's options, not insert_many's");
        like(dies { $ann->insert_many_fk('posts', as_given => 1, {id => 20}) },        qr/^Unknown argument to insert_many_fk\(\): as_given/,                           "and insert_many_fk insert_many's");
        like(dies { $ann->insert_fk('posts', {id => 20}, 'raw') },                     qr/^The option 'raw' to insert_fk\(\) has no value/,                             "an option needs a value");
        like(dies { $ann->insert_fk('posts', [{id => 20}]) },                          qr/^insert_fk\(\) takes option => value pairs and hashrefs of fields/,           "rows are hashrefs");

        like(dies { $bob->insert_fk('badges', {id => 1}) }, qr/^Cannot insert rows linked to a 'users' row whose linked value is NULL \(user_email\)/, "a NULL linked value croaks");

        my $draft = $orm->vivify(users => {id => 9, name => 'Draft'});
        like(dies { $draft->insert_fk('posts', {id => 20}) }, qr/^Cannot insert rows linked to a 'users' row that is not in the database/, "a row not inserted croaks");

        my $gone = $orm->insert(users => {id => 8, name => 'Gone'});
        $gone->delete;
        like(dies { $gone->insert_fk('posts', {id => 20}) }, qr/^Cannot insert rows linked to a 'users' row that is not in the database/, "so does a deleted row");

        is($orm->handle('posts')->where({id => 20})->count, 0, "nothing was inserted");
    };

    subtest missing_parent_field => sub {
        my $slim  = $orm->handle('users')->fields(['id'])->where({id => 1})->only;
        my $badge = $slim->insert_fk('badges', {id => 2});
        is($badge->field('user_email'), 'ann@x', "a linked field missing from the row is fetched first");
    };
};

done_testing;
