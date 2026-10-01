use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use Path::Tiny qw( path );
use File::Temp qw( tempdir );
use JSON::MaybeXS qw( decode_json );
use Time::Piece;

use App::karr::Config;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Foundation;
use App::karr::Foundation::Executor;
use App::karr::Foundation::Picker;

# Ticket k306: backlog is held back. Three stages, three meanings (CONTEXT.md):
#
#   * backlog -- filed and held back; nobody takes it automatically
#   * todo    -- released; `karr pick` and karr-foundation may take it
#   * a claim -- the card is being worked right now
#
# So a card in backlog is never pickable (`karr pick`, whatever its filters,
# and karr-foundation's ticket selection, which asks the same rule), is not
# actionable for karr-foundation (a board with only backlog left is drained),
# cannot gain a claim (create/edit/move --claim are refused), and a move into
# backlog releases the claim the card carried. `backlog -> in-progress --claim`
# directly stays allowed: the claim lands on in-progress.
#
# The held-back status is the status named `backlog`, hardcoded rather than a
# per-status config flag: kanban-md drops a status key it does not know when it
# rewrites config.yml, so a materialize -> kanban-md -> import round trip would
# silently lose the hold. A board without a backlog column behaves as before.

# Foundation reads ~/.config/karr-foundation/config.yml by default; keep the
# machine's own out of this file.
local $ENV{HOME} = tempdir( CLEANUP => 1 );

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub _repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo )                                     == 0 or die 'git init';
    system( 'git', '-C', "$repo", 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
    system( 'git', '-C', "$repo", 'config', 'user.name', 'Test User' )         == 0 or die 'git config';
    return "$repo";
}

sub _board {
    my $repo = _repo();
    my $rv = run_karr( $repo, 'init', '--name', 'k306 Board' );
    is( $rv->{exit}, 0, 'setup: karr init' ) or diag $rv->{stderr};
    return $repo;
}

sub _store {
    my ($repo) = @_;
    return App::karr::BoardStore->new( git => App::karr::Git->new( dir => $repo ) );
}

sub _task {
    my ( $repo, $id ) = @_;
    return App::karr::Git->new( dir => $repo )->load_task_ref( $id // 1 );
}

# A card with KARR_CLAIM unset, so any claim it ends up with came from the
# command under test.
sub _card {
    my ( $repo, $title, @opt ) = @_;
    local $ENV{KARR_CLAIM};
    delete $ENV{KARR_CLAIM};
    my $rv = run_karr( $repo, 'create', $title, @opt );
    is( $rv->{exit}, 0, "setup: create '$title' @opt" ) or diag $rv->{stderr};
}

sub _task_count {
    my ($repo) = @_;
    return scalar grep { defined } _store($repo)->load_tasks;
}

# A card written straight through the store, for fixtures no command may
# produce any more -- a claim on a backlog card, written before k306.
sub _raw_card {
    my ( $repo, %a ) = @_;
    my $store = _store($repo);
    my $id    = $store->allocate_next_id;
    $store->save_task( App::karr::Task->new( id => $id, title => "task $id", %a ) );
    return $id;
}

# ---------------------------------------------------------------------------
# The predicate
# ---------------------------------------------------------------------------

subtest 'is_held_back_status: backlog, and only on a board that has it' => sub {
    ok( App::karr::Config->is_held_back_status('backlog'),
        'on the class (the default board) backlog is held back' );
    ok( !App::karr::Config->is_held_back_status($_), "$_ is not" )
        for qw( todo in-progress review done archived );
    ok( !App::karr::Config->is_held_back_status(undef), 'undef is not' );

    my $default = App::karr::Config->from_merged( App::karr::Config->effective_config );
    ok( $default->is_held_back_status('backlog'), 'a default board instance agrees' );
    is( $default->promotion_status, 'todo', 'and promotes a held-back card to todo' );

    my $no_backlog = App::karr::Config->from_merged( App::karr::Config->effective_config(
        { statuses => [ 'todo', { name => 'doing', require_claim => 1 }, 'done' ] } ) );
    ok( !$no_backlog->is_held_back_status('backlog'),
        'a board without a backlog column holds nothing back' );
    is( $no_backlog->promotion_status, undef, 'and has nothing to promote to' );

    my $ready = App::karr::Config->from_merged( App::karr::Config->effective_config(
        { statuses => [ 'backlog', 'ready', { name => 'doing', require_claim => 1 }, 'done' ] } ) );
    is( $ready->promotion_status, 'ready',
        'the promotion target is the board\'s next column, not the literal todo' );

    my $repo = _board();
    ok( _store($repo)->is_held_back_status('backlog'), 'BoardStore wraps it for the board' );
    ok( !_store($repo)->is_held_back_status('todo'),   'todo is released' );
};

# ---------------------------------------------------------------------------
# pick
# ---------------------------------------------------------------------------

subtest 'pick without filters never takes a backlog card' => sub {
    my $repo = _board();
    _card( $repo, 'Held back' );    # default status: backlog

    my $rv = run_karr( $repo, 'pick', '--claim', 'agent-a' );
    is( $rv->{exit}, 0, 'nothing to pick is not a failure' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/No available tasks to pick/, 'and says so' );
    my $t = _task($repo);
    is( $t->status, 'backlog', 'the card stays in backlog' );
    ok( !$t->has_claimed_by, 'and unclaimed' );

    # The backlog card outranks the todo card on every axis pick sorts by,
    # so only the hold can explain which one comes out.
    _card( $repo, 'Released', '--status', 'todo', '--priority', 'low' );
    run_karr( $repo, 'edit', '1', '--priority', 'critical', '--class', 'expedite' );
    $rv = run_karr( $repo, 'pick', '--claim', 'agent-a', '--json' );
    is( $rv->{exit}, 0, 'pick succeeds' ) or diag $rv->{stderr};
    is( decode_json( $rv->{stdout} )->{id}, 2, 'the todo card is picked, not the backlog one' );
    ok( !_task( $repo, 1 )->has_claimed_by, 'the backlog card is still unclaimed' );
};

subtest 'pick --status backlog is a usage error pointing at karr move ID todo' => sub {
    my $repo = _board();
    _card( $repo, 'Held back' );

    for my $filter ( 'backlog', 'backlog,todo', 'todo,backlog' ) {
        my $rv = run_karr( $repo, 'pick', '--claim', 'agent-a', '--status', $filter );
        is( $rv->{exit}, 2, "--status $filter: exit 2 (ADR 0002)" )
            or diag $rv->{stdout} . $rv->{stderr};
        like( $rv->{stderr}, qr/\AUsage error: backlog is held back and never picked/,
            '--status ' . $filter . ': says why' );
        like( $rv->{stderr}, qr/\n  karr move ID todo\n\z/,
            '--status ' . $filter . ': and ends in the way out' );
    }
    ok( !_task($repo)->has_claimed_by, 'nothing was claimed' );
    is( _task($repo)->status, 'backlog', 'nothing moved' );
};

subtest 'pick --move backlog is a usage error' => sub {
    my $repo = _board();
    _card( $repo, 'Released', '--status', 'todo' );

    my $rv = run_karr( $repo, 'pick', '--claim', 'agent-a', '--move', 'backlog' );
    is( $rv->{exit}, 2, 'exit 2' ) or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr},
        qr/\AUsage error: --move backlog would leave the picked card in backlog, which holds no claim/,
        'says why' );
    like( $rv->{stderr}, qr/\n  karr pick --move in-progress --claim agent-a\n\z/,
        'and ends in the call that would have worked' );

    my $t = _task($repo);
    is( $t->status, 'todo', 'the card did not move' );
    ok( !$t->has_claimed_by, 'and was not claimed' );
};

subtest 'Foundation::Picker skips backlog the same way' => sub {
    my $repo = _board();
    _card( $repo, 'Held back', '--priority', 'critical', '--class', 'expedite' );
    is( App::karr::Foundation::Picker->new( store => _store($repo) )->next_ticket,
        undef, 'a board with only a backlog card has no ticket to give' );

    _card( $repo, 'Released', '--status', 'todo', '--priority', 'low' );
    is( App::karr::Foundation::Picker->new( store => _store($repo) )->next_ticket,
        2, 'the todo card is the ticket, however urgent the backlog card is' );
};

# ---------------------------------------------------------------------------
# Claims: backlog holds none
# ---------------------------------------------------------------------------

subtest 'create --claim into backlog is refused, and burns no id' => sub {
    my $repo = _board();

    my $rv = run_karr( $repo, 'create', 'Held', '--claim', 'X' );
    is( $rv->{exit}, 1, 'the default status: exit 1, like the require_claim refusal' )
        or diag $rv->{stdout} . $rv->{stderr};
    is( $rv->{stderr},
        "Status 'backlog' holds no claim -- promote the card first and claim it there:\n"
          . "  karr create Held --status todo --claim X\n",
        'the refusal, verbatim' );
    is( _task_count($repo), 0, 'no card was created' );

    $rv = run_karr( $repo, 'create', 'Held', '--status', 'backlog', '--claim', 'X' );
    is( $rv->{exit}, 1, 'an explicit --status backlog: refused too' );
    is( _task_count($repo), 0, 'still no card' );

    $rv = run_karr( $repo, 'create', 'Released', '--status', 'todo', '--claim', 'X' );
    is( $rv->{exit}, 0, '--status todo --claim X is fine' ) or diag $rv->{stderr};
    is( _task($repo)->id, 1, 'and it got id 1: the refusals allocated nothing' );
    is( _task($repo)->claimed_by, 'X', 'claimed in todo' );
};

subtest 'create with KARR_CLAIM files into backlog unclaimed (the env never reaches backlog)' => sub {
    my $repo = _board();
    local $ENV{KARR_CLAIM} = 'me';
    my $rv = run_karr( $repo, 'create', 'Filed' );
    is( $rv->{exit}, 0, 'create succeeds' ) or diag $rv->{stderr};
    is( _task($repo)->status, 'backlog', 'in backlog' );
    ok( !_task($repo)->has_claimed_by, 'unclaimed' );
};

subtest 'edit --claim on a backlog card is refused' => sub {
    my $repo = _board();
    _card( $repo, 'Held' );

    my $rv = run_karr( $repo, 'edit', '1', '--claim', 'X', '-a', 'note' );
    is( $rv->{exit}, 1, 'exit 1' ) or diag $rv->{stdout} . $rv->{stderr};
    is( $rv->{stderr},
        "Status 'backlog' holds no claim -- promote the card first and claim it there:\n"
          . "  karr move 1 todo --claim X\n"
          . "1 of 1 ids failed\n",
        'the refusal, verbatim, then the batch summary' );
    my $t = _task($repo);
    ok( !$t->has_claimed_by, 'no claim was written' );
    unlike( $t->body // '', qr/note/, 'and nothing else from that edit either' );

    $rv = run_karr( $repo, 'edit', '1', '--claim', 'X', '--json' );
    is( $rv->{exit}, 1, '--json: exit 1' );
    is_deeply( decode_json( $rv->{stdout} ),
        { id => 1, error => "Status 'backlog' holds no claim -- promote the card first and claim it there" },
        '--json: the one-line error field' );
};

subtest 'edit --status backlog --claim is refused; --status todo --claim is fine' => sub {
    my $repo = _board();
    _card( $repo, 'Released', '--status', 'todo' );

    my $rv = run_karr( $repo, 'edit', '1', '--status', 'backlog', '--claim', 'X' );
    is( $rv->{exit}, 1, 'into backlog with a claim: exit 1' ) or diag $rv->{stderr};
    like( $rv->{stderr}, qr/\AStatus 'backlog' holds no claim/, 'the held-back refusal' );
    is( _task($repo)->status, 'todo', 'the card stayed in todo' );
    ok( !_task($repo)->has_claimed_by, 'unclaimed' );

    _card( $repo, 'Held' );
    $rv = run_karr( $repo, 'edit', '2', '--status', 'todo', '--claim', 'X' );
    is( $rv->{exit}, 0, 'out of backlog with a claim: fine' ) or diag $rv->{stderr};
    is( _task( $repo, 2 )->status, 'todo', 'in todo' );
    is( _task( $repo, 2 )->claimed_by, 'X', 'claimed there' );
};

subtest 'move ID backlog --claim is refused, from any column' => sub {
    my $repo = _board();
    _card( $repo, 'Released', '--status', 'todo' );
    _card( $repo, 'Held' );

    my $rv = run_karr( $repo, 'move', '1', 'backlog', '--claim', 'X' );
    is( $rv->{exit}, 1, 'todo -> backlog --claim: exit 1' ) or diag $rv->{stderr};
    is( $rv->{stderr},
        "Status 'backlog' holds no claim -- promote the card first and claim it there:\n"
          . "  karr move 1 todo --claim X\n"
          . "1 of 1 ids failed\n",
        'the refusal, verbatim' );
    is( _task( $repo, 1 )->status, 'todo', 'the card stayed in todo' );
    ok( !_task( $repo, 1 )->has_claimed_by, 'unclaimed' );

    $rv = run_karr( $repo, 'move', '2', 'backlog', '--claim', 'X' );
    is( $rv->{exit}, 1, 'backlog -> backlog --claim (a claim-only move): refused too' );
    ok( !_task( $repo, 2 )->has_claimed_by, 'unclaimed' );
};

subtest 'backlog -> in-progress --claim directly stays allowed' => sub {
    my $repo = _board();
    _card( $repo, 'Urgent after all' );

    my $rv = run_karr( $repo, 'move', '1', 'in-progress', '--claim', 'X' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    my $t = _task($repo);
    is( $t->status,     'in-progress', 'in progress' );
    is( $t->claimed_by, 'X',           'claimed by X' );
};

subtest 'backlog -> todo with KARR_CLAIM set promotes without claiming' => sub {
    my $repo = _board();
    _card( $repo, 'Promote me' );
    local $ENV{KARR_CLAIM} = 'coordinator';

    my $rv = run_karr( $repo, 'move', '1', 'todo' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    is( _task($repo)->status, 'todo', 'in todo' );
    ok( !_task($repo)->has_claimed_by, 'unclaimed: the pool is for whoever picks next' );
};

# ---------------------------------------------------------------------------
# A move into backlog releases the claim
# ---------------------------------------------------------------------------

subtest 'move ID backlog releases the claim, and the log records the move' => sub {
    my $repo = _board();
    _card( $repo, 'Parked again' );
    local $ENV{KARR_CLAIM} = 'agent-a';
    my $rv = run_karr( $repo, 'move', '1', 'in-progress' );
    is( $rv->{exit}, 0, 'setup: taken up under the env name' ) or diag $rv->{stderr};
    is( _task($repo)->claimed_by, 'agent-a', 'setup: held' );

    $rv = run_karr( $repo, 'move', '1', 'backlog' );
    is( $rv->{exit}, 0, 'the holder parks it: exit 0' ) or diag $rv->{stderr};
    my $t = _task($repo);
    is( $t->status, 'backlog', 'back in backlog' );
    ok( !$t->has_claimed_by, 'claimed_by is gone' );
    ok( !$t->has_claimed_at, 'and so is claimed_at' );

    $rv = run_karr( $repo, 'log', '--json' );
    is( $rv->{exit}, 0, 'log --json' ) or diag $rv->{stderr};
    my @moves = grep { $_->{action} eq 'move' && $_->{task_id} == 1 }
        @{ decode_json( $rv->{stdout} ) };
    is( $moves[-1]{detail}, 'backlog', 'the release is logged as the move into backlog' );
};

subtest 'edit --status backlog releases the claim too' => sub {
    my $repo = _board();
    _card( $repo, 'Parked' );
    my $rv = run_karr( $repo, 'move', '1', 'review', '--claim', 'agent-b' );
    is( $rv->{exit}, 0, 'setup: in review, claimed' ) or diag $rv->{stderr};

    $rv = run_karr( $repo, 'edit', '1', '--status', 'backlog', '--claim', 'agent-b' );
    is( $rv->{exit}, 1, 'naming the claim on the way in is refused' );
    is( _task($repo)->claimed_by, 'agent-b', 'setup: still held after the refusal' );

    local $ENV{KARR_CLAIM} = 'agent-b';
    $rv = run_karr( $repo, 'edit', '1', '--status', 'backlog' );
    is( $rv->{exit}, 0, 'the holder parks it with edit' ) or diag $rv->{stderr};
    my $t = _task($repo);
    is( $t->status, 'backlog', 'in backlog' );
    ok( !$t->has_claimed_by, 'claim released' );
    ok( !$t->has_claimed_at, 'claimed_at too' );
};

# ---------------------------------------------------------------------------
# Legacy: a claim already sitting on a backlog card
# ---------------------------------------------------------------------------

subtest 'a legacy claimed backlog card does not break unrelated commands' => sub {
    my $repo = _board();
    my $now  = gmtime->datetime . 'Z';
    _raw_card( $repo, status => 'backlog', claimed_by => 'old-agent', claimed_at => $now );

    {
        local $ENV{KARR_CLAIM} = 'old-agent';
        my $rv = run_karr( $repo, 'edit', '1', '-a', 'a note from the holder' );
        is( $rv->{exit}, 0, 'edit -a by the holder (KARR_CLAIM) works' ) or diag $rv->{stderr};
    }
    {
        local $ENV{KARR_CLAIM};
        delete $ENV{KARR_CLAIM};
        my $rv = run_karr( $repo, 'edit', '1', '-a', 'note', '--claim', 'old-agent', '--add-tag', 'x' );
        is( $rv->{exit}, 1, 're-stamping the claim explicitly is still a new claim: refused' );
    }
    my $t = _task($repo);
    like( $t->body, qr/a note from the holder/, 'the note landed' );
    is( $t->claimed_by, 'old-agent', 'the legacy claim is left alone' );
    is( $t->claimed_at, $now,        'and not re-stamped' );

    for my $cmd ( [ 'show', '1' ], ['list'], ['board'], [ 'list', '--json' ] ) {
        my $rv = run_karr( $repo, @$cmd );
        is( $rv->{exit}, 0, "karr @$cmd works" ) or diag $rv->{stderr};
    }

    my $rv = run_karr( $repo, 'pick', '--claim', 'agent-a' );
    like( $rv->{stdout}, qr/No available tasks/, 'and pick still does not take it' );
};

# ---------------------------------------------------------------------------
# karr-foundation: backlog is not actionable
# ---------------------------------------------------------------------------

# The agent: moves the first todo card to done, one per run, logging the move
# as the agent so foundation sees it engaged the board. Every run is recorded,
# including the ones that find nothing -- the run count is what the drain
# assertions below are about.
sub _fake_agent {
    my ($dir) = @_;
    my $lib    = path('lib')->absolute->stringify;
    my $script = path($dir)->child('fake-agent.pl');
    $script->spew_utf8(<<'PERL');
use strict;
use warnings;
require App::karr::Git;
require App::karr::BoardStore;
require App::karr::ActivityLog;
my $repo = $ENV{KARR_REPO} or die "no KARR_REPO\n";
open my $fh, '>>', "$repo/agent-runs.log" or die $!;
print {$fh} "run\n";
close $fh;
my $store = App::karr::BoardStore->new(
  git => App::karr::Git->new( dir => $repo ) );
my ( $t ) = grep { $_ && $_->status eq 'todo' } $store->load_tasks;
exit 0 unless $t;
$t->status('done');
$store->save_task($t);
App::karr::ActivityLog->new( git => $store->git, role => 'agent' )->log_entry(
  agent => 'fake-agent', action => 'move', task_id => $t->id + 0,
  detail => 'done' );
PERL
    return qq{$^X -I"$lib" "$script"};
}

sub _fake_hook {
    my ($dir) = @_;
    my $script = path($dir)->child('fake-hook.pl');
    $script->spew_utf8(<<'PERL');
use strict;
use warnings;
my $repo = $ENV{KARR_REPO} or die "no KARR_REPO\n";
open my $fh, '>>', "$repo/hook-runs.log" or die $!;
print {$fh} "hook\n";
close $fh;
PERL
    return qq{$^X "$script"};
}

sub _runs {
    my ( $repo, $file ) = @_;
    my $log = path($repo)->child($file);
    my @lines = $log->exists ? ( grep { length } split /\n/, $log->slurp_utf8 ) : ();
    return @lines;
}

subtest 'foundation: a backlog card is not actionable' => sub {
    my $repo = _repo();
    _raw_card( $repo, status => 'backlog' );
    _raw_card( $repo, status => 'done' );
    my $f = App::karr::Foundation->new( _config_data => {} );

    my %states = $f->_task_states($repo);
    ok( $states{1}{held_back}, 'the snapshot carries the board\'s held-back verdict' );
    ok( !$states{2}{held_back}, 'and only for backlog' );
    ok( !$f->_is_actionable( $states{1} ), 'a backlog card is not actionable' );
    ok( !$f->_has_actionable_tasks($repo), 'so backlog + done is a drained board' );

    my $exec = App::karr::Foundation::Executor->new( foundation => $f );
    is( $exec->facts_for( { kind => 'shell', repo => $repo } )->{board_actionable},
        'no', 'board_actionable says no' );

    _raw_card( $repo, status => 'todo' );
    %states = $f->_task_states($repo);
    ok( $f->_is_actionable( $states{3} ), 'a todo card is actionable' );
    is( $exec->facts_for( { kind => 'shell', repo => $repo } )->{board_actionable},
        'yes', 'and board_actionable follows' );
};

subtest 'foundation: an unchanged board with only backlog left is skipped' => sub {
    my $repo = _repo();
    _raw_card( $repo, status => 'backlog' );
    _raw_card( $repo, status => 'backlog' );
    my $agent = _fake_agent($repo);
    path($repo)->child('.karr')->spew_utf8("command: $agent\nmax_runtime: 60\n");

    my $f = App::karr::Foundation->new( _config_data => {} );
    $f->_state_set( path($repo), hash => $f->_ref_hash( path($repo) ) );

    my $res = $f->_process_repo( path($repo) );
    is( $res->{outcome}, 'skipped', 'the tick skips the board' );
    is( $res->{reason}, 'no board change and no actionable tasks', 'as drained' );
    is( scalar _runs( $repo, 'agent-runs.log' ), 0, 'no agent ran' );
};

subtest 'foundation: a drain stops when only backlog is left, and on_drained runs' => sub {
    my $repo = _repo();
    _raw_card( $repo, status => 'backlog' );
    _raw_card( $repo, status => 'todo' );
    my $agent = _fake_agent($repo);
    my $hook  = _fake_hook($repo);
    path($repo)->child('.karr')->spew_utf8(
        "command: $agent\nmax_runtime: 60\non_drained: $hook\n" );

    my $f   = App::karr::Foundation->new( _config_data => {} );
    my $res = $f->_process_repo( path($repo) );

    is( _store($repo)->find_task(2)->status, 'done',    'the todo card got done' );
    is( _store($repo)->find_task(1)->status, 'backlog', 'the backlog card was left alone' );
    is( scalar _runs( $repo, 'agent-runs.log' ), 1,
        'one agent run: nothing but backlog was left after it' );
    is( $res->{outcome}, 'progress', 'the drain reports its progress' );
    is( scalar _runs( $repo, 'hook-runs.log' ), 1, 'and on_drained ran' );
};

done_testing;
