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

# Ticket #130: `karr config get statuses` printed
#
#     backlog, todo, HASH(0x558580cd1688), HASH(0x558582ac9348), done, archived
#
# The statuses and classes lists allow both a bare name and the mapping form
# ({ name => 'in-progress', require_claim => 1 }), and the default board uses
# both: two statuses carry require_claim, every class carries wip_limit or
# bypass_column_wip. The renderer joined the raw list, so every mapping came out
# as its address. `classes` was worse than `statuses` -- all four entries are
# mappings, so the answer was four addresses and no names at all.
#
# Not cosmetic: this is the output a reader consults to learn which columns a
# board has, and two unreadable entries invite invention -- the ticket was filed
# after an agent claimed a board ran an "extended status set" with a `closed`
# status that no board in the tree configures.
#
# The fix renders an entry as its name plus its per-entry settings in
# parentheses, in `get` and in `show` alike, so the two surfaces cannot disagree
# about what the board's columns are. --json keeps carrying the entries exactly
# as configured -- it was already faithful, and is pinned here so a rendering
# fix can never be "helpfully" pushed into the machine-readable payload. That
# assurance is about the entries, not about the envelope: #131 later wrapped
# every `config get --json` answer in its key, so the expectations here are
# `{ statuses => [...] }` where they used to be a bare array. t/138 owns the
# envelope.
#
# Driven through the real binary: the bug lived in the command's renderer, and
# an in-process assertion on Config->statuses (t/02, t/53) stayed green
# throughout -- those accessors normalize to names and are exactly what `config
# get` was not using.

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

# Fresh throwaway board per subtest -- never the developer's own.
sub _board_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
        or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
        or die 'git config';
    is( _run_karr( $repo, 'init', '--name', 'Rendering Board' )->{exit},
        0, 'setup: karr init exits 0' );
    return $repo;
}

sub _line {
    my ($text) = @_;
    $text =~ s/\s+\z//;
    return $text;
}

subtest 'config get statuses names every column and no address (RED, #130)' => sub {
    my $repo = _board_repo();

    my $rv = _run_karr( $repo, 'config', 'get', 'statuses' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    unlike( $rv->{stdout}, qr/HASH\(0x/, 'no stringified hash ref' );

    is( _line( $rv->{stdout} ),
        'backlog, todo, in-progress (require_claim: 1), review (require_claim: 1), done, archived',
        'every status is named, and the two that need a claim say so' );
};

subtest 'config get classes names every class and its settings (RED, #130)' => sub {
    my $repo = _board_repo();

    my $rv = _run_karr( $repo, 'config', 'get', 'classes' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    unlike( $rv->{stdout}, qr/HASH\(0x/, 'no stringified hash ref' );

    # All four default classes are mappings, so before the fix this line was
    # four addresses -- the board's classes were unreadable outright.
    is( _line( $rv->{stdout} ),
        'expedite (bypass_column_wip: 1, wip_limit: 1), fixed-date, standard, intangible',
        'names lead, per-class settings follow' );
};

subtest 'config get priorities is unchanged -- a plain list stays plain' => sub {
    my $repo = _board_repo();

    my $rv = _run_karr( $repo, 'config', 'get', 'priorities' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    is( _line( $rv->{stdout} ), 'low, medium, high, critical',
        'no parentheses appear where no entry has settings' );
};

subtest 'config show renders the same lists as config get (#130)' => sub {
    my $repo = _board_repo();

    my $show = _run_karr( $repo, 'config', 'show' );
    is( $show->{exit}, 0, 'exit 0' ) or diag $show->{stderr};
    unlike( $show->{stdout}, qr/HASH\(0x|ARRAY\(0x/, 'no stringified ref anywhere' );

    for my $key (qw( statuses priorities classes )) {
        my ($shown) = $show->{stdout} =~ /^\Q$key\E\s+(.*?)\s*$/m;
        my $got = _line( _run_karr( $repo, 'config', 'get', $key )->{stdout} );
        is( $shown, $got, "config show agrees with config get $key" );
    }
};

subtest '--json carries the entries as configured, not the rendering (#130)' => sub {
    my $repo = _board_repo();

    # The payload is wrapped in the requested key since #131 -- what this
    # subtest guards is the *value*: the entries as configured, never the
    # `name (setting: 1)` rendering above.
    my $statuses = _run_karr( $repo, 'config', 'get', 'statuses', '--json' );
    is( $statuses->{exit}, 0, 'exit 0' ) or diag $statuses->{stderr};
    is_deeply(
        eval { decode_json( $statuses->{stdout} ) },
        {   statuses => [
                'backlog',
                'todo',
                { name => 'in-progress', require_claim => 1 },
                { name => 'review',      require_claim => 1 },
                'done',
                'archived',
            ]
        },
        'statuses --json is the configured structure, mappings and all'
    ) or diag $statuses->{stdout};

    my $classes = _run_karr( $repo, 'config', 'get', 'classes', '--json' );
    is( $classes->{exit}, 0, 'exit 0' ) or diag $classes->{stderr};
    is_deeply(
        eval { decode_json( $classes->{stdout} ) },
        {   classes => [
                { name => 'expedite', wip_limit => 1, bypass_column_wip => 1 },
                { name => 'fixed-date' },
                { name => 'standard' },
                { name => 'intangible' },
            ]
        },
        'classes --json keeps wip_limit and bypass_column_wip'
    ) or diag $classes->{stdout};

    my $priorities = _run_karr( $repo, 'config', 'get', 'priorities', '--json' );
    is_deeply( eval { decode_json( $priorities->{stdout} ) },
        { priorities => [qw( low medium high critical )] },
        'priorities --json is a plain array' )
        or diag $priorities->{stdout};

    my $whole = _run_karr( $repo, 'config', 'show', '--json' );
    is( $whole->{exit}, 0, 'exit 0' ) or diag $whole->{stderr};
    my $data = eval { decode_json( $whole->{stdout} ) };
    is_deeply( $data->{statuses}[2], { name => 'in-progress', require_claim => 1 },
        'config show --json carries the same mapping' )
        or diag $whole->{stdout};
};

subtest 'a board that names its own columns renders them, not the defaults' => sub {
    my $repo = _board_repo();

    # Written straight into the config ref: karr's statuses are not settable
    # from the CLI, so a non-default list only ever arrives through import of a
    # kanban-md config -- and that is exactly the board whose column names a
    # reader cannot guess.
    ok( App::karr::Git->new( dir => $repo )->write_ref(
            'refs/karr/config',
            join( "\n",
                '---',
                'version: 1',
                'board:',
                '  name: Custom',
                'tasks_dir: tasks',
                'statuses:',
                '  - inbox',
                '  - name: doing',
                '    require_claim: 1',
                '  - shipped',
                'priorities:',
                '  - low',
                '  - high',
                'classes:',
                '  - name: rush',
                '    wip_limit: 2',
                '  - name: normal',
                '' )
        ),
        'setup: a board with its own statuses and classes'
    );

    is( _line( _run_karr( $repo, 'config', 'get', 'statuses' )->{stdout} ),
        'inbox, doing (require_claim: 1), shipped',
        q{the board's own status names, with the one that needs a claim marked} );
    is( _line( _run_karr( $repo, 'config', 'get', 'classes' )->{stdout} ),
        'rush (wip_limit: 2), normal', q{the board's own classes} );
};

subtest '#78 still holds: a broken statuses list prints nothing, not an error' => sub {
    my $repo = _board_repo();

    ok( App::karr::Git->new( dir => $repo )->write_ref(
            'refs/karr/config',
            "---\nversion: 1\nboard:\n  name: B\nstatuses: 42\n" ),
        'setup: forged a config with a scalar where the status list belongs' );

    # `config show` is how a broken board is diagnosed, so the renderer must not
    # die dereferencing the very key that is wrong -- pinned again here because
    # the fix moved show off the normalizing Config accessors onto the raw list.
    my $show = _run_karr( $repo, 'config', 'show' );
    is( $show->{exit}, 0, 'config show still exits 0' ) or diag $show->{stderr};
    unlike( $show->{stderr}, qr/ARRAY ref|strict refs/,
        'no raw Perl dereference error leaks out' );
    like( $show->{stdout}, qr/^board\.name\s+B$/m, 'and it prints what it can' );
    like( $show->{stdout}, qr/^statuses\s*$/m, 'the unusable list renders empty' );
};

done_testing;
