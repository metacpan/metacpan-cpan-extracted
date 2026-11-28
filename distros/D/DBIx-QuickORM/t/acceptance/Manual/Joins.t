# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Joins.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    my %id;
    $id{$_->[0]} = $orm->insert(users => {name => $_->[0], referred_by => $_->[1] && $id{$_->[1]}})->field('id') for ['Alice'], ['Bob', 'Alice'], ['Carol', 'Alice'], ['Dave'];
    $orm->insert(posts => {user_id => $id{$_->[0]}, title => $_->[1], views => $_->[2]}) for ['Alice', 'Hello', 10], ['Alice', 'Again', 5], ['Bob', 'Bob post', 7], ['Carol', 'Carol post', 1];

    # INNER AND LEFT JOINS
    {
        my $joined = $orm->handle('posts')->join('users')->order_by('posts.id');

        my @pairs = $joined->all;
        my $count = $joined->count;
        my $first = $joined->first;

        my $it = $joined->iter;
        while (my $pair = $it->next) {
            my $post   = $pair->row('posts');                 # a full posts row
            my $title  = $post->field('title');
            my $author = $pair->row('users')->field('name');
            my @names  = $pair->aliases;                      # ('posts', 'users')
        }

        my (@seen, @seen_aliases);
        my $again = $joined->iter;
        while (my $pair = $again->next) {
            push @seen         => [$pair->row('posts')->field('title'), $pair->row('users')->field('name')];
            push @seen_aliases => [$pair->aliases];
            isa_ok($pair->row('posts'), ['DBIx::QuickORM::Row'], "row() returns the table's row object");
        }

        my @everyone = $orm->handle('users')->left_join('posts')->order_by('users.id')->all;

        isa_ok($pairs[0], ['DBIx::QuickORM::JoinRow'], "a join hands out join rows");
        is([map { [$_->row('posts')->field('title'), $_->row('users')->field('name')] } @pairs], [['Hello', 'Alice'], ['Again', 'Alice'], ['Bob post', 'Bob'], ['Carol post', 'Carol']], "each post with its author");
        is(\@seen,                                                                               [map { [$_->row('posts')->field('title'), $_->row('users')->field('name')] } @pairs], "iter walks the same join rows");
        is($seen_aliases[0],                                                                      ['posts', 'users'],                                                                    "aliases in join order");
        is($count,                                                                                4,                                                                                     "count counts the joined rows");
        is($first->row('posts')->field('title'),                                                  'Hello',                                                                               "first returns the first join row");
        is(scalar(@everyone),                                                                     5,                                                                                     "a left join keeps the user without posts");
        is($everyone[-1]->row('users')->field('name'),                                            'Dave',                                                                                "that user is there");
        is($everyone[-1]->row('posts'),                                                           undef,                                                                                 "with no post row");
    }

    # FILTERING, ORDERING, AND FIELDS
    {
        my @popular = $orm->handle('posts')->join('users')->where({
            'users.name'  => 'Alice',
            'posts.views' => {'>' => 5},
            })->order_by([{-desc => 'posts.views'}, 'posts.id'])->fields(['posts.title', 'users.name'])    # a subset (each primary key is always added)
            ->all;

        my $n = $orm->handle('posts')->join('users')->where({'users.name' => 'Alice'})->count;

        is([map { $_->row('posts')->field('title') } @popular], ['Hello'],                                                                                      "where names fields of both tables");
        is($popular[0]->data,                                   {'posts.title' => 'Hello', 'users.name' => 'Alice', 'posts.id' => 1, 'users.id' => $id{Alice}}, "fields selects the subset plus each primary key");
        is($n,                                                  2,                                                                                              "count counts the joined rows");
    }

    # ALIASES
    my @by_author = $orm->handle('posts')->join('users', as => 'author')->order_by('author.name')->all;

    my $writer = $by_author[0]->row('author')->field('name');

    is($writer,                  'Alice',             "the joined table is known by its alias");
    is([$by_author[0]->aliases], ['posts', 'author'], "which names the component");

    # SELF JOINS
    {
        # Each referred user with whoever referred them.
        my @referred = $orm->handle('users')->join(
            'users',
            as   => 'referrer',
            link => {referred_by => 'id'},
        )->order_by('users.id')->all;

        for my $pair (@referred) {
            my $who = $pair->row('users')->field('name');
            my $by  = $pair->row('referrer')->field('name');
        }

        # The other way round: each referrer with the users they referred.
        my @referrals = $orm->handle('users')->join(
            'users',
            as   => 'referral',
            link => {id => 'referred_by'},
        )->order_by('referral.id')->all;

        is([map { [$_->row('users')->field('name'), $_->row('referrer')->field('name')] } @referred],  [['Bob',   'Alice'], ['Carol', 'Alice']], "{referred_by => 'id'} pairs each referred user with the referrer");
        is([map { [$_->row('users')->field('name'), $_->row('referral')->field('name')] } @referrals], [['Alice', 'Bob'],   ['Alice', 'Carol']], "{id => 'referred_by'} pairs the referrer with each referral");
    }

    # JOINING FROM A JOINED TABLE
    {
        my @chain = $orm->handle('posts')->join('users')->left_join(
            'users',
            as   => 'referrer',
            from => 'users',
            link => {referred_by => 'id'},
        )->order_by('posts.id')->all;

        my $author   = $chain[0]->row('users')->field('name');
        my $referrer = $chain[0]->row('referrer');               # undef when the author was not referred

        is($author,                                   'Alice', "the author of the first post");
        is($referrer,                                 undef,   "who nobody referred");
        is($chain[2]->row('referrer')->field('name'), 'Alice', "from joins the second users component to the first, not to posts");
    }

    # FLAT ROWS
    {
        # one join row per post
        my @pairs = $orm->handle('users')->join('posts')->order_by('posts.id')->all;

        my @aliases = $pairs[0]->aliases;    # ('users', 'posts'), in join order

        # {'users.id' => 1, 'users.name' => 'Alice', 'posts.title' => 'Hello', ...}
        my $data = $pairs[0]->data;

        # Plain hashrefs keyed table.field, with no row objects at all.
        my @raw = $orm->handle('users')->join('posts')->row_class(undef)->all;

        is(scalar(@pairs),         4,                  "one join row per post");
        is(\@aliases,              ['users', 'posts'], "aliases in join order");
        is($data->{'users.name'},  'Alice',            "data is keyed table.field");
        is($data->{'posts.title'}, 'Hello',            "for every component");
        ref_is($pairs[0]->row('users'), $pairs[1]->row('users'), "two posts by one user share the user row object within one result");
        is(ref($raw[0]),                            'HASH',                                       "row_class undef gives hashrefs");
        is([sort map { $_->{'posts.title'} } @raw], ['Again', 'Bob post', 'Carol post', 'Hello'], "keyed table.field");
    }

    # WRITING AND FOLLOWING KEYS
    my $post_id = $orm->handle('posts')->where({title => 'Hello'})->only->field('id');

    my $pair = $orm->handle('posts')->join('users')->where({'posts.id' => $post_id})->only;

    $pair->row('posts')->update({views => 11});    # write through the table's row
    my @posts = $pair->row('users')->follow_fk('posts')->all;

    is($orm->handle('posts')->where({title => 'Hello'})->only->field('views'), 11, "the update went through the component row");
    is(scalar(@posts),                                                         2,  "a table's row follows its keys");
    ok(!$pair->can('update'), "a join row has no write methods");
};

done_testing;
