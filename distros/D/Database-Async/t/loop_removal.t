use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Refcount;
use Database::Async;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

subtest 'remove without any activity' => sub {
    $loop->add(
        my $db = Database::Async->new
    );
    $loop->remove($db);
    is_oneref($db, 'only a single reference left after removing from the loop');
    ok(!exists $db->{pool}, 'pool was removed');
    ok(!exists $db->{ryu}, 'Ryu::Async was removed');
    is(() = $db->children, 0, 'notifier has no children');
    done_testing;
};
subtest 'remove after registering a single engine instance' => sub {
    $loop->add(
        my $db = Database::Async->new
    );
    $db->pool->register_engine(Database::Async::Engine::Empty->new);
    $loop->remove($db);
    is_oneref($db, 'only a single reference left after removing from the loop');
    ok(!exists $db->{pool}, 'pool was removed');
    ok(!exists $db->{ryu}, 'Ryu::Async was removed');
    is(() = $db->children, 0, 'notifier has no children');
    done_testing;
};

done_testing;
