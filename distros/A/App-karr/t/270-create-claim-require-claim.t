use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );

use App::karr::Git;
use App::karr::ActivityLog;

# Ticket #270: create gets the claim half of the lifecycle.
#
#   karr create "x" --claim NAME
#       stamps claimed_by/claimed_at exactly as `karr move --claim` does, and
#       the activity-log entry for the create carries the claim name as its
#       agent field (Role::BoardAccess/log_agent prefers a command's own
#       --claim over the git identity).
#
#   karr create "x" --status in-progress   (a require_claim status, no --claim)
#       is refused with the k263-shaped message -- "Status 'in-progress'
#       requires a claim:" and the invocation that would have worked as the
#       LAST line -- instead of creating an unclaimed card in a column that
#       demands one. Before the ticket this succeeded silently.
#
# The default status (backlog) is deliberately not consulted, and a board
# whose statuses carry no require_claim behaves exactly as before.

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    return run_karr( $cwd, @argv );
}

sub _bare_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo )                                     == 0 or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' )         == 0 or die 'git config';
    return $repo;
}

# The default board config marks in-progress and review require_claim
# (App::karr::Config/default_config), so a plain `karr init` board is the
# fixture for the refusal.
sub _board_repo {
    my $repo = _bare_repo();
    my $init = _run_karr( $repo, 'init', '--name', 'Claim Board' );
    is( $init->{exit}, 0, 'setup: karr init' ) or diag $init->{stderr};
    return $repo;
}

sub _task {
    my ( $repo, $id ) = @_;
    return App::karr::Git->new( dir => $repo )->load_task_ref( $id // 1 );
}

sub _log_agents {
    my ($repo) = @_;
    my $log = App::karr::ActivityLog->new(
        git  => App::karr::Git->new( dir => $repo ),
        role => 'user',
    );
    return map { $_->{agent} } $log->entries;
}

# The lines a caller actually sees, trailing blanks dropped, so "last line"
# means the last line with anything on it.
sub _lines {
    my ($text) = @_;
    my @lines = split /\n/, $text;
    pop @lines while @lines && $lines[-1] !~ /\S/;
    return @lines;
}

subtest 'create --claim stamps claimed_by and claimed_at' => sub {
    my $repo = _board_repo();

    my $rv = _run_karr( $repo, 'create', 'Claimed at birth', '--claim', 'swift-fox' );
    is( $rv->{exit}, 0, 'create --claim succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->claimed_by, 'swift-fox', 'claimed_by stamped' );
    like( $task->claimed_at, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/,
        'claimed_at is the same UTC instant shape `karr move --claim` writes' );
};

subtest 'the activity-log entry for a claimed create carries the claim name' => sub {
    my $repo = _board_repo();

    _run_karr( $repo, 'create', 'Claimed', '--claim', 'swift-fox' );
    my @agents = _log_agents($repo);

    is( scalar @agents, 1, 'one log entry for the one create' );
    is( $agents[0], 'swift-fox',
        'the agent field is the claim name, not the git identity' );
};

subtest 'create --status in-progress without --claim is refused, k263 shape' => sub {
    my $repo = _board_repo();

    my $rv = _run_karr( $repo, 'create', 'No claim', '--status', 'in-progress' );
    is( $rv->{exit}, 1, 'exit 1, a runtime refusal (ADR 0002)' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr},
        qr/^Status 'in-progress' requires a claim, and KARR_CLAIM is unset:$/m,
        'the wording names the status, the missing value, and the empty env (ADR 0005)' );
    like( $rv->{stderr}, qr/^  export KARR_CLAIM=\$\(karr agent-name\)/m,
        'and the once-per-session export is named too' );

    my @lines = _lines( $rv->{stderr} );
    is( $lines[-1], "  karr create 'No claim' --status in-progress --claim NAME",
        'the invocation that would have worked is still the last line' )
        or diag $rv->{stderr};

    # Nothing was created: the refusal happens before an id is allocated.
    my $list = _run_karr( $repo, 'list', '--compact' );
    unlike( $list->{stdout}, qr/No claim/, 'no card was burned by the refusal' );
};

subtest 'the suggested line really works' => sub {
    my $repo = _board_repo();

    my $rv = _run_karr( $repo, 'create', 'No claim', '--status', 'in-progress',
        '--claim', 'NAME' );
    is( $rv->{exit}, 0, 'create --status in-progress --claim NAME succeeds' )
        or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status,     'in-progress', 'card landed in the require_claim column' );
    is( $task->claimed_by, 'NAME',        'and is claimed' );
};

subtest 'the default status is not consulted: create without --status needs no claim' => sub {
    my $repo = _board_repo();

    my $rv = _run_karr( $repo, 'create', 'Plain card' );
    is( $rv->{exit}, 0, 'create without --status succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status, 'backlog', 'default status unchanged' );
    ok( !$task->has_claimed_by, 'and no claim was invented' );
};

subtest 'a board with no require_claim statuses behaves as before' => sub {
    # init --statuses writes bare status names, which carry no require_claim
    # (App::karr::Config/status_config synthesizes { name => $s } for a bare
    # string, and that entry has no require_claim key).
    my $repo = _bare_repo();
    my $init = _run_karr( $repo, 'init', '--statuses', 'backlog,todo,in-progress,done' );
    is( $init->{exit}, 0, 'setup: init with bare statuses' ) or diag $init->{stderr};

    my $rv = _run_karr( $repo, 'create', 'No claim needed', '--status', 'in-progress' );
    is( $rv->{exit}, 0, 'create --status in-progress succeeds on a board that does not require it' )
        or diag $rv->{stdout} . $rv->{stderr};

    my $task = _task($repo);
    is( $task->status, 'in-progress', 'card landed' );
    ok( !$task->has_claimed_by, 'and no claim was demanded' );
};

subtest 'an unknown status still fails validation before the claim check' => sub {
    my $repo = _board_repo();

    my $rv = _run_karr( $repo, 'create', 'Bad status', '--status', 'nowhere' );
    is( $rv->{exit}, 2, 'an unknown status is still a usage error (2)' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/Usage error/, 'the validation answer, not the claim answer' );
};

done_testing;
