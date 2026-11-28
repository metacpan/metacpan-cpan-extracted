# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/AggregateRow.pm. Whenever an example
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

    my $id = $orm->insert(users => {name => 'Alice', created => '2024-02-03 04:05:06'})->field('id');
    $orm->insert(posts => {user_id => $id, title => "Post $_", views => $_}) for 1 .. 3;

    use DBIx::QuickORM::Value qw/sql/;

    my $stat = $orm->handle('posts')->group_by('user_id')->fields({
        user_id => 'user_id',
        posts   => [count => '*'],
        top     => [max   => 'views'],
    })->first;

    my $count  = $stat->field('posts');
    my $author = $stat->follow_fk('users')->only;    # user_id keeps its foreign key

    my $signups = $orm->handle('users')->fields({
        total  => sql('COUNT(*)'),
        newest => [max => 'created'],
    })->only;

    my $year = $signups->field('newest')->datetime_ref->year;    # MAX keeps the field's type: a DateTime

    isa_ok($stat, ['DBIx::QuickORM::AggregateRow'], "computed rows are aggregate rows");
    is($count,                   3,       "a computed count");
    is($stat->field('top'),      3,       "a maximum");
    is($author->field('name'),   'Alice', "a grouped field follows its foreign key");
    is($signups->field('total'), 1,       "computed rows without a group");
    is($year,                    2024,    "MAX of a timestamp inflates");
};

done_testing;
