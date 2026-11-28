# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Iterator.pm. Whenever an example
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

    $orm->insert(users => {name => 'Bob', email => 'bob@example.com'});
    $orm->insert(users => {name => 'Alice'});

    my $it = $orm->handle('users')->order_by('name')->iter;

    my @names;
    while (my $user = $it->next) {
        push @names => $user->field('name');
    }

    $it->reset;    # back to the first row, without running the query again
    my @all   = $it->all;
    my $first = $it->first;

    # The one row, or undef. Croaks when there is more than one.
    my $bob = $orm->handle('users')->where({email => 'bob@example.com'})->iter->only;

    my $later = $orm->handle('users')->async->iter;
    do_something_else() until $later->ready;
    my @rows = $later->all;

    is(\@names,                          ['Alice', 'Bob'], "next walks the rows");
    is([map { $_->field('name') } @all], ['Alice', 'Bob'], "all after reset");
    is($first->field('name'),            'Alice',          "first");
    is($bob->field('name'),              'Bob',            "only");
    is(scalar(@rows),                    2,                "a pending iterator's rows");
    like(dies { $orm->handle('users')->iter->only }, qr/more than one/, "only croaks on more than one row");
};

done_testing;
