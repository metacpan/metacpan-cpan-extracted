use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use YAML::XS qw( Dump );
use JSON::MaybeXS qw( decode_json );
use Time::Piece;

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Metrics;

# karr board ticket #126: `karr metrics` -- throughput, lead/cycle time, flow
# efficiency and aging work items, the last kanban-md parity gap.
#
# What these tests pin down is not "the command prints something" but the
# decisions the ticket asked to be made rather than assumed:
#
#   * which stamps define lead versus cycle time (created->completed vs
#     started->completed, kanban-md's split, so the numbers compare between the
#     two tools);
#   * what flow efficiency divides by -- karr's one deliberate departure: the
#     lead time of the same tasks the cycle time was measured over, so a
#     completed card with no start cannot push the ratio above 100%;
#   * which stamps are trustworthy enough to measure with at all: a `started`
#     that precedes its own card is a pre-#68 bare date, not a start time, and
#     counting one is how the first run of this command against karr's own
#     board reported 107.3% flow efficiency;
#   * that "terminal" comes from the board's config and not from a hardcoded
#     `done`, which is what tickets #67/#98/#101 cost to establish;
#   * that a card missing from a figure is reported rather than dropped
#     silently -- a metrics command that quietly under-counts is worse than one
#     that refuses to answer.
#
# Every test runs against its own temp repository; none of them touches the
# developer's board.

sub _init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo );
    system( 'git', '-C', $repo, 'config', 'user.email', 'me@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Me' );
    return $repo;
}

# A board with a config ref (so require_local_board is satisfied) and whatever
# statuses the caller wants -- the default list unless overridden.
sub _board {
    my (%args) = @_;
    my $repo = _init_repo();
    my $git  = App::karr::Git->new( dir => $repo );
    $git->write_ref( 'refs/karr/config',
        Dump( { version => 1, board => { name => 'T' },
                statuses => $args{statuses} || [qw( backlog todo in-progress review done )] } ) );
    $git->write_ref( 'refs/karr/meta/next-id', "1\n" );
    return App::karr::BoardStore->new( git => $git );
}

sub _add_task {
    my ( $store, %fields ) = @_;
    $store->save_task( App::karr::Task->new( class => 'standard', %fields ) );
}

sub _run {
    my ( $store, %opt ) = @_;
    my $cmd = App::karr::Cmd::Metrics->new(
        store => $store, git => $store->git, role => 'user', %opt );
    my $out;
    my $err = do {
        local $@;
        eval {
            local *STDOUT;
            open STDOUT, '>:encoding(UTF-8)', \$out or die $!;
            $cmd->execute( [], [] );
        };
        $@;
    };
    return ( $err, defined $out ? $out : '' );
}

sub _json {
    my ( $store, %opt ) = @_;
    my ( $err, $out ) = _run( $store, json => 1, %opt );
    is( $err, '', 'metrics --json executes cleanly' ) or diag("died with: $err");
    return decode_json($out);
}

my $NOW = gmtime;

# An RFC3339 stamp in karr's own shape, $hours_ago before this test started.
sub _ago {
    my ($hours_ago) = @_;
    return ( $NOW - $hours_ago * 3600 )->datetime . 'Z';
}

subtest 'throughput counts completions inside the fixed 7d and 30d windows' => sub {
    my $store = _board();
    _add_task( $store, id => 1, title => 'Two days ago', status => 'done',
        created => _ago( 24 * 5 ), started => _ago( 24 * 3 ), completed => _ago( 24 * 2 ) );
    _add_task( $store, id => 2, title => 'Ten days ago', status => 'done',
        created => _ago( 24 * 20 ), started => _ago( 24 * 12 ), completed => _ago( 24 * 10 ) );
    _add_task( $store, id => 3, title => 'Forty days ago', status => 'done',
        created => _ago( 24 * 50 ), started => _ago( 24 * 45 ), completed => _ago( 24 * 40 ) );
    _add_task( $store, id => 4, title => 'Not finished', status => 'todo',
        created => _ago( 24 * 2 ) );

    my $m = _json($store);
    is( $m->{throughput_7d},  1, 'only the two-day-old completion is inside 7d' );
    is( $m->{throughput_30d}, 2, 'the ten-day-old one joins it inside 30d' );
    is( $m->{lead_samples},   3, 'all three completions feed the lead average' );

    my ( undef, $text ) = _run($store);
    like( $text, qr/^Throughput 7d:\s+1 task$/m,  'the default render says 1 task, not "1 tasks"' );
    like( $text, qr/^Throughput 30d:\s+2 tasks$/m, 'and pluralizes the other' );
};

subtest 'lead time is created->completed, cycle time is started->completed' => sub {
    my $store = _board();
    # 10 days from creation to completion, of which the last 24 hours were
    # spent actually working on it.
    _add_task( $store, id => 1, title => 'Slow queue, fast work', status => 'done',
        created => _ago( 24 * 10 ), started => _ago( 24 ), completed => _ago( 0 ) );

    my $m = _json($store);
    cmp_ok( abs( $m->{avg_lead_time_hours} - 240 ), '<', 0.05,
        'lead time spans the whole life of the card (240h), queue time included' );
    cmp_ok( abs( $m->{avg_cycle_time_hours} - 24 ), '<', 0.05,
        'cycle time spans only the part after it was started (24h)' );
    cmp_ok( abs( $m->{flow_efficiency} - 0.1 ), '<', 0.001,
        'flow efficiency is the cycle share of the lead time' );

    my ( undef, $text ) = _run($store);
    like( $text, qr/^Avg lead time:\s+10d 0h \(over 1 task\)$/m,
        'the human render carries the sample count with the average' );
    like( $text, qr/^Avg cycle time:\s+1d 0h \(over 1 task\)$/m, 'for both averages' );
    like( $text, qr/^Flow efficiency:\s+10\.0%$/m, 'and the efficiency as a percentage' );
};

subtest 'flow efficiency divides by the lead time of the tasks it measured' => sub {
    # The kanban-md arithmetic -- avg_cycle / avg_lead -- takes its two averages
    # over different populations when a completed card carries no start, and
    # then reports an efficiency that can exceed 100%. Here: cycle avg is 24h
    # (one card), lead avg is (240 + 2)/2 = 121h, so its ratio would be 19.8%
    # for a board on which the only measured card spent 10% of its life being
    # worked on. karr pairs the two, so the second card changes the averages
    # without corrupting the ratio.
    my $store = _board();
    _add_task( $store, id => 1, title => 'Measured', status => 'done',
        created => _ago( 24 * 10 ), started => _ago( 24 ), completed => _ago( 0 ) );
    _add_task( $store, id => 2, title => 'Imported, never started', status => 'done',
        created => _ago( 2 ), completed => _ago( 0 ) );

    my $m = _json($store);
    is( $m->{lead_samples},  2, 'both completed cards feed the lead average' );
    is( $m->{cycle_samples}, 1, 'only the one with a start feeds the cycle average' );
    cmp_ok( abs( $m->{avg_lead_time_hours} - 121 ), '<', 0.05,
        'the lead average is taken over both, as in kanban-md' );
    cmp_ok( abs( $m->{flow_efficiency} - 0.1 ), '<', 0.001,
        'but the efficiency stays the paired ratio (10%), not 24/121' );
    cmp_ok( $m->{flow_efficiency}, '<=', 1, 'and can never exceed 100%' );
};

subtest 'aging work items: started, still open, oldest first' => sub {
    my $store = _board();
    _add_task( $store, id => 1, title => 'Young', status => 'in-progress',
        created => _ago( 24 * 3 ), started => _ago( 5 ) );
    _add_task( $store, id => 2, title => 'Old', status => 'review',
        created => _ago( 24 * 9 ), started => _ago( 24 * 8 ) );
    _add_task( $store, id => 3, title => 'Never started', status => 'todo',
        created => _ago( 24 * 4 ) );
    _add_task( $store, id => 4, title => 'Finished', status => 'done',
        created => _ago( 24 * 4 ), started => _ago( 24 * 3 ), completed => _ago( 24 * 2 ) );

    my $m = _json($store);
    is( scalar @{ $m->{aging_items} }, 2,
        'only the two started-but-open cards age' );
    is_deeply( [ map { $_->{id} } @{ $m->{aging_items} } ], [ 2, 1 ],
        'oldest first -- refs come back unordered, so the sort is the command\'s job' );
    cmp_ok( abs( $m->{aging_items}[0]{age_hours} - 192 ), '<', 0.05,
        'the age is measured from `started`, not from `created`' );
    is( $m->{aging_items}[0]{status}, 'review', 'each item carries its status' );

    my ( undef, $text ) = _run($store);
    like( $text, qr/^- 2 \| Old \| review \| age:8d 0h$/m,
        'rendered in the `- id | title | meta` line shape `karr board` uses' );

    my ( undef, $compact ) = _run( $store, compact => 1 );
    like( $compact, qr/^Aging: #2 \[review\] Old \(8d 0h\)$/m,
        'and in kanban-md\'s shape under --compact' );
    like( $compact, qr/^Throughput: 1\/7d 1\/30d \| Lead: /m,
        'whose first line is the one-line summary' );
};

subtest 'terminal statuses come from the board config, not from a literal "done"' => sub {
    # The #67/#98/#101 rule: a board imported from kanban-md can end in
    # `shipped`, and a card parked there is finished work -- not work that has
    # been aging since the day it started.
    my $store = _board( statuses => [qw( backlog todo in-progress shipped )] );
    _add_task( $store, id => 1, title => 'Shipped, no completion stamp',
        status => 'shipped', created => _ago( 24 * 9 ), started => _ago( 24 * 8 ) );
    _add_task( $store, id => 2, title => 'Really in flight', status => 'in-progress',
        created => _ago( 24 * 2 ), started => _ago( 24 ) );

    my $m = _json($store);
    is_deeply( [ map { $_->{id} } @{ $m->{aging_items} } ], [2],
        'the card in the board\'s own terminal column does not age' );
};

subtest 'archived work is out of every figure' => sub {
    my $store = _board();
    _add_task( $store, id => 1, title => 'Archived', status => 'archived',
        created => _ago( 24 * 3 ), started => _ago( 24 * 2 ), completed => _ago( 24 ) );

    my $m = _json($store);
    is( $m->{throughput_7d}, 0, 'an archived completion is not throughput' );
    is( $m->{lead_samples},  0, 'nor a lead-time sample' );
    ok( !exists $m->{avg_lead_time_hours},
        'an average with no samples is omitted rather than reported as 0' );
    is_deeply( $m->{aging_items}, [],
        'aging_items is always present, as an empty array when nothing ages' );
};

subtest '--since narrows the completions but leaves the aging list alone' => sub {
    my $store = _board();
    _add_task( $store, id => 1, title => 'Old completion', status => 'done',
        created => _ago( 24 * 40 ), started => _ago( 24 * 35 ), completed => _ago( 24 * 30 ) );
    _add_task( $store, id => 2, title => 'Recent completion', status => 'done',
        created => _ago( 24 * 3 ), started => _ago( 24 * 2 ), completed => _ago( 24 ) );
    _add_task( $store, id => 3, title => 'In flight', status => 'in-progress',
        created => _ago( 24 * 20 ), started => _ago( 24 * 15 ) );

    my $cutoff = ( $NOW - 10 * 24 * 3600 )->strftime('%Y-%m-%d');
    my $m = _json( $store, since => $cutoff );
    is( $m->{lead_samples}, 1, 'the completion older than --since is dropped' );
    is_deeply( [ map { $_->{id} } @{ $m->{aging_items} } ], [3],
        'the card that was started long before it is not, because it never completed' );
};

subtest '--since must be a real calendar date, and says so as a usage error' => sub {
    my $store = _board();
    for my $bad ( 'yesterday', '2026-02-30' ) {
        my ( $err, undef ) = _run( $store, since => $bad );
        like( $err, qr/^Usage error: invalid --since date "\Q$bad\E"/,
            "--since $bad is refused as a usage error (exit 2), naming the option" );
    }
};

subtest 'an empty board says so instead of printing a page of zeroes' => sub {
    my $store = _board();
    my ( $err, $text ) = _run($store);
    is( $err, '', 'metrics on an empty board is not an error' ) or diag("died with: $err");
    like( $text, qr/^Avg lead time:\s+--$/m, 'an average with no data is --, not 0h 0m' );
    like( $text, qr/^Flow efficiency:\s+--$/m, 'and so is the efficiency' );
    like( $text, qr/Nothing to measure yet/,
        'and the render says why every figure is blank' );

    my $m = _json($store);
    is( $m->{throughput_7d}, 0, 'the JSON payload still carries the real zero' );
    ok( !exists $m->{flow_efficiency}, 'and omits the metrics it could not compute' );
};

subtest 'stamps karr did not write: kanban-md offsets, and a legacy bare date' => sub {
    my $store = _board();
    # kanban-md writes Go's RFC3339Nano off the local clock: fraction and a
    # numeric offset. Read as UTC (offset ignored) this card's cycle time would
    # be two hours out.
    my $started_local   = ( $NOW - 26 * 3600 + 2 * 3600 )->datetime . '.449764553+02:00';
    my $completed_local = ( $NOW - 2 * 3600 + 2 * 3600 )->datetime . '.113000000+02:00';
    _add_task( $store, id => 1, title => 'From kanban-md', status => 'done',
        created   => ( $NOW - 24 * 3600 * 2 )->datetime . 'Z',
        started   => $started_local,
        completed => $completed_local );
    # A karr `started` from before ticket #68, when it was stamped as a bare
    # date.
    _add_task( $store, id => 2, title => 'Pre-0.403 board', status => 'in-progress',
        created => _ago( 24 * 4 ),
        started => ( $NOW - 24 * 3600 * 2 )->strftime('%Y-%m-%d') );

    my $m = _json($store);
    is( $m->{unusable_timestamps}, 0, 'both shapes are understood' );
    cmp_ok( abs( $m->{avg_cycle_time_hours} - 24 ), '<', 0.05,
        'the +02:00 offset is honoured, not read as UTC' );
    is( scalar @{ $m->{aging_items} }, 1, 'the bare-date start still ages a card' );
    cmp_ok( $m->{aging_items}[0]{age_hours}, '>', 24,
        'from midnight of that date' );
};

subtest 'a timestamp karr cannot read is reported, never silently dropped' => sub {
    my $store = _board();
    _add_task( $store, id => 1, title => 'Hand-edited', status => 'done',
        created => _ago( 24 * 3 ), started => _ago( 24 * 2 ), completed => 'last tuesday' );
    _add_task( $store, id => 2, title => 'Fine', status => 'done',
        created => _ago( 24 * 2 ), started => _ago( 24 ), completed => _ago( 0 ) );

    my $m = _json($store);
    is( $m->{unusable_timestamps}, 1, 'the card with the unreadable stamp is counted' );
    is( $m->{lead_samples}, 1, 'and left out of the averages' );
    is_deeply( $m->{aging_items}, [],
        'but not reported as aging: it is finished work, not work in flight' );

    my ( undef, $text ) = _run($store);
    like( $text, qr/^Note: 1 task carries a timestamp karr could not use/m,
        'the human render names what was left out' );
};

subtest 'a start that precedes its own card contributes no cycle time' => sub {
    # Found by running this command against karr's own board: it reported a
    # flow efficiency of 107.3%, which describes nothing. karr wrote `started`
    # as a bare date until ticket #68, and a bare date reads as midnight -- so a
    # ticket filed at 15:49 and picked up the same afternoon carries a start six
    # hours before it existed, and its "cycle time" exceeds its lead time. 75 of
    # the 116 finished tickets on karr's own board carry such a stamp.
    my $store = _board();
    my $day = ( $NOW - 24 * 3600 )->strftime('%Y-%m-%d');
    _add_task( $store, id => 1, title => 'Filed and picked up the same day',
        status => 'done',
        created => "${day}T15:49:02Z", started => $day,
        completed => "${day}T18:00:00Z" );
    _add_task( $store, id => 2, title => 'Sound stamps', status => 'done',
        created => _ago( 24 * 10 ), started => _ago( 24 ), completed => _ago( 0 ) );
    _add_task( $store, id => 3, title => 'Still in flight', status => 'in-progress',
        created => "${day}T15:49:02Z", started => $day );

    my $m = _json($store);
    is( $m->{lead_samples}, 2,
        'the card still has a lead time -- created and completed are both sound' );
    is( $m->{cycle_samples}, 1, 'but contributes no cycle time' );
    cmp_ok( abs( $m->{flow_efficiency} - 0.1 ), '<', 0.001,
        'so the efficiency is the sound card\'s 10%, not something over 100%' );
    is( $m->{unusable_timestamps}, 2, 'both impossible starts are counted' );
    is_deeply( [ map { $_->{id} } @{ $m->{aging_items} } ], [3],
        'and the open one still ages: a bare-date start is precise enough for that' );

    my ( undef, $text ) = _run($store);
    like( $text, qr/^Note: 2 tasks carry a timestamp karr could not use/m,
        'the note says how many cards the averages left out' );
    like( $text, qr/start that precedes the card's own creation/,
        'and why, so the number is not just smaller than expected' );
};

subtest 'a repository with no board refuses instead of reporting zeroes' => sub {
    my $repo  = _init_repo();
    my $git   = App::karr::Git->new( dir => $repo );
    my $store = App::karr::BoardStore->new( git => $git );
    my ( $err, undef ) = _run($store);
    like( $err, qr/^No karr board in this repository/,
        'the #135 refusal applies here too -- "throughput 0" would read as a board that shipped nothing' );
};

done_testing;
