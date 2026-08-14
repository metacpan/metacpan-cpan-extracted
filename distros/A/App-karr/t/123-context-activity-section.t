use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use YAML::XS qw( Dump );
use JSON::MaybeXS qw( decode_json );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::ActivityLog;
use App::karr::Task;
use App::karr::Cmd::Context;
use MockStore;

# Regression for karr board ticket #92:
#   `Cmd/Context.pm` built its four sections purely from task state and never
#   looked at refs/karr/log/*, even though #64 had already made every mutating
#   command write to it. `karr context` -- the briefing an agent reads before
#   picking up work -- therefore never showed any of the board's activity
#   history.
#
#   The maintainer's decision (ticket #92, 2026-08-10): add the log, but
#   bounded -- the last N entries written by identities *other* than the one
#   invoking `context`, since an agent already knows what it itself just did
#   (`karr show --me` covers that) and the value of a briefing is what
#   everybody else has been doing.

sub _init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo );
    system( 'git', '-C', $repo, 'config', 'user.email', 'me@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name', 'Me' );
    return $repo;
}

sub _run_execute {
    my ( $cmd, @args ) = @_;
    my $out;
    my $err = do {
        local $@;
        eval {
            local *STDOUT;
            # Same layer bin/karr installs via enable_std_utf8: reopening
            # STDOUT drops it, and App::karr::Encoding's POD makes putting it
            # back the in-process capturer's job. Without it the em dash in a
            # noted item (ticket #108) prints wide and warns.
            open STDOUT, '>:encoding(UTF-8)', \$out or die $!;
            $cmd->execute( \@args, [] );
        };
        $@;
    };
    return ( $err, $out );
}

my $repo = _init_repo();
my $git  = App::karr::Git->new( dir => $repo );
$git->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'T' } } ) );
$git->write_ref( 'refs/karr/meta/next-id', "2\n" );
my $store = App::karr::BoardStore->new( git => $git );
$store->save_task(
    App::karr::Task->new(
        id => 1, title => 'Task 1', status => 'todo',
        priority => 'high', class => 'standard',
    )
);

# Two distinct identities sharing this repo's one Git config, disambiguated by
# role the same way App::karr::ActivityLog's own POD describes a human and an
# agent sharing one clone. `context` below always runs as role => 'user', so
# these role => 'agent' entries are "somebody else" to it.
my $other = App::karr::ActivityLog->new( git => $git, role => 'agent' );
$other->log_entry( agent => 'agent-fox', action => 'move', task_id => 1,
    detail => 'in-progress', ts => '2026-01-01T00:00:00Z' );
$other->log_entry( agent => 'agent-fox', action => 'edit', task_id => 1,
    detail => 'in-progress', ts => '2026-01-02T00:00:00Z' );
$other->log_entry( agent => 'agent-owl', action => 'edit', task_id => 1,
    detail => 'in-progress', ts => '2026-01-03T00:00:00Z' );
$other->log_entry( agent => 'agent-owl', action => 'edit', task_id => 1,
    detail => 'in-progress', ts => '2026-01-04T00:00:00Z' );
$other->log_entry( agent => 'agent-owl', action => 'edit', task_id => 1,
    detail => 'in-progress', ts => '2026-01-05T00:00:00Z' );
$other->log_entry( agent => 'agent-owl', action => 'edit', task_id => 1,
    detail => 'in-progress', ts => '2026-01-06T00:00:00Z' );

# This identity's own entry -- context, invoked as role => 'user' below, must
# never show it.
my $mine = App::karr::ActivityLog->new( git => $git, role => 'user' );
$mine->log_entry( agent => 'Me', action => 'create', task_id => 1,
    detail => 'todo', ts => '2026-01-07T00:00:00Z' );

subtest 'the activity section shows other identities, not this one' => sub {
    my $cmd = App::karr::Cmd::Context->new(
        store => $store, git => $git, role => 'user',
        sections => 'activity',
    );
    my ( $err, $out ) = _run_execute($cmd);
    is( $err, '', 'context executes cleanly' ) or diag("died with: $err");

    like( $out, qr/### Recent Activity/, 'the section header is rendered' );
    like( $out, qr/agent-fox/, 'the other identity\'s agent-fox entries show up' )
        or diag("got:\n$out");
    like( $out, qr/agent-owl/, 'and its agent-owl entries too' )
        or diag("got:\n$out");
    unlike( $out, qr/\bcreate\b/, 'but not this identity\'s own create entry' )
        or diag("got:\n$out");
};

subtest 'it is bounded to the last N entries by default (5)' => sub {
    my $cmd = App::karr::Cmd::Context->new(
        store => $store, git => $git, role => 'user',
        sections => 'activity',
    );
    my ( undef, $out ) = _run_execute($cmd);

    my @lines = grep { /^- / } split /\n/, $out;
    is( scalar @lines, 5, 'exactly five entries, not all six' );
    unlike( $out, qr/2026-01-01T00:00:00Z/,
        'the oldest of the six other-agent entries fell off the bound' )
        or diag("got:\n$out");
    like( $out, qr/2026-01-06T00:00:00Z/, 'the newest one is kept' )
        or diag("got:\n$out");
};

subtest '--activity-limit narrows the bound' => sub {
    my $cmd = App::karr::Cmd::Context->new(
        store => $store, git => $git, role => 'user',
        sections => 'activity', activity_limit => 2,
    );
    my ( undef, $out ) = _run_execute($cmd);

    my @lines = grep { /^- / } split /\n/, $out;
    is( scalar @lines, 2, '--activity-limit 2 keeps only two' );
    like( $out, qr/2026-01-06T00:00:00Z/, 'the newest' ) or diag("got:\n$out");
    like( $out, qr/2026-01-05T00:00:00Z/, 'and the second newest' ) or diag("got:\n$out");
};

subtest 'newest first' => sub {
    my $cmd = App::karr::Cmd::Context->new(
        store => $store, git => $git, role => 'user',
        sections => 'activity', activity_limit => 2,
    );
    my ( undef, $out ) = _run_execute($cmd);

    my ($first_ts) = $out =~ /^- (\S+)/m;
    is( $first_ts, '2026-01-06T00:00:00Z', 'the most recent entry leads' )
        or diag("got:\n$out");
};

subtest '--sections omitting activity leaves it out entirely' => sub {
    my $cmd = App::karr::Cmd::Context->new(
        store => $store, git => $git, role => 'user',
        sections => 'blocked',
    );
    my ( undef, $out ) = _run_execute($cmd);
    unlike( $out, qr/Recent Activity/, 'no activity section when not requested' )
        or diag("got:\n$out");
};

subtest '--json carries the section in the same shape as the others' => sub {
    my $cmd = App::karr::Cmd::Context->new(
        store => $store, git => $git, role => 'user',
        sections => 'activity', activity_limit => 3, json => 1,
    );
    my ( $err, $out ) = _run_execute($cmd);
    is( $err, '', 'context --json executes cleanly' ) or diag("died with: $err");

    my $data = decode_json($out);
    is( ref $data->{sections}, 'ARRAY', 'sections is the same top-level array' );
    my ($section) = grep { $_->{name} eq 'activity' } @{ $data->{sections} };
    ok( $section, 'an "activity" section is present, named like the rest' )
        or diag("got:\n$out");
    is( ref $section->{items}, 'ARRAY', 'wrapped in items, like the rest' );
    is( scalar @{ $section->{items} }, 3, 'bounded by --activity-limit' );

    my $item = $section->{items}[0];
    is( $item->{ts}, '2026-01-06T00:00:00Z', 'newest first here too' );
    is( $item->{agent}, 'agent-owl', 'carries the acting agent' );
    is( $item->{action}, 'edit', 'and the action' );
    is( $item->{task_id}, 1, 'and the task id' );
    is( $item->{detail}, 'in-progress', 'and the detail, when present' );
};

subtest '--activity-limit below 1 is a usage error, not a silent surprise' => sub {
    # The bound is the whole point of the section, and the two out-of-range
    # values failed in opposite, equally silent directions: the falsy guard in
    # _recent_activity read 0 as "no bound", pouring the entire log into the
    # briefing the option exists to keep short, and a negative produced an
    # empty section with exit 0 -- indistinguishable from "nobody else acted".
    # `show --last` settled this for count options in ticket #76 / ADR 0002.
    for my $bad ( 0, -3 ) {
        my $cmd = App::karr::Cmd::Context->new(
            store => $store, git => $git, role => 'user',
            sections => 'activity', activity_limit => $bad,
        );
        my ( $err, $out ) = _run_execute($cmd);
        like( $err, qr/^Usage error: --activity-limit must be 1 or greater/,
            "--activity-limit $bad is refused as a usage error" )
            or diag( "got err: $err\nout:\n" . ( $out // '' ) );
        unlike( $out // '', qr/Recent Activity/,
            "--activity-limit $bad renders no section at all" );
    }
};

subtest 'a store double with no git-backed log renders no activity section' => sub {
    # Regression guard: MockStore's git double used to answer every
    # unrecognised call (list_refs, read_ref included) with a bare `1` via
    # AUTOLOAD, which _recent_activity would have tried to decode as a log
    # entry and crashed on ($e->{ts}) against a non-reference. MockStore now
    # stubs list_refs/read_ref explicitly; this exercises that stub through
    # the real command the way t/07 and t/108 already drive Context.
    my $cmd = App::karr::Cmd::Context->new(
        store => MockStore->new(
            tasks => [ App::karr::Task->new(
                id => 1, title => 'Solo', status => 'todo', priority => 'high',
            ) ],
        ),
    );
    my ( $err, $out ) = _run_execute($cmd);
    is( $err, '', 'context does not die without a real git-backed log' )
        or diag("died with: $err");
    unlike( $out, qr/Recent Activity/, 'and simply omits the section' )
        or diag("got:\n$out");
};

done_testing;
