use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use Test::More;

use Async::Event::Interval;

# 3.4: id counter lives in shared %events (as _id_counter / _event_count)
# so IDs are unique even when events are created from forked processes.

# Sequential unique IDs within a single process.
{
    my $e0 = Async::Event::Interval->new(0, sub {});
    my $e1 = Async::Event::Interval->new(0, sub {});
    my $e2 = Async::Event::Interval->new(0, sub {});

    my $base = $e0->id;
    is $e1->id, $base + 1, "second event gets base+1 ID";
    is $e2->id, $base + 2, "third event gets base+2 ID";

    my %seen;
    $seen{$_}++ for ($e0->id, $e1->id, $e2->id);
    is scalar keys %seen, 3, "all three IDs are unique";
}

# _event_count increments on new(), decrements on DESTROY.
{
    my $before = Async::Event::Interval::_events_count();

    my $e0 = Async::Event::Interval->new(0, sub {});
    is Async::Event::Interval::_events_count(), $before + 1,
        "_event_count incremented on new()";

    my $e1 = Async::Event::Interval->new(0, sub {});
    is Async::Event::Interval::_events_count(), $before + 2,
        "_event_count incremented again";

    undef $e1;
    is Async::Event::Interval::_events_count(), $before + 1,
        "_event_count decremented on DESTROY";

    undef $e0;
    is Async::Event::Interval::_events_count(), $before,
        "_event_count back to baseline after all events destroyed";
}

# events() excludes internal _-prefixed keys.
{
    my $e = Async::Event::Interval->new(0, sub {});
    my $snap = Async::Event::Interval::events();

    ok exists $snap->{$e->id}, "events() includes user event key";
    for my $id (keys %$snap) {
        unlike $id, qr/^_/, "events() key '$id' is not internal metadata";
    }
}

# _id_counter is monotonic: freed IDs are never reassigned.
{
    my $e0 = Async::Event::Interval->new(0, sub {});
    my $e1 = Async::Event::Interval->new(0, sub {});
    my $freed_id = $e1->id;

    undef $e0;
    undef $e1;

    my $e2 = Async::Event::Interval->new(0, sub {});
    cmp_ok $e2->id, '>', $freed_id,
        "freed IDs are not reassigned (monotonic _id_counter)";
}

# Both _id_counter and _event_count survive across DESTROY of all events.
{
    my $ct = Async::Event::Interval::_events_count();
    is $ct, 0, "_event_count is 0 after all events destroyed";

    my $id_ct = Async::Event::Interval::_events_next_id();
    cmp_ok $id_ct, '>', 0,
        "_id_counter persists after all events destroyed ($id_ct)";
}

# Fork does not corrupt shared counters, and events created after
# fork still get unique IDs.
{
    my $ct_before = Async::Event::Interval::_events_next_id();
    my $ev_before = Async::Event::Interval::_events_count();

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (! $pid) {
        exit 0;
    }

    $SIG{CHLD} = 'DEFAULT';
    waitpid $pid, 0;
    $SIG{CHLD} = 'IGNORE';

    is Async::Event::Interval::_events_next_id(), $ct_before,
        "simple fork does not corrupt _id_counter";
    is Async::Event::Interval::_events_count(), $ev_before,
        "simple fork does not corrupt _event_count";

    # After the fork, new events continue from the same counter.
    my $e0 = Async::Event::Interval->new(0, sub {});
    my $e1 = Async::Event::Interval->new(0, sub {});
    is $e0->id, $ct_before,     "post-fork event gets expected next ID";
    is $e1->id, $ct_before + 1, "post-fork second event gets sequential ID";
    is Async::Event::Interval::_events_next_id(), $ct_before + 2,
        "counter advanced past post-fork events";
}
