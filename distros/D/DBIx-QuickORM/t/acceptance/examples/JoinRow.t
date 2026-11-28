# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/JoinRow.pm. Whenever an example
# there changes, change its copy here to match: t/acceptance/Examples.t fails while any example has
# no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    my $id = $orm->insert(users => {name => 'Alice'})->field('id');
    $orm->insert(posts => {user_id => $id, title => 'Hello'});

    my $jrow  = $orm->handle('posts')->join('users')->first;
    my $post  = $jrow->row('posts');
    my $name  = $jrow->row('users')->field('name');
    my @names = $jrow->aliases;                                # ('posts', 'users')
    my $title = $jrow->data->{'posts.title'};

    is($post->field('title'), 'Hello',            "a component row");
    is($name,                 'Alice',            "the joined row");
    is(\@names,               ['posts', 'users'], "aliases in join order");
    is($title,                'Hello',            "the raw data");
};

done_testing;
