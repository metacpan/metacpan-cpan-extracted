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

# Ticket #131: `karr config get KEY --json` wrapped a scalar in its key and
# handed a list or mapping over bare:
#
#     karr config get claim_timeout --json  -> {"claim_timeout":"1h"}
#     karr config get board --json          -> {"name":"App::karr"}
#     karr config get statuses --json       -> ["backlog", ...]
#
# The middle line is the whole problem: it is byte-identical to the wrapped
# form of a scalar key called `name`, and nothing in the payload says which of
# the two it is. A consumer that reads $data->{board} gets undef from a board
# answer and a value from a mapping that happens to have a `board` member, with
# no way to tell the shapes apart.
#
# This is a deliberate break of a machine-readable interface, decided rather
# than fixed: `get` now always wraps, so the key asked for is always in the
# payload and the answer is a one-key subset of the `config show --json`
# object. Consumers reading the bare list or mapping must index the key first.
#
# RED before the change: every "wrapped" assertion below on a ref-valued key
# failed (the payload was the bare array/hash); the scalar ones were already
# green and are pinned here as the half of the contract that did not move.
#
# Driven through the real binary -- the shape is what a caller piping `karr
# config get --json` into a JSON parser sees, and only a subprocess produces
# that.

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
    is( _run_karr( $repo, 'init', '--name', 'Wrapping Board' )->{exit},
        0, 'setup: karr init exits 0' );
    return $repo;
}

sub _json_of {
    my ( $repo, @argv ) = @_;
    my $rv = _run_karr( $repo, @argv, '--json' );
    is( $rv->{exit}, 0, "@argv --json exits 0" ) or diag $rv->{stderr};
    my $data = eval { decode_json( $rv->{stdout} ) };
    ok( $data, "@argv --json is valid JSON" ) or diag "stdout: $rv->{stdout}";
    return $data;
}

subtest 'scalar value: wrapped in its key (unchanged half of the contract)' => sub {
    my $repo = _board_repo();

    is_deeply( _json_of( $repo, 'config', 'get', 'claim_timeout' ),
        { claim_timeout => '1h' }, 'a scalar is the key mapped to its value' );

    # A dotted key wraps under the dotted name it was asked for, not nested --
    # `get` echoes the key as given, so a caller can always look it up by the
    # string it passed in.
    is_deeply( _json_of( $repo, 'config', 'get', 'board.name' ),
        { 'board.name' => 'Wrapping Board' }, 'a dotted key wraps under the dotted key' );
};

subtest 'mapping value: wrapped too, so it cannot be read as a scalar answer (RED, #131)' => sub {
    my $repo = _board_repo();

    my $data = _json_of( $repo, 'config', 'get', 'board' );

    # The exact confusion the ticket names: before the break this printed
    # {"name":"Wrapping Board"}, which is what `config get name --json` would
    # legitimately look like for a scalar key called `name`.
    is_deeply( $data, { board => { name => 'Wrapping Board' } },
        'the mapping sits under the key that was asked for' );
    ok( !exists $data->{name}, 'the mapping members are not at the top level any more' );
};

subtest 'list value: wrapped too, no longer a bare JSON array (RED, #131)' => sub {
    my $repo = _board_repo();

    my $data = _json_of( $repo, 'config', 'get', 'statuses' );

    # Guarded: under the old bare form this payload *was* an array, and an
    # unguarded ->{statuses} would die and take the rest of the file with it
    # instead of reporting the failure.
    is( ref $data, 'HASH', 'the payload is an object, not an array' )
        or return;
    is( ref $data->{statuses}, 'ARRAY', 'the list sits under its key' );
    is( $data->{statuses}[0], 'backlog', 'and is the configured list' );
    is_deeply( $data->{statuses}[2], { name => 'in-progress', require_claim => 1 },
        'entries are carried as configured, mappings and all (#130)' );

    my $classes = _json_of( $repo, 'config', 'get', 'classes' );
    is( ref $classes, 'HASH', 'classes payload is an object too' ) or return;
    is( ref $classes->{classes}, 'ARRAY', 'classes is wrapped the same way' );
};

subtest 'the key is in the payload whatever the value type is (#131)' => sub {
    my $repo = _board_repo();

    # The one property a consumer may rely on, stated once over all three value
    # shapes: whatever `get KEY --json` answers, it is an object whose single
    # key is KEY. That is what the bare forms made impossible.
    for my $key (qw( claim_timeout lock_timeout version tasks_dir
                     board defaults statuses classes priorities )) {
        my $rv   = _run_karr( $repo, 'config', 'get', $key, '--json' );
        my $data = eval { decode_json( $rv->{stdout} ) };
        is( ref $data, 'HASH', "get $key --json is a JSON object" )
            or next;
        is_deeply( [ keys %$data ], [$key],
            "get $key --json carries exactly the requested key" );
    }
};

subtest 'get --json is a one-key subset of show --json (#131)' => sub {
    my $repo = _board_repo();

    my $show = _json_of( $repo, 'config', 'show' );

    # The point of wrapping: the two surfaces speak one schema, so a caller can
    # switch between the whole config and a single key without reshaping.
    for my $key (qw( board statuses classes claim_timeout )) {
        is_deeply( _json_of( $repo, 'config', 'get', $key ),
            { $key => $show->{$key} },
            "get $key --json equals the $key slice of show --json" );
    }

    # `show` itself did not move: still the whole config as one object, keys at
    # the top level and not wrapped in anything.
    is( $show->{version}, 1, 'show --json still carries version at the top level' );
    is( $show->{board}{name}, 'Wrapping Board', 'and the board mapping nested under board' );

    # Bare `karr config --json` is `show`, so it must not drift either.
    is_deeply( _json_of( $repo, 'config' ), $show,
        'bare config --json is still the show payload' );
};

subtest '--defaults answers in the same wrapped shape' => sub {
    my $dir = tempdir( CLEANUP => 1 );   # no board, no repository: --defaults needs neither

    is_deeply( _json_of( $dir, 'config', 'get', 'claim_timeout', '--defaults' ),
        { claim_timeout => '1h' }, 'scalar default is wrapped' );

    my $statuses = _json_of( $dir, 'config', 'get', 'statuses', '--defaults' );
    is( ref $statuses, 'HASH', 'the defaults payload is an object' ) or return;
    is( ref $statuses->{statuses}, 'ARRAY',
        'a list default is wrapped in its key too -- --defaults is not a second schema' );
};

subtest 'an unknown key still fails, it does not answer an empty wrapper' => sub {
    my $repo = _board_repo();

    my $rv = _run_karr( $repo, 'config', 'get', 'no_such_key', '--json' );
    isnt( $rv->{exit}, 0, 'exits non-zero' );
    is( $rv->{stdout}, '', 'nothing on stdout -- no {"no_such_key":null}' );
    like( $rv->{stderr}, qr/Unknown key/, 'stderr says Unknown key' );
};

done_testing;
