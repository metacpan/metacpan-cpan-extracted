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

# karr board ticket #139: what `karr metrics` does about a `completed` stamp
# that precedes its own card's `created`.
#
# The decision, taken on the ticket and pinned here so it cannot be drifted out
# of: no clamp, and no migration. `created` and `completed` are original data,
# unlike `started` -- which karr manufactured and `karr repair` rewrites (#138)
# -- so a negative lead time is real evidence of a bad completion, and every
# value it could be clamped to would be an invention: `created` is too early,
# `started` asserts a zero cycle time, and the end of the day a bare date bounds
# was never written down. The sample therefore stays in the lead average,
# negative, and the command's job is to make sure no reader mistakes the
# resulting figure for a measurement.
#
# So what this file pins is the *qualification*, not a correction:
#
#   * the negative sample is still in `lead_samples` and still moves
#     `avg_lead_time_hours` downward -- t/141 pins the boundary from the other
#     side (the cycle average excludes it), this one pins that lead does not;
#   * `negative_lead_samples` counts exactly those cards, is always present in
#     --json including as 0, and never exceeds `lead_samples`;
#   * it is *not* folded into `unusable_timestamps`, whose definition (#140) is
#     "cards missing from at least one average" -- these are missing from
#     nothing. The two counters stay distinct, and one card can be in both;
#   * the human and compact renderings both carry the note, and the note states
#     the same figure --json does.
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

# The pre-#68 shape: a card filed at 15:49 and finished the same day, whose
# completion was written as a bare `YYYY-MM-DD` and so reads as the midnight
# *before* it was created. A lead time of about -16 hours.
sub _bare_date_completion {
    my ($store) = @_;
    my $day = ( $NOW - 24 * 3600 )->strftime('%Y-%m-%d');
    _add_task( $store, id => 1, title => 'Bare-date completion', status => 'done',
        created => "${day}T15:49:02Z", started => "${day}T15:49:02Z",
        completed => $day );
    return;
}

subtest 'the impossible lead time stays in the average, unclamped' => sub {
    my $store = _board();
    _bare_date_completion($store);
    # 10 days queued, 1 day worked: the sound card the other metrics tests use.
    _add_task( $store, id => 2, title => 'Sound stamps', status => 'done',
        created => _ago( 24 * 10 ), started => _ago( 24 ), completed => _ago( 0 ) );

    my $m = _json($store);
    is( $m->{lead_samples}, 2,
        'the impossible card is still a lead sample -- no clamp, no exclusion' );
    cmp_ok( $m->{avg_lead_time_hours}, '<', 240,
        'and it drags the average below the sound card\'s own 240h' );
    cmp_ok( $m->{avg_lead_time_hours}, '>', 100,
        'by roughly the -16h it really is, not by a value karr invented for it' );
    is( $m->{negative_lead_samples}, 1,
        'the sample is counted instead of corrected: that is the whole fix' );
    cmp_ok( $m->{negative_lead_samples}, '<=', $m->{lead_samples},
        'a negative lead sample is by definition also a lead sample' );
};

subtest 'negative lead samples are not unusable timestamps' => sub {
    # #140 defined `unusable_timestamps` as cards missing from at least one
    # average. A card excluded from the cycle average for its ordering is one;
    # a negative lead time is not, because it is missing from nothing. Folding
    # the two together would make the counter mean neither thing.
    my $store = _board();
    _bare_date_completion($store);

    my $m = _json($store);
    is( $m->{negative_lead_samples}, 1, 'the negative lead sample is counted' );
    is( $m->{unusable_timestamps}, 1,
        'and the same card is unusable for the cycle average -- one card, two counters' );
    is( $m->{cycle_samples}, 0, 'which is what it is missing from' );

    # The distinction the other way round: a card whose start is unreadable is
    # missing from the cycle average, but its lead time is sound.
    my $store2 = _board();
    _add_task( $store2, id => 1, title => 'Unreadable start', status => 'done',
        created => _ago( 48 ), started => 'yesterday', completed => _ago( 0 ) );

    my $m2 = _json($store2);
    is( $m2->{unusable_timestamps}, 1, 'unusable counts the unreadable start' );
    is( $m2->{negative_lead_samples}, 0,
        'and nothing is negative -- the counters do not track each other' );
};

subtest 'a card can be in both counters at once' => sub {
    # Unreadable `started` (missing from the cycle average) plus a completion
    # below its own creation (present in the lead average, and impossible).
    my $store = _board();
    my $day = ( $NOW - 24 * 3600 )->strftime('%Y-%m-%d');
    _add_task( $store, id => 1, title => 'Both faults', status => 'done',
        created => "${day}T15:49:02Z", started => 'sometime', completed => $day );

    my $m = _json($store);
    is( $m->{unusable_timestamps},   1, 'counted as missing from the cycle average' );
    is( $m->{negative_lead_samples}, 1, 'and as an impossible sample inside the lead one' );
    is( $m->{lead_samples},  1, 'the lead average still has it' );
    is( $m->{cycle_samples}, 0, 'the cycle average does not' );
};

subtest 'the counter is always present, including as zero' => sub {
    # A consumer must be able to tell "no impossible samples" from "this karr
    # does not report them"; the averages are omitted when empty, the counts
    # never are.
    my $store = _board();
    _add_task( $store, id => 1, title => 'Sound stamps', status => 'done',
        created => _ago( 24 * 10 ), started => _ago( 24 ), completed => _ago( 0 ) );

    my $m = _json($store);
    ok( exists $m->{negative_lead_samples}, 'the key is there on a clean board' );
    is( $m->{negative_lead_samples}, 0, 'reporting a real zero' );

    my $empty = _board();
    my $e = _json($empty);
    ok( exists $e->{negative_lead_samples}, 'and on a board with nothing on it' );
    is( $e->{negative_lead_samples}, 0, 'also zero' );
    ok( !exists $e->{avg_lead_time_hours},
        'while the average it qualifies is omitted, as before' );
};

subtest 'both renderings say it, and say the same number' => sub {
    my $store = _board();
    _bare_date_completion($store);
    _add_task( $store, id => 2, title => 'Sound stamps', status => 'done',
        created => _ago( 24 * 10 ), started => _ago( 24 ), completed => _ago( 0 ) );

    my ( undef, $text ) = _run($store);
    like( $text, qr/^Note: 1 of the 2 lead times behind the average above is negative/m,
        'the default rendering states the count against the sample total' );
    like( $text, qr/Nothing is clamped/,
        'and says the figure was left alone rather than corrected' );
    like( $text, qr/finer than the data underneath it/,
        'and that an hour-precise average over day-granular stamps overstates itself' );
    like( $text, qr/Note: 1 of the 2 lead times.*?Note: 1 task carries a timestamp/s,
        'the lead caveat comes before the note about what was left out entirely' );

    my ( undef, $compact ) = _run( $store, compact => 1 );
    like( $compact, qr/^Note: 1 of the 2 lead times behind the average above is negative/m,
        'the compact rendering carries the caveat too -- brevity does not drop it' );
    like( $compact, qr/^Note: 1 task carries a timestamp karr could not use/m,
        'alongside the pre-existing one' );

    my $m = _json($store);
    is( $m->{negative_lead_samples}, 1, '--json reports the same figure the note states' );
};

subtest 'a clean board carries no lead note at all' => sub {
    my $store = _board();
    _add_task( $store, id => 1, title => 'Sound stamps', status => 'done',
        created => _ago( 24 * 10 ), started => _ago( 24 ), completed => _ago( 0 ) );

    my ( undef, $text ) = _run($store);
    unlike( $text, qr/lead times behind the average/,
        'no caveat where there is nothing to caveat' );
    unlike( $text, qr/^Note:/m, 'and no note of any kind' );
};

subtest 'a lead time of exactly zero is a measurement, not a negative' => sub {
    # `created == completed` for a card filed and finished in the same second:
    # the guard is `< 0`, not `<= 0`, for the same reason the cycle guard is
    # `>=` -- zero is a real duration.
    my $store = _board();
    my $moment = _ago( 24 );
    _add_task( $store, id => 1, title => 'Filed and finished at once', status => 'done',
        created => $moment, started => $moment, completed => $moment );

    my $m = _json($store);
    is( $m->{lead_samples},           1, 'the card feeds the lead average' );
    is( $m->{avg_lead_time_hours},    0, 'with a lead time of zero' );
    is( $m->{negative_lead_samples},  0, 'and zero is not negative' );
    is( $m->{unusable_timestamps},    0, 'nor unusable' );
};

subtest '--since narrows the count with the population it counts over' => sub {
    # The counter has to be taken after the filter, like `unusable_timestamps`:
    # a card the caller asked to leave out must not be reported as one dragging
    # an average it is not in.
    my $store = _board();
    my $old_day = ( $NOW - 24 * 40 * 3600 )->strftime('%Y-%m-%d');
    _add_task( $store, id => 1, title => 'Old bare-date completion', status => 'done',
        created => "${old_day}T15:49:02Z", started => "${old_day}T15:49:02Z",
        completed => $old_day );
    _add_task( $store, id => 2, title => 'Sound stamps', status => 'done',
        created => _ago( 24 * 10 ), started => _ago( 24 ), completed => _ago( 0 ) );

    my $all = _json($store);
    is( $all->{negative_lead_samples}, 1, 'counted over the whole board' );

    my $since = ( $NOW - 24 * 20 * 3600 )->strftime('%Y-%m-%d');
    my $m = _json( $store, since => $since );
    is( $m->{lead_samples}, 1, 'the old card is out of the population' );
    is( $m->{negative_lead_samples}, 0,
        'and out of the count -- the caveat describes what was measured' );
};

done_testing;
