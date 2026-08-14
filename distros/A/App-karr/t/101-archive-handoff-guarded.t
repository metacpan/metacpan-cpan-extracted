use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Time::Piece;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Archive;
use App::karr::Cmd::Handoff;

# Ticket #97: two write paths were left outside the fix for #56.
#
#   * Cmd::Archive set the status to `archived` and saved with no claim check
#     at all -- a third door into a status change next to `move` and
#     `edit --status`, and the only one that could take a card off an agent who
#     was still holding it.
#
#   * Cmd::Handoff read the task, mutated it and saved it back unguarded, so a
#     claim (or any other change) that landed between the read and the write
#     was silently overwritten.
#
# Both now go through Role::TaskMutation -- update_task_guarded for the
# compare-and-swap and apply_status_change for the status change itself -- so
# the claim rule is applied to the same revision that is written, which is the
# whole point of #44/#46/#56.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3( undef, my $stdout_fh, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
    my $stdout      = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";

    return {
        exit   => $exit,
        stdout => defined $stdout      ? $stdout      : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _cli_board {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0                                     or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' ) == 0        or die 'git config';
    is( _run_karr( $repo, 'init', '--name', 'Guard Board' )->{exit}, 0,
        'setup: karr init exits 0' );
    is( _run_karr( $repo, 'create', 'Held task' )->{exit}, 0,
        'setup: task 1 created' );
    return $repo;
}

sub _field_of {
    my ( $repo, $id, $label ) = @_;
    my $rv = _run_karr( $repo, 'show', $id );
    my ($value) = $rv->{stdout} =~ /^\Q$label\E:\s+(\S+)/m;
    return defined $value ? $value : '';
}

# ---------------------------------------------------------------------------
# the claim rule now covers archive too
# ---------------------------------------------------------------------------

subtest 'archive refuses a task another agent is holding' => sub {
    my $repo = _cli_board();
    is( _run_karr( $repo, 'edit', '1', '--claim', 'other-agent' )->{exit}, 0,
        'other-agent claims task 1' );

    my $rv = _run_karr( $repo, 'archive', '1' );

    is( $rv->{exit}, 1, 'archive exits 1 instead of taking the card' );
    like( $rv->{stderr}, qr/Task 1 is claimed by other-agent/,
        'and says so in the same words move, edit and delete use' );
    isnt( _field_of( $repo, 1, 'Status' ), 'archived',
        'the task is still where its holder left it' );
    is( _field_of( $repo, 1, 'Claimed' ), 'other-agent',
        'and still carries the claim' );
};

subtest 'archive goes through once the claim is released' => sub {
    my $repo = _cli_board();
    _run_karr( $repo, 'edit', '1', '--claim', 'other-agent' );

    is( _run_karr( $repo, 'edit', '1', '--release' )->{exit}, 0, 'claim released' );
    my $rv = _run_karr( $repo, 'archive', '1' );
    is( $rv->{exit}, 0, 'archive exits 0' ) or diag $rv->{stderr};
    is( _field_of( $repo, 1, 'Status' ), 'archived', 'and the task is archived' );
};

subtest 'an unclaimed task archives exactly as before' => sub {
    my $repo = _cli_board();

    my $rv = _run_karr( $repo, 'archive', '1' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/Archived task 1: Held task/, 'same message as before' );
    is( _field_of( $repo, 1, 'Status' ), 'archived', 'status archived' );

    # The no-op re-archive must survive the move onto the guarded path: it
    # short-circuits before the claim check, so it stays a success (ADR 0002).
    my $again = _run_karr( $repo, 'archive', '1' );
    is( $again->{exit}, 0, 're-archiving is still a no-op success' );
    like( $again->{stdout}, qr/already archived/i, 'and still says so' );
};

subtest 'handoff still refuses a task another agent is holding' => sub {
    my $repo = _cli_board();
    _run_karr( $repo, 'edit', '1', '--claim', 'other-agent' );

    my $rv = _run_karr( $repo, 'handoff', '1', '--claim', 'agent-fox' );
    is( $rv->{exit}, 1, 'handoff exits 1' );
    like( $rv->{stderr}, qr/Task 1 is claimed by other-agent/,
        'with the one shared claim message' );
    isnt( _field_of( $repo, 1, 'Status' ), 'review', 'and nothing moved' );
};

subtest 'handoff by the holder still works' => sub {
    my $repo = _cli_board();
    _run_karr( $repo, 'edit', '1', '--claim', 'agent-fox' );

    my $rv = _run_karr( $repo, 'handoff', '1', '--claim', 'agent-fox',
        '--note', 'ready for review' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/Handed off task 1 -> review/, 'same message as before' );
    is( _field_of( $repo, 1, 'Status' ),  'review',    'status is review' );
    is( _field_of( $repo, 1, 'Claimed' ), 'agent-fox', 'claim refreshed' );
    like( _run_karr( $repo, 'show', 1 )->{stdout}, qr/ready for review/,
        'and the note landed in the body' );
};

# ---------------------------------------------------------------------------
# the write itself is now guarded: a change landing in the read/write window
# is no longer overwritten
# ---------------------------------------------------------------------------

sub _ref_board {
    my $dir = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $dir ) == 0                              or die 'git init';
    system( 'git', '-C', $dir, 'config', 'user.email', 'a@karr.test' ) == 0 or die 'git config';
    system( 'git', '-C', $dir, 'config', 'user.name',  'agent-a' ) == 0    or die 'git config';

    my $git = App::karr::Git->new( dir => $dir );
    $git->write_ref( 'refs/karr/config', "version: 1\nboard:\n  name: demo\n" );
    $git->save_task_ref(
        App::karr::Task->new(
            id       => 1,
            title    => 'One',
            status   => 'todo',
            priority => 'high',
            class    => 'standard',
            body     => '',
        )
    );
    return ( $git, App::karr::BoardStore->new( git => $git ) );
}

# Another agent claims task 1 the instant the command has parsed its first copy
# of the card -- the window an unguarded read-then-write leaves open. Task
# parsing is the common point on both the old and the new code path, so the
# same hook arms both.
#
# Everything the command reported is returned together: `archive` takes an id
# list, so a refusal reaches STDERR per id and the raised exception is the batch
# summary, while single-id `handoff` raises the refusal itself. What both have
# to say is that the claim stopped them.
sub _claim_lands_in_the_window {
    my ( $git, $cmd ) = @_;

    my $original = \&App::karr::Task::from_string;
    my $armed    = 1;

    my ( $out, $warned ) = ( '', '' );
    my $err = do {
        no warnings 'redefine';
        local *App::karr::Task::from_string = sub {
            my $task = $original->(@_);
            if ( $armed && $task->id == 1 ) {
                $armed = 0;
                my $other = $original->(@_);
                $other->claimed_by('other-agent');
                $other->claimed_at( gmtime->datetime . 'Z' );
                $git->save_task_ref($other);
            }
            return $task;
        };
        local $SIG{__WARN__} = sub { $warned .= $_[0] };
        local $@;
        eval {
            local *STDOUT;
            open STDOUT, '>', \$out or die $!;
            $cmd->execute( [1], [] );
            '';
        } || $@;
    };

    return "$err$warned";
}

subtest 'a claim landing in the archive window is not archived away' => sub {
    my ( $git, $store ) = _ref_board();
    my $cmd = App::karr::Cmd::Archive->new( store => $store );

    my $reported = _claim_lands_in_the_window( $git, $cmd );

    like( $reported, qr/claimed by other-agent/i,
        'the archive is refused by the claim that landed in the window' );

    my $stored = $git->load_task_ref(1);
    isnt( $stored->status, 'archived', 'the task was not archived' );
    is( $stored->claimed_by, 'other-agent', 'and the claim survived' );
};

subtest 'a claim landing in the handoff window is not overwritten' => sub {
    my ( $git, $store ) = _ref_board();
    my $cmd = App::karr::Cmd::Handoff->new( store => $store, claim => 'agent-fox' );

    my $reported = _claim_lands_in_the_window( $git, $cmd );

    like( $reported, qr/claimed by other-agent/i,
        'the handoff is refused by the claim that landed in the window' );

    my $stored = $git->load_task_ref(1);
    isnt( $stored->status, 'review', 'the task was not handed off' );
    is( $stored->claimed_by, 'other-agent',
        "and agent-fox's claim did not overwrite other-agent's" );
};

done_testing;
