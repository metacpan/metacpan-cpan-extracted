# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/ForeignKeys.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    $db->connect->do(<<'SQL');
CREATE TABLE audit_log (
    id      SERIAL PRIMARY KEY,
    user_id INTEGER,
    action  TEXT NOT NULL
);
SQL
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    my $alice = $orm->insert(users => {name => 'Alice'});
    my $bob   = $orm->insert(users => {name => 'Bob', referred_by => $alice->field('id')});
    $orm->insert(users => {name => 'Carol', referred_by => $alice->field('id')});
    my $post_id = $orm->insert(posts => {user_id => $alice->field('id'), title => 'Hello', views => 10})->field('id');
    $orm->insert(posts => {user_id => $alice->field('id'), title => 'Again',    views => 5});
    $orm->insert(posts => {user_id => $bob->field('id'),   title => 'Bob post', views => 7});

    # FOLLOWING A KEY
    my $post = $orm->handle('posts')->where({id => $post_id})->only;

    # the user posts.user_id points at
    my $author = $post->follow_fk('users')->only;

    # the posts whose user_id points at this user
    my @posts = $author->follow_fk('posts')->order_by('id')->all;

    is($post->field('title'),               'Hello',            "the post looked up by id");
    is($author->field('name'),              'Alice',            "forward: the row the key points at");
    is([map { $_->field('title') } @posts], ['Hello', 'Again'], "reverse: the rows pointing here");

    {
        # SINGLE AND MULTI
        my $one  = $post->follow_fk('users');      # single: user_id reaches the users primary key
        my $many = $author->follow_fk('posts');    # multi: any number of posts may point here

        my $user  = $one->only;                    # the row, or undef
        my @all   = $many->all;
        my $state = $many->state;                  # 'multi': only() croaks if multi is true

        is($one->state,          'single', "a key to a primary key is single");
        is($user->field('name'), 'Alice',  "only gives the row");
        is(scalar(@all),         2,        "a multi handle gives every row");
        is($state,               'multi',  "and says so");
        like(dies { $many->only }, qr/only\(\) cannot be used on a multi-row iterator/, "only croaks on a multi handle");
    }

    # DIRECTION WITH LINK
    # users.referred_by points at users.id: the same key read both ways.

    # who referred Bob
    my $referrer = $bob->follow_fk('users', link => {referred_by => 'id'})->only;

    # whom Alice referred
    my @referrals = $alice->follow_fk('users', link => {id => 'referred_by'})->order_by('id')->all;

    is($referrer->field('name'),               'Alice',          "{referred_by => 'id'} follows to the referrer");
    is([map { $_->field('name') } @referrals], ['Bob', 'Carol'], "{id => 'referred_by'} follows to the referrals");
    like(dies { $bob->follow_fk('users') }, qr/more than one foreign key between 'users' and 'users'/, "both directions of referred_by fit, so a link is needed");

    {
        # NULL LINKS
        # Alice was not referred
        my $nobody = $alice->follow_fk('users', link => {referred_by => 'id'});
        my $who    = $nobody->only;                                               # undef: a NULL key points at nothing

        is($who,           undef,    "a NULL key finds nothing");
        is($nobody->state, 'single', "and the handle is still single");
    }

    # NARROWING AND JOINING
    my @popular = $author->follow_fk('posts')->and({views => {'>' => 5}})->all;

    # Bob's referrer with each of their posts
    my @theirs = $bob->follow_fk('users', link => {referred_by => 'id'})->join('posts')->order_by('posts.id')->all;

    is($author->follow_fk('posts')->and({views => {'>' => 5}})->state,                        undef,                                    "and drops the multi state");
    is([map { $_->field('title') } @popular],                                                 ['Hello'],                                "and narrows the followed rows");
    is([map { [$_->row('users')->field('name'), $_->row('posts')->field('title')] } @theirs], [['Alice', 'Hello'], ['Alice', 'Again']], "a followed handle can be joined");

    # WITHOUT ROW OBJECTS
    my $data = $orm->handle('posts')->data_only->where({id => $post_id})->only;    # a hashref

    my $who = $orm->follow_fk('posts', $data, 'users')->only;                      # a users row object

    # user_id is fetched first
    my $by_key = $orm->follow_fk('posts', {id => $post_id}, 'users')->only;

    is(ref($data), 'HASH', "row data");
    isa_ok($who, ['DBIx::QuickORM::Row'], "data_only applied to the lookup only; the followed row is an object");
    is($who->field('name'),    'Alice', "the ORM's follow_fk takes it");
    is($by_key->field('name'), 'Alice', "and fetches a missing key field first");

    # FROM AGGREGATE AND JOIN ROWS
    my $stat = $orm->handle('posts')->group_by('user_id')->fields({
        user_id => 'user_id',
        posts   => [count => '*'],
    })->order_by('user_id')->first;

    my $user = $stat->follow_fk('users')->only;    # user_id kept its key

    my $jrow = $orm->handle('posts')->join('users')->order_by('posts.id')->first;
    # each table's row in a join is an ordinary row
    my @more = $jrow->row('users')->follow_fk('posts')->all;

    is($user->field('name'), 'Alice', "an aggregate row follows a grouped field's key");
    is(scalar(@more),        2,       "a join row's component follows its keys");

    # KEYS THE MAP DOES NOT KNOW
    {
        my $alice_id = $alice->field('id');

        # audit_log.user_id points at users.id, but nothing declares it
        my $entry = $orm->insert(audit_log => {user_id => $alice_id, action => 'login'});

        my $who = $entry->follow_fk('users',     via => {user_id => 'id'})->only;
        my @log = $alice->follow_fk('audit_log', via => {id      => 'user_id'})->all;

        my @pairs = $orm->handle('audit_log')->join('users', via => {user_id => 'id'})->all;

        my $next = $alice->insert_fk('audit_log', via => {id => 'user_id'}, {action => 'logout'});

        is($who->field('name'),                              'Alice',   "via follows to the row");
        is([map { $_->field('action') } @log],               ['login'], "and back");
        is([map { $_->row('users')->field('name') } @pairs], ['Alice'], "a join takes via");
        is($next->field('user_id'),                          $alice_id, "and so does insert_fk");
        $orm->handle('audit_log')->delete;
    }

    # INSERTING LINKED ROWS
    {
        my $alice_id = $alice->field('id');

        my $post  = $alice->insert_fk('posts', {title => 'Hi'});                                   # user_id is Alice's id
        my $posts = $alice->insert_many_fk('posts', {title => 'A'}, {title => 'B'});               # an arrayref of rows
        my $count = $alice->insert_many_fk('posts', count => 1, {title => 'C'}, {title => 'D'});

        # only keys pointing back at Alice count, so users.referred_by needs no link
        my $dan = $alice->insert_fk('users', {name => 'Dan'});                                     # referred by Alice

        my $note = $orm->insert_fk(users => {id => $alice_id}, 'posts', {title => 'Note'});

        is($post->field('user_id'),              $alice_id,  "insert_fk fills the key from the row");
        is([map { $_->field('title') } @$posts], ['A', 'B'], "insert_many_fk returns the rows");
        is($count,                               2,          "or the count");
        is($dan->field('referred_by'),           $alice_id,  "a self-reference needs no link");
        is($note->field('user_id'),              $alice_id,  "the ORM form takes row data");
    }
};

done_testing;
