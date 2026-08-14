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

# karr board ticket #140: the ordering guard `karr metrics` applies to cycle
# time, and what `unusable_timestamps` means once it is there.
#
# t/137-metrics.t pins the first guard -- a `started` that precedes its own
# card's `created` measures nothing, so it contributes no cycle time and is
# counted as unusable. That guard stopped guarding when `karr repair` learned to
# clamp such a start up to `created` (ticket #138): after the clamp
# `started >= $created` holds by construction on every card it touched, so the
# check excludes nothing -- while the same pre-#68 karr also wrote `completed`
# as a bare date, which reads as midnight and now falls *below* the clamped
# start. On karr's own board that was 42 negative samples out of 117, an average
# cycle time of 16 minutes, and `unusable_timestamps` reporting 0: the figure
# whose whole job is to say what is missing from the averages, saying nothing.
#
# So the cycle time carries a second ordering check of its own -- a cycle time
# may not be negative -- counted into `unusable_timestamps` exactly the way the
# start check is, so the note keeps naming what was left out.
#
# What this file pins, beyond "the number moved":
#
#   * the excluded card still contributes its lead time, negative and visible.
#     Whether lead time gets a symmetric guard is ticket #139's decision, and
#     this test is here so that decision has to be taken rather than drifted
#     into;
#   * `unusable_timestamps` counts cards, not stamps: a card with two ordering
#     faults counts once;
#   * `completed == started` is measurable, not impossible -- karr stamps both
#     at the same instant for a card dragged straight into a terminal status,
#     and a zero cycle time is a real measurement of that;
#   * the JSON count and the human note state the same figure.
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

sub _board {
    my $repo = _init_repo();
    my $git  = App::karr::Git->new( dir => $repo );
    $git->write_ref( 'refs/karr/config',
        Dump( { version => 1, board => { name => 'T' },
                statuses => [qw( backlog todo in-progress review done )] } ) );
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

sub _ago {
    my ($hours_ago) = @_;
    return ( $NOW - $hours_ago * 3600 )->datetime . 'Z';
}

subtest 'a completion that precedes its start contributes no cycle time' => sub {
    my $store = _board();
    # The shape `karr repair` leaves behind on a pre-#68 board: the start was a
    # bare date, has been clamped up to `created`, and the completion is still
    # the bare date it always was -- midnight of a day that ended before the
    # card was even filed. Counted, it is a cycle time of about -16 hours.
    my $day = ( $NOW - 24 * 3600 )->strftime('%Y-%m-%d');
    _add_task( $store, id => 1, title => 'Clamped start over a bare completion',
        status  => 'done',
        created => "${day}T15:49:02Z",
        started => "${day}T15:49:02Z",
        completed => $day );
    # 10 days queued, 1 day worked: the same sound card t/137-metrics.t uses.
    _add_task( $store, id => 2, title => 'Sound stamps', status => 'done',
        created => _ago( 24 * 10 ), started => _ago( 24 ), completed => _ago( 0 ) );

    my $m = _json($store);
    is( $m->{cycle_samples}, 1,
        'only the sound card feeds the cycle average -- a cycle time may not be negative' );
    cmp_ok( abs( $m->{avg_cycle_time_hours} - 24 ), '<', 0.05,
        'so the average is the sound card\'s 24h, not the 4h the two of them average to' );
    is( $m->{unusable_timestamps}, 1,
        'and the excluded card is counted, not dropped silently' );
    cmp_ok( abs( $m->{flow_efficiency} - 0.1 ), '<', 0.001,
        'the efficiency is the sound card\'s 10%, over its own lead time' );

    # Ticket #139's boundary, pinned rather than assumed: the lead time of the
    # excluded card is still computed, and is still allowed to be impossible.
    is( $m->{lead_samples}, 2,
        'the card still contributes a lead time -- `created` and `completed` both parse' );
    cmp_ok( $m->{avg_lead_time_hours}, '<', 240,
        'and that lead time is negative, left visible rather than clamped (ticket #139)' );
};

subtest 'the note and the JSON count say the same thing' => sub {
    my $store = _board();
    my $day = ( $NOW - 24 * 3600 )->strftime('%Y-%m-%d');
    _add_task( $store, id => 1, title => 'Completion below its start', status => 'done',
        created => "${day}T15:49:02Z", started => "${day}T15:49:02Z", completed => $day );
    _add_task( $store, id => 2, title => 'Sound stamps', status => 'done',
        created => _ago( 24 * 10 ), started => _ago( 24 ), completed => _ago( 0 ) );

    my ( undef, $text ) = _run($store);
    like( $text, qr/^Avg cycle time:\s+1d 0h \(over 1 task\)$/m,
        'the human render states the sample count the exclusion left' );
    like( $text, qr/^Note: 1 task carries a timestamp karr could not use/m,
        'and names the card that is missing from it' );
    like( $text, qr/completion that\n\s*precedes that start/,
        'the note says which fault, so the reader can go and look at the card' );

    my ( undef, $compact ) = _run( $store, compact => 1 );
    like( $compact, qr/^Note: 1 task carries a timestamp karr could not use/m,
        'the compact rendering carries the same note' );

    my $m = _json($store);
    is( $m->{unusable_timestamps}, 1,
        'and --json reports the same figure the note states' );
};

subtest 'unusable_timestamps counts cards, not stamps' => sub {
    my $store = _board();
    # Two ordering faults on one card: a start below its own creation (the
    # pre-clamp shape) and a completion below that start.
    my $day = ( $NOW - 24 * 3600 )->strftime('%Y-%m-%d');
    my $earlier = ( $NOW - 48 * 3600 )->strftime('%Y-%m-%d');
    _add_task( $store, id => 1, title => 'Both stamps out of order', status => 'done',
        created => "${day}T15:49:02Z", started => $day, completed => $earlier );

    my $m = _json($store);
    is( $m->{unusable_timestamps}, 1,
        'a card carrying two faults is one card missing from the averages, counted once' );
    is( $m->{cycle_samples}, 0, 'and contributes no cycle time' );
};

subtest 'a card finished the instant it started is measurable, not impossible' => sub {
    # karr stamps `started` and `completed` together for a card dragged straight
    # into a terminal status (App::karr::Task::update_timestamps). Its cycle time
    # is zero, and zero is a measurement -- the guard is `completed >= started`
    # for exactly this reason.
    my $store = _board();
    my $moment = _ago( 24 );
    _add_task( $store, id => 1, title => 'Straight to done', status => 'done',
        created => _ago( 24 * 3 ), started => $moment, completed => $moment );

    my $m = _json($store);
    is( $m->{cycle_samples}, 1, 'the card feeds the cycle average' );
    is( $m->{avg_cycle_time_hours}, 0, 'with a cycle time of zero' );
    is( $m->{unusable_timestamps}, 0, 'and nothing about it is unusable' );
    is( $m->{flow_efficiency}, 0,
        'a flow efficiency of 0% -- all queue, no work time' );

    my ( undef, $text ) = _run($store);
    unlike( $text, qr/^Note:/m, 'so the render carries no note' );
};

subtest 'a card with no start at all is still not counted as unusable' => sub {
    # The pre-existing rule, kept: a missing stamp is not an unusable one. The
    # per-average sample counts are what say the card was not measured.
    my $store = _board();
    _add_task( $store, id => 1, title => 'Imported, never started', status => 'done',
        created => _ago( 24 * 2 ), completed => _ago( 0 ) );

    my $m = _json($store);
    is( $m->{unusable_timestamps}, 0, 'nothing on the card is unusable' );
    is( $m->{lead_samples},  1, 'it has a lead time' );
    is( $m->{cycle_samples}, 0, 'and no cycle time, which the sample counts state' );
};

done_testing;
