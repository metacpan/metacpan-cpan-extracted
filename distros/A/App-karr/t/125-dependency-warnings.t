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
use JSON::MaybeXS qw( decode_json );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;

# Ticket #123: depends_on was stored, round-tripped and written into the
# frontmatter by App::karr::Task, and read by nothing. A card that recorded
# `depends_on: [5]` looked as though karr would hold it back until 5 was
# finished -- the field was accepted, kept and materialized -- while move, edit
# --status and pick handed it out with no word said. In a multi-agent board that
# is work starting in the wrong order with nothing anywhere to notice it.
#
# The decision was to warn, not to block: taking a card into a non-terminal
# status with unsatisfied dependencies proceeds and exits 0, but says so.
# "Unsatisfied" is decided by the board's own terminal statuses
# (App::karr::Config::is_terminal_status, #67/#98), never a hardcoded `done`,
# and a dependency on an id that is not on the board is reported in its own
# words, because it is a different mistake from one that is merely not finished
# yet.
#
# The channel rules follow the ones App::karr::Role::TaskMutation::run_batch
# already set for per-id errors: the human copy goes to STDERR so STDOUT stays
# parseable, --json carries it in the result object instead, and --quiet
# silences the STDERR copy.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3( my $stdin_fh, my $stdout_fh, $stderr,
        $^X, "-I$ROOT/lib", $BIN, @argv );
    close $stdin_fh;

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

# A fresh isolated temp repo per subtest, never the developer's real board.
# Tasks are seeded through BoardStore rather than `karr create`, because
# nothing on the CLI can set depends_on -- which is half of what made #123
# invisible.
sub _board {
    my (@specs) = @_;
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
        or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
        or die 'git config';

    my $init = _run_karr( $repo, 'init', '--name', 'Dep Board' );
    die "karr init failed: $init->{stderr}" if $init->{exit};

    my $git   = App::karr::Git->new( dir => $repo );
    my $store = App::karr::BoardStore->new( git => $git );
    for my $spec (@specs) {
        $store->save_task(
            App::karr::Task->new(
                id     => $spec->{id},
                title  => $spec->{title} // "Task $spec->{id}",
                status => $spec->{status},
                ( $spec->{depends_on} ? ( depends_on => $spec->{depends_on} ) : () ),
            )
        );
    }
    # The seeded ids bypass the counter; keep it above them so a later
    # `karr create` in the same board could not collide.
    $git->write_ref( 'refs/karr/meta/next-id', "50\n" );

    return $repo;
}

sub _task {
    my ( $repo, $id ) = @_;
    return App::karr::Git->new( dir => $repo )->load_task_ref($id);
}

subtest 'a satisfied dependency says nothing' => sub {
    my $repo = _board(
        { id => 1, status => 'done' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'move', '2', 'in-progress', '--claim', 'agent-a' );
    is( $r->{exit}, 0, 'move succeeds' ) or diag $r->{stderr};
    unlike( $r->{stderr}, qr/depends on/,
        'a dependency in a terminal status is satisfied, so nothing is said' );
    is( _task( $repo, 2 )->status, 'in-progress', 'and the card moved' );
};

subtest 'an unfinished dependency warns and still moves' => sub {
    my $repo = _board(
        { id => 1, status => 'todo' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'move', '2', 'in-progress', '--claim', 'agent-a' );
    is( $r->{exit}, 0, 'the move is not blocked -- warn, do not refuse' )
        or diag $r->{stderr};
    like( $r->{stderr}, qr/task 2 depends on task 1, which is still todo/,
        'the warning names both cards and the state of the dependency' );
    like( $r->{stdout}, qr/Moved task 2/, 'STDOUT reports the move as usual' );
    unlike( $r->{stdout}, qr/depends on/,
        'and carries no warning of its own, so it stays parseable' );
    is( _task( $repo, 2 )->status, 'in-progress', 'the card really did move' );
};

subtest 'a dependency on an id that is not on the board is a different warning' => sub {
    my $repo = _board(
        { id => 2, status => 'todo', depends_on => [99] },
    );

    my $r = _run_karr( $repo, 'move', '2', 'in-progress', '--claim', 'agent-a' );
    is( $r->{exit}, 0, 'still not blocked' ) or diag $r->{stderr};
    like( $r->{stderr}, qr/task 2 depends on task 99, which does not exist/,
        'a missing dependency is reported as missing' );
    unlike( $r->{stderr}, qr/still/,
        'and not in the words used for one that is merely unfinished' );
};

subtest 'every unsatisfied dependency is reported, not just the first' => sub {
    my $repo = _board(
        { id => 1, status => 'done' },
        { id => 2, status => 'backlog' },
        { id => 3, status => 'todo', depends_on => [ 1, 2, 99 ] },
    );

    my $r = _run_karr( $repo, 'move', '3', 'in-progress', '--claim', 'agent-a' );
    is( $r->{exit}, 0, 'move succeeds' ) or diag $r->{stderr};
    unlike( $r->{stderr}, qr/depends on task 1\b/, 'the finished one is silent' );
    like( $r->{stderr}, qr/depends on task 2, which is still backlog/,
        'the unfinished one is named' );
    like( $r->{stderr}, qr/depends on task 99, which does not exist/,
        'and so is the missing one' );
};

subtest 'a move into a terminal status never warns' => sub {
    my $repo = _board(
        { id => 1, status => 'todo' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'move', '2', 'done' );
    is( $r->{exit}, 0, 'move succeeds' ) or diag $r->{stderr};
    unlike( $r->{stderr}, qr/depends on/,
        'finishing a card is not taking it up, so the dependency is moot' );
    is( _task( $repo, 2 )->status, 'done', 'the card is done' );
};

subtest 'the board decides what terminal means, not the word done' => sub {
    # backlog / doing / shipped: `shipped` is this board's finish line, so a
    # dependency sitting in it is satisfied and a move into it is a finish.
    # A hardcoded done/archived pair gets both of these backwards.
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
        or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
        or die 'git config';

    my $git = App::karr::Git->new( dir => $repo );
    $git->write_ref(
        'refs/karr/config',
        "---\nversion: 1\nboard:\n  name: Custom\nstatuses:\n  - backlog\n  - doing\n  - shipped\n"
    );
    $git->write_ref( 'refs/karr/meta/next-id', "50\n" );
    my $store = App::karr::BoardStore->new( git => $git );
    $store->save_task( App::karr::Task->new( id => 1, title => 'Dep', status => 'shipped' ) );
    $store->save_task(
        App::karr::Task->new(
            id => 2, title => 'Dependent', status => 'backlog', depends_on => [1] ) );
    $store->save_task(
        App::karr::Task->new(
            id => 3, title => 'Other', status => 'backlog', depends_on => [2] ) );

    my $ok = _run_karr( $repo, 'move', '2', 'doing' );
    is( $ok->{exit}, 0, 'move succeeds' ) or diag $ok->{stderr};
    unlike( $ok->{stderr}, qr/depends on/,
        'a dependency in the board own final column is satisfied' );

    my $fin = _run_karr( $repo, 'move', '3', 'shipped' );
    is( $fin->{exit}, 0, 'move succeeds' ) or diag $fin->{stderr};
    unlike( $fin->{stderr}, qr/depends on/,
        'and a move into that column is a finish, so it does not warn' );
};

subtest '--json carries the warning in the object and not on STDERR' => sub {
    my $repo = _board(
        { id => 1, status => 'todo' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'move', '2', 'in-progress', '--claim', 'agent-a', '--json' );
    is( $r->{exit}, 0, 'move succeeds' ) or diag $r->{stderr};
    unlike( $r->{stderr}, qr/depends on/,
        'nothing on STDERR: a JSON consumer would never see it there' );

    my $data = eval { decode_json( $r->{stdout} ) };
    ok( $data, 'STDOUT is still one decodable JSON object' )
        or diag "stdout was: $r->{stdout}";
    is( ref $data->{dependency_warnings}, 'ARRAY',
        'the warning rides in the result object' );
    is( scalar @{ $data->{dependency_warnings} }, 1, 'one unsatisfied dependency' );
    like( $data->{dependency_warnings}[0], qr/depends on task 1, which is still todo/,
        'and it is the same sentence STDERR would have carried' );
};

subtest '--json omits the key entirely when there is nothing to say' => sub {
    my $repo = _board(
        { id => 1, status => 'done' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'move', '2', 'in-progress', '--claim', 'agent-a', '--json' );
    my $data = eval { decode_json( $r->{stdout} ) };
    ok( $data, 'STDOUT decodes' ) or diag "stdout was: $r->{stdout}";
    ok( !exists $data->{dependency_warnings},
        'no empty array to make a consumer test for length' );
};

subtest '--quiet silences it' => sub {
    my $repo = _board(
        { id => 1, status => 'todo' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'move', '2', 'in-progress', '--claim', 'agent-a', '--quiet' );
    is( $r->{exit}, 0, 'move succeeds' ) or diag $r->{stderr};
    unlike( $r->{stderr}, qr/depends on/, 'STDERR says nothing under --quiet' );
    unlike( $r->{stdout}, qr/depends on/, 'and it did not move to STDOUT either' );
    is( _task( $repo, 2 )->status, 'in-progress', 'the move still happened' );
};

subtest 'edit --status takes the same path and so gets the same warning' => sub {
    my $repo = _board(
        { id => 1, status => 'todo' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'edit', '2', '--status', 'in-progress', '--claim', 'agent-e' );
    is( $r->{exit}, 0, 'edit succeeds' ) or diag $r->{stderr};
    like( $r->{stderr}, qr/task 2 depends on task 1, which is still todo/,
        'the second door into a status change warns like the first (#55)' );
    is( _task( $repo, 2 )->status, 'in-progress', 'and the status changed' );
};

subtest 'edit without --status does not warn' => sub {
    my $repo = _board(
        { id => 1, status => 'todo' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'edit', '2', '--title', 'Renamed' );
    is( $r->{exit}, 0, 'edit succeeds' ) or diag $r->{stderr};
    unlike( $r->{stderr}, qr/depends on/,
        'retitling a card is not taking it up' );
};

subtest 'pick --move warns about the card it hands out' => sub {
    my $repo = _board(
        { id => 1, status => 'backlog' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo,
        'pick', '--claim', 'agent-p', '--status', 'todo', '--move', 'in-progress' );
    is( $r->{exit}, 0, 'pick succeeds' ) or diag $r->{stderr};
    like( $r->{stdout}, qr/Picked task 2/, 'task 2 was handed out' );
    like( $r->{stderr}, qr/task 2 depends on task 1, which is still backlog/,
        'and the agent is told what it is about to start on top of' );
};

subtest 'pick --move into a terminal status does not warn' => sub {
    my $repo = _board(
        { id => 1, status => 'backlog' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo,
        'pick', '--claim', 'agent-p', '--status', 'todo', '--move', 'done' );
    is( $r->{exit}, 0, 'pick succeeds' ) or diag $r->{stderr};
    unlike( $r->{stderr}, qr/depends on/, 'nothing is being started' );
};

subtest 'a bare pick warns too -- the claim is the taking-up' => sub {
    # No --move anywhere. `karr pick --claim X` is the commonest call there is,
    # and after it the agent holds the card and starts; whether the status
    # changed on the way is beside the point. While this one stayed silent,
    # #123's own sentence -- "karr pick hands it out regardless" -- was still
    # true of the command it was written about.
    my $repo = _board(
        { id => 1, status => 'backlog' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'pick', '--claim', 'agent-p', '--status', 'todo' );
    is( $r->{exit}, 0, 'pick succeeds' ) or diag $r->{stderr};
    like( $r->{stdout}, qr/Picked task 2/, 'the card is handed out' );
    like( $r->{stderr}, qr/task 2 depends on task 1, which is still backlog/,
        'and the agent is told what is still open under it' );
    is( _task( $repo, 2 )->claimed_by, 'agent-p', 'the claim landed' );
    is( _task( $repo, 2 )->status, 'todo', 'and the status is untouched' );
};

subtest 'a bare pick with a satisfied dependency stays silent' => sub {
    my $repo = _board(
        { id => 1, status => 'done' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'pick', '--claim', 'agent-p', '--status', 'todo' );
    is( $r->{exit}, 0, 'pick succeeds' ) or diag $r->{stderr};
    like( $r->{stdout}, qr/Picked task 2/, 'the card is handed out' );
    unlike( $r->{stderr}, qr/depends on/, 'nothing outstanding, nothing said' );
};

subtest 'a bare pick of an already finished card says nothing' => sub {
    # --status is the one way a terminal card reaches the claim at all:
    # _is_pickable excludes terminal statuses only when --status is absent. So
    # the status the card *stays in* has to be the one judged when there is no
    # --move, or picking up a finished card would lecture about dependencies
    # that stopped mattering when it was finished.
    my $repo = _board(
        { id => 1, status => 'backlog' },
        { id => 2, status => 'done', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'pick', '--claim', 'agent-p', '--status', 'done' );
    is( $r->{exit}, 0, 'pick succeeds' ) or diag $r->{stderr};
    like( $r->{stdout}, qr/Picked task 2/, 'the finished card is handed out' );
    unlike( $r->{stderr}, qr/depends on/, 'and draws no dependency warning' );
};

subtest 'a bare pick puts the warning in --json, not on STDERR' => sub {
    my $repo = _board(
        { id => 1, status => 'backlog' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo,
        'pick', '--claim', 'agent-p', '--status', 'todo', '--json' );
    is( $r->{exit}, 0, 'pick succeeds' ) or diag $r->{stderr};
    unlike( $r->{stderr}, qr/depends on/, 'not on STDERR under --json' );

    my $data = eval { decode_json( $r->{stdout} ) };
    ok( $data, 'STDOUT decodes' ) or diag "stdout was: $r->{stdout}";
    like( ( $data->{dependency_warnings} || [] )->[0] // '',
        qr/depends on task 1, which is still backlog/,
        'the same sentence rides in the object' );
};

subtest 'pick --json carries the warning in the object' => sub {
    my $repo = _board(
        { id => 1, status => 'backlog' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'pick', '--claim', 'agent-p',
        '--status', 'todo', '--move', 'in-progress', '--json' );
    is( $r->{exit}, 0, 'pick succeeds' ) or diag $r->{stderr};
    unlike( $r->{stderr}, qr/depends on/, 'not on STDERR under --json' );

    my $data = eval { decode_json( $r->{stdout} ) };
    ok( $data, 'STDOUT decodes' ) or diag "stdout was: $r->{stdout}";
    is( $data->{id}, 2, 'the picked card is still the payload' );
    like( ( $data->{dependency_warnings} || [] )->[0] // '',
        qr/depends on task 1, which is still backlog/,
        'with the warning alongside it' );
};

subtest 'show displays depends_on with the state of each dependency' => sub {
    my $repo = _board(
        { id => 1, status => 'done' },
        { id => 3, status => 'in-progress' },
        { id => 2, status => 'todo', depends_on => [ 1, 3, 99 ] },
    );

    my $r = _run_karr( $repo, 'show', '2' );
    is( $r->{exit}, 0, 'show succeeds' ) or diag $r->{stderr};
    like( $r->{stdout}, qr/^Depends:\s+\S/m,
        'the field is finally visible where a human looks' );
    like( $r->{stdout}, qr/1 \(done\)/,        'a finished dependency shows its status' );
    like( $r->{stdout}, qr/3 \(in-progress\)/, 'so does an unfinished one' );
    like( $r->{stdout}, qr/99 \(unknown\)/,    'and a missing one is marked as such' );
};

subtest 'show says nothing about dependencies when there are none' => sub {
    my $repo = _board( { id => 1, status => 'todo' } );

    my $r = _run_karr( $repo, 'show', '1' );
    is( $r->{exit}, 0, 'show succeeds' ) or diag $r->{stderr};
    unlike( $r->{stdout}, qr/^Depends:/m, 'no empty row for a card with no deps' );
};

subtest 'show --json still exposes the raw list' => sub {
    my $repo = _board(
        { id => 1, status => 'done' },
        { id => 2, status => 'todo', depends_on => [1] },
    );

    my $r = _run_karr( $repo, 'show', '2', '--json' );
    my $data = eval { decode_json( $r->{stdout} ) };
    ok( $data, 'STDOUT decodes' ) or diag "stdout was: $r->{stdout}";
    is_deeply( $data->{depends_on}, [1],
        'the machine-readable view keeps the ids themselves' );
};

done_testing;
