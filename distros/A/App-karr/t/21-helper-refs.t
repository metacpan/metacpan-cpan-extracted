use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

use App::karr::Git;

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is($rc, 0, "@cmd");
}

sub _init_bare_remote {
    my $bare = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '--bare', $bare );
    return $bare;
}

sub _init_repo {
    my ( $repo, $email, $name ) = @_;
    _git_ok( 'git', 'init', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', $email );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', $name );
    _git_ok( 'git', '-C', $repo, 'commit', '--allow-empty', '-m', 'init' );
}

sub _default_branch {
    my ($repo) = @_;
    my $branch = `git -C '$repo' rev-parse --abbrev-ref HEAD 2>/dev/null`;
    chomp $branch;
    return $branch;
}

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3(
        undef,
        my $stdout_fh,
        $stderr,
        $^X,
        "-I$ROOT/lib",
        $BIN,
        @argv,
    );

    my $stdout = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";

    return {
        exit   => $exit,
        stdout => defined $stdout ? $stdout : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

subtest 'git helper API normalizes refs and blocks protected namespaces' => sub {
    my $repo = tempdir( CLEANUP => 1 );
    _init_repo( $repo, 'test@example.com', 'Test User' );

    my $git = App::karr::Git->new( dir => $repo );

    can_ok( $git, qw( normalize_ref_name validate_helper_ref push_ref pull_ref ) );
    is(
        $git->normalize_ref_name('superpowers/spec/1234.md'),
        'refs/superpowers/spec/1234.md',
        'bare ref is normalized below refs/'
    );
    is(
        $git->normalize_ref_name('refs/superpowers/spec/1234.md'),
        'refs/superpowers/spec/1234.md',
        'full ref remains unchanged'
    );

    ok(
        eval { $git->validate_helper_ref('refs/superpowers/spec/1234.md'); 1 },
        'non-reserved helper ref is accepted'
    ) or diag $@;

    ok(
        !eval { $git->validate_helper_ref('refs/heads/main'); 1 },
        'heads namespace is rejected'
    );
    like( $@, qr/protected|blocked/i, 'blocked namespace error is descriptive' );
};

subtest 'set-refs and get-refs roundtrip over a remote' => sub {
    my $bare = _init_bare_remote();

    my $repo_a = tempdir( CLEANUP => 1 );
    _init_repo( $repo_a, 'a@test.com', 'Agent A' );
    _git_ok( 'git', '-C', $repo_a, 'remote', 'add', 'origin', $bare );
    my $branch = _default_branch($repo_a);
    _git_ok( 'git', '-C', $repo_a, 'push', 'origin', $branch );

    my $repo_b = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'clone', $bare, $repo_b );
    _git_ok( 'git', '-C', $repo_b, 'config', 'user.email', 'b@test.com' );
    _git_ok( 'git', '-C', $repo_b, 'config', 'user.name', 'Agent B' );

    my $set = _run_karr( $repo_a, 'set-refs', 'superpowers/spec/1234.md', 'hello', 'world' );
    is( $set->{exit}, 0, 'set-refs exits successfully' );
    is( $set->{stdout}, '', 'set-refs keeps payload off stdout' );
    like( $set->{stderr}, qr{refs/superpowers/spec/1234\.md}, 'set-refs reports target ref on stderr' );

    my $get = _run_karr( $repo_b, 'get-refs', 'superpowers/spec/1234.md' );
    is( $get->{exit}, 0, 'get-refs exits successfully' );
    is( $get->{stdout}, "hello world\n", 'get-refs prints payload to stdout' );
    like( $get->{stderr}, qr{refs/superpowers/spec/1234\.md}, 'get-refs reports fetch/read status on stderr' );
};

subtest 'protected namespaces are rejected from the CLI' => sub {
    my $repo = tempdir( CLEANUP => 1 );
    _init_repo( $repo, 'test@example.com', 'Test User' );

    my $rv = _run_karr( $repo, 'set-refs', 'heads/main', 'nope' );
    isnt( $rv->{exit}, 0, 'set-refs fails for protected namespaces' );
    is( $rv->{stdout}, '', 'error path keeps stdout empty' );
    like( $rv->{stderr}, qr/protected|blocked/i, 'stderr explains why the ref is rejected' );
};

done_testing;
