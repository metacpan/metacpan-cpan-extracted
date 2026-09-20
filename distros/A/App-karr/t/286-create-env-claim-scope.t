use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );

use App::karr::Git;

# Ticket #286: create takes KARR_CLAIM only for a card it is starting.
#
# Since ADR 0005 every claiming command defaults --claim from KARR_CLAIM, and
# the skill has each agent export it first thing. Cmd::Create stamped that
# remembered claim on EVERY card it made, so an agent filing a bug it found --
# `karr create "Bug found"`, into the backlog, for whoever picks it next --
# held that card until claim_timeout (1h): other agents' `pick` and
# `list --unclaimed` skipped it. A Claim is a lease held while working a card
# (CONTEXT.md); a card filed for someone else is not being worked.
#
# The rule now:
#
#   * an explicit --claim NAME stamps the claim on any status (k270, unchanged)
#   * KARR_CLAIM is used only when --status names a require_claim column --
#     the card is being started right now, and that is exactly the case the
#     k270 guard consults the env for, so guard and stamp agree
#   * no --status, or a --status that needs no claim: nothing from the env
#   * without --claim and with KARR_CLAIM unset, --status in-progress is still
#     refused the k270 way (exit 1, the --claim hint as the last line)
#
# The default board config marks in-progress and review require_claim and
# leaves backlog and todo bare (App::karr::Config/default_config), so a plain
# `karr init` board is the fixture.

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    return run_karr( $cwd, @argv );
}

sub _board_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo )                                     == 0 or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' )         == 0 or die 'git config';
    my $init = _run_karr( $repo, 'init', '--name', 'k286 Board' );
    is( $init->{exit}, 0, 'setup: karr init' ) or diag $init->{stderr};
    return $repo;
}

sub _task {
    my ( $repo, $id ) = @_;
    return App::karr::Git->new( dir => $repo )->load_task_ref( $id // 1 );
}

# The lines a caller actually sees, trailing blanks dropped, so "last line"
# means the last line with anything on it.
sub _lines {
    my ($text) = @_;
    my @lines = split /\n/, $text;
    pop @lines while @lines && $lines[-1] !~ /\S/;
    return @lines;
}

subtest 'KARR_CLAIM set, no --status: the backlog card is filed unclaimed' => sub {
    my $repo = _board_repo();
    local $ENV{KARR_CLAIM} = 'filer';

    my $rv = _run_karr( $repo, 'create', 'Bug found' );
    is( $rv->{exit}, 0, 'create succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status, 'backlog', 'default status' );
    ok( !$task->has_claimed_by, 'no claimed_by from the environment' );
    ok( !$task->has_claimed_at, 'and no claimed_at either' );
};

subtest 'KARR_CLAIM set, --status todo (no require_claim): still unclaimed' => sub {
    my $repo = _board_repo();
    local $ENV{KARR_CLAIM} = 'filer';

    my $rv = _run_karr( $repo, 'create', 'Ready to go', '--status', 'todo' );
    is( $rv->{exit}, 0, 'create --status todo succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status, 'todo', 'card landed in todo' );
    ok( !$task->has_claimed_by, 'a column that needs no claim gets none from the env' );
};

subtest 'KARR_CLAIM set, --status in-progress: the env claim is written' => sub {
    my $repo = _board_repo();
    local $ENV{KARR_CLAIM} = 'starter';

    my $rv = _run_karr( $repo, 'create', 'Starting now', '--status', 'in-progress' );
    is( $rv->{exit}, 0, 'create --status in-progress is satisfied by the env' )
        or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status,     'in-progress', 'card landed in the require_claim column' );
    is( $task->claimed_by, 'starter',     'claimed_by is the env name' );
    like( $task->claimed_at, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/,
        'claimed_at is the same UTC instant shape `karr move --claim` writes' );
};

subtest 'an explicit --claim stamps the default-status card as before' => sub {
    my $repo = _board_repo();
    local $ENV{KARR_CLAIM} = 'filer';

    my $rv = _run_karr( $repo, 'create', 'Held on purpose', '--claim', 'other' );
    is( $rv->{exit}, 0, 'create --claim succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status,     'backlog', 'default status' );
    is( $task->claimed_by, 'other',   'the explicit flag wins on any status' );
    ok( $task->has_claimed_at, 'and claimed_at is stamped with it' );
};

subtest 'KARR_CLAIM unset, no --claim: --status in-progress is still refused (k270)' => sub {
    my $repo = _board_repo();
    local $ENV{KARR_CLAIM};
    delete $ENV{KARR_CLAIM};

    my $rv = _run_karr( $repo, 'create', 'No claim', '--status', 'in-progress' );
    is( $rv->{exit}, 1, 'exit 1, a runtime refusal (ADR 0002)' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr},
        qr/^Status 'in-progress' requires a claim, and KARR_CLAIM is unset:$/m,
        'the wording is unchanged' );

    my @lines = _lines( $rv->{stderr} );
    is( $lines[-1], "  karr create 'No claim' --status in-progress --claim NAME",
        'the --claim hint is still the last line' )
        or diag $rv->{stderr};

    my $list = _run_karr( $repo, 'list', '--compact' );
    unlike( $list->{stdout}, qr/No claim/, 'no card was burned by the refusal' );
};

subtest 'the symptom: another agent sees the filed card in list --unclaimed' => sub {
    my $repo = _board_repo();

    {
        local $ENV{KARR_CLAIM} = 'agent-x';
        my $rv = _run_karr( $repo, 'create', 'Bug found' );
        is( $rv->{exit}, 0, 'agent-x files a card' ) or diag $rv->{stderr};
    }
    {
        local $ENV{KARR_CLAIM} = 'agent-y';
        my $un = _run_karr( $repo, 'list', '--unclaimed', '--compact' );
        is( $un->{exit}, 0, 'agent-y lists the unclaimed cards' ) or diag $un->{stderr};
        like( $un->{stdout}, qr/Bug found/,
            'the card agent-x filed is free for agent-y, not held until claim_timeout' );
    }
};

done_testing;
