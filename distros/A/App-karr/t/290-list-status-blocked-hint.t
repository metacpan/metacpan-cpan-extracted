use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );

# Regression tests for ticket k290 -- `list --status blocked` is correctly
# rejected (blocked is a filter flag, not a status), but agents type it
# reproducibly reaching for `list --blocked`. The rejection now names the flag
# that was meant for `blocked`/`not-blocked`; every other invalid value keeps
# the plain `(valid: ...)` message. Exit code stays 2 either way (ADR 0002).

sub _git_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    return $repo;
}

sub _board {
    my $repo = _git_repo();
    is( run_karr( $repo, 'init', '--name', 'Blocked Hint' )->{exit},
        0, 'setup: karr init succeeds' );
    is( run_karr( $repo, 'create', '--title', 'A task' )->{exit},
        0, 'setup: karr create' );
    return $repo;
}

subtest 'list --status blocked keeps exit 2 and hints at --blocked' => sub {
    my $repo = _board();

    my $rv = run_karr( $repo, 'list', '--status', 'blocked' );
    is( $rv->{exit}, 2, 'list --status blocked is still a usage error (2)' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
    like( $rv->{stderr}, qr/invalid status "blocked"/,
        'the rejection still names the offending value' );
    like( $rv->{stderr}, qr/karr list --blocked\b/,
        'the message points at the --blocked filter' );
    unlike( $rv->{stderr}, qr/karr list --not-blocked/,
        'the blocked hint does not name --not-blocked' );
};

subtest 'list --status not-blocked hints at --not-blocked' => sub {
    my $repo = _board();

    my $rv = run_karr( $repo, 'list', '--status', 'not-blocked' );
    is( $rv->{exit}, 2, 'list --status not-blocked is still a usage error (2)' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
    like( $rv->{stderr}, qr/invalid status "not-blocked"/,
        'the rejection names the offending value' );
    like( $rv->{stderr}, qr/karr list --not-blocked\b/,
        'the message points at the --not-blocked filter' );
};

subtest 'blocked buried in a comma list still gets the hint' => sub {
    my $repo = _board();

    my $rv = run_karr( $repo, 'list', '--status', 'todo,blocked' );
    is( $rv->{exit}, 2, 'list --status todo,blocked is a usage error (2)' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
    like( $rv->{stderr}, qr/karr list --blocked\b/,
        'a blocked element anywhere in the list triggers the hint' );
};

subtest 'a genuinely-nonsense status gets no filter-flag hint' => sub {
    my $repo = _board();

    my $rv = run_karr( $repo, 'list', '--status', 'wibble' );
    is( $rv->{exit}, 2, 'list --status wibble is still a usage error (2)' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
    like( $rv->{stderr}, qr/invalid status "wibble"/,
        'the rejection names the offending value' );
    unlike( $rv->{stderr}, qr/karr list --/,
        'no filter-flag hint is appended for an unrelated typo' );
    unlike( $rv->{stderr}, qr/filter flag/,
        'no filter-flag prose is appended for an unrelated typo' );
};

done_testing;
