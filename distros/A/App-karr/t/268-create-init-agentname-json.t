use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );
use JSON::MaybeXS qw( decode_json );
use Path::Tiny qw( path );

# Ticket #268: create, init and agent-name get --json, each emitting exactly
# one JSON object and nothing else on stdout, so a caller can pipe the result
# into the next step.
#
#   karr create "x" --json   -> the card in the same shape `karr show --json`
#                               uses (frontmatter plus body, one object)
#   karr init --json         -> { "board": { "name": ... }, "gitignore": [...] }
#   karr agent-name --json   -> { "name": "..." }
#
# Before the ticket all three answered "Unknown option: json" with exit 2.
# Sync progress goes to STDERR (Role::SyncLifecycle), so the JSON stream on
# STDOUT stays clean -- asserted here as "nothing else on stdout".

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    return run_karr( $cwd, @argv );
}

# Fresh isolated temp repo per subtest, never the developer's real board.
sub _bare_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo )                                     == 0 or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' )         == 0 or die 'git config';
    return $repo;
}

sub _board_repo {
    my $repo = _bare_repo();
    my $init = _run_karr( $repo, 'init', '--name', 'JSON Board' );
    is( $init->{exit}, 0, 'setup: karr init' ) or diag $init->{stderr};
    return $repo;
}

subtest 'create --json emits the show-shape card and nothing else' => sub {
    my $repo = _board_repo();

    my $rv = _run_karr( $repo, 'create', 'First card', '--body', 'Some body', '--json' );
    is( $rv->{exit}, 0, 'create --json succeeds' ) or diag $rv->{stderr};

    my $data = eval { decode_json( $rv->{stdout} ) };
    is( ref $data, 'HASH', 'stdout is exactly one JSON object' ) or diag $rv->{stdout};
    is( $data->{id},     1,          'id present' );
    is( $data->{title},  'First card', 'title present' );
    is( $data->{status}, 'backlog',  'default status present' );
    is( $data->{body},   'Some body', 'body included, the show --json shape' );
    ok( exists $data->{created} && exists $data->{updated},
        'lifecycle stamps present' );

    unlike( $rv->{stdout}, qr/Created task/, 'no human "Created task" line leaks into stdout' );
    is( $rv->{stderr}, '', 'and nothing on stderr either' ) or diag $rv->{stderr};
};

subtest 'create --json --claim carries the claim fields' => sub {
    my $repo = _board_repo();

    my $rv = _run_karr( $repo, 'create', 'Claimed', '--claim', 'fox-1', '--json' );
    is( $rv->{exit}, 0, 'create --json --claim succeeds' ) or diag $rv->{stderr};

    my $data = eval { decode_json( $rv->{stdout} ) };
    is( ref $data, 'HASH', 'one JSON object' ) or diag $rv->{stdout};
    is( $data->{claimed_by}, 'fox-1', 'claimed_by stamped' );
    ok( exists $data->{claimed_at}, 'claimed_at stamped' );
};

subtest 'create --json with a non-ASCII title round-trips' => sub {
    my $repo = _board_repo();
    my $title = "Fix \x{dc}nicode \x{2014} \x{e4}rger";

    my $rv = _run_karr( $repo, 'create', $title, '--json' );
    is( $rv->{exit}, 0, 'create --json succeeds' ) or diag $rv->{stderr};

    my $data = eval { decode_json( $rv->{stdout} ) };
    is( $data->{title}, $title, 'title round-trips through the JSON boundary' )
        or diag $rv->{stdout};
};

subtest 'agent-name --json emits {"name":"..."} and nothing else' => sub {
    my $repo = _bare_repo();

    my $rv = _run_karr( $repo, 'agent-name', '--json' );
    is( $rv->{exit}, 0, 'agent-name --json succeeds' ) or diag $rv->{stderr};

    my $data = eval { decode_json( $rv->{stdout} ) };
    is( ref $data, 'HASH', 'one JSON object' ) or diag $rv->{stdout};
    like( $data->{name}, qr/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/,
        'name is a claim-safe checkout token (ADR 0005)' );
    is( scalar keys %$data, 1, 'and nothing but the name' );
    is( $rv->{stderr}, '', 'nothing on stderr' ) or diag $rv->{stderr};
};

subtest 'init --json reports board name and gitignore entries' => sub {
    my $repo = _bare_repo();

    my $rv = _run_karr( $repo, 'init', '--name', 'Named Board', '--json' );
    is( $rv->{exit}, 0, 'init --json succeeds' ) or diag $rv->{stderr};

    my $data = eval { decode_json( $rv->{stdout} ) };
    is( ref $data, 'HASH', 'one JSON object' ) or diag $rv->{stdout};
    is( $data->{board}{name}, 'Named Board', 'board name reported' );
    is_deeply( $data->{gitignore}, [ 'tasks/', 'config.yml' ],
        'the .gitignore entries this run added' );

    unlike( $rv->{stdout}, qr/Initialized karr board/, 'no human line leaks into stdout' );
    is( $rv->{stderr}, '', 'nothing on stderr' ) or diag $rv->{stderr};
};

subtest 'init --json without --name reports the default board name' => sub {
    my $repo = _bare_repo();

    my $rv = _run_karr( $repo, 'init', '--json' );
    is( $rv->{exit}, 0, 'init --json succeeds' ) or diag $rv->{stderr};

    my $data = eval { decode_json( $rv->{stdout} ) };
    is( $data->{board}{name}, 'Kanban Board', 'default name reported' );
};

subtest 'init --json --claude-skill still installs, silently' => sub {
    my $repo = _bare_repo();

    my $rv = _run_karr( $repo, 'init', '--claude-skill', '--json' );
    is( $rv->{exit}, 0, 'init --json --claude-skill succeeds' ) or diag $rv->{stderr};

    my $data = eval { decode_json( $rv->{stdout} ) };
    is( ref $data, 'HASH', 'one JSON object' ) or diag $rv->{stdout};
    unlike( $rv->{stdout}, qr/Installed Claude Code skill/,
        'the install confirmation is not on stdout' );

    my $skill = path($repo)->child('.claude/skills/kanban-issues-karr-cli/SKILL.md');
    ok( -f $skill, 'the skill file was still written' );
};

subtest 'the plaintext forms are unchanged' => sub {
    my $repo = _board_repo();

    my $create = _run_karr( $repo, 'create', 'Plain' );
    is( $create->{exit}, 0, 'create without --json succeeds' );
    like( $create->{stdout}, qr/\ACreated task 1: Plain\n\z/,
        'the human line is exactly as before' );

    my $name = _run_karr( $repo, 'agent-name' );
    is( $name->{exit}, 0, 'agent-name without --json succeeds' );
    like( $name->{stdout}, qr/\A[a-z0-9]+(?:-[a-z0-9]+)*\n\z/,
        'the bare name line is a claim-safe checkout token (ADR 0005)' );

    my $repo2 = _bare_repo();
    my $init  = _run_karr( $repo2, 'init', '--name', 'Plain Board' );
    is( $init->{exit}, 0, 'init without --json succeeds' );
    like( $init->{stdout}, qr/\AInitialized karr board in refs\/karr\/\n/,
        'the human line is exactly as before' );
};

done_testing;
