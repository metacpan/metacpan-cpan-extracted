use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use Cwd qw( abs_path );
use File::Temp qw( tempdir );

# Regression tests for ticket #271 -- `list --status bogus` and
# `list --priority bogus` printed an empty list and exited 0, which reads as
# "no such work" when the truth is "no such status/priority". Every element of
# the comma-separated lists is now validated against the board's config before
# any filtering, and `pick --status` gets the same check (its --move already
# had one, ticket #54). ADR 0002 classifies an invalid option value as a usage
# error (2).

my $ROOT = abs_path('.');

sub _run_karr { return run_karr(@_) }

sub _git_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    return $repo;
}

sub _board_with_tasks {
    my ($label) = @_;
    my $repo = _git_repo();
    is( _run_karr( $repo, 'init', '--name', "Board $label" )->{exit},
        0, "setup: karr init succeeds for board $label" );
    for my $title ( 'First task', 'Second task' ) {
        is( _run_karr( $repo, 'create', '--title', $title )->{exit},
            0, "setup: karr create '$title'" );
    }
    return $repo;
}

subtest 'list --status with an unknown element is a usage error' => sub {
    my $repo = _board_with_tasks('ListStatus');

    for my $bad ( 'bogus', 'bogus,todo', 'todo,bogus' ) {
        my $rv = _run_karr( $repo, 'list', '--status', $bad );
        is( $rv->{exit}, 2, "list --status $bad is a usage error (2), not an empty list" )
            or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
        is( $rv->{stdout}, '', "list --status $bad prints no list" );
        like( $rv->{stderr}, qr/invalid status "bogus"/,
            "list --status $bad names the offending value" );
        like( $rv->{stderr}, qr/valid: /,
            "list --status $bad lists the valid statuses" );
    }
};

subtest 'list --priority with an unknown element is a usage error' => sub {
    my $repo = _board_with_tasks('ListPriority');

    for my $bad ( 'bogus', 'bogus,high', 'high,bogus' ) {
        my $rv = _run_karr( $repo, 'list', '--priority', $bad );
        is( $rv->{exit}, 2, "list --priority $bad is a usage error (2), not an empty list" )
            or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
        is( $rv->{stdout}, '', "list --priority $bad prints no list" );
        like( $rv->{stderr}, qr/invalid priority "bogus"/,
            "list --priority $bad names the offending value" );
        like( $rv->{stderr}, qr/valid: /,
            "list --priority $bad lists the valid priorities" );
    }
};

subtest 'list --status archived is accepted even though it is not a column' => sub {
    # `archived` is a real status karr hardcodes (Config/ARCHIVED_STATUS), so a
    # --status filter may name it on any board. The board here has no archived
    # tasks, so the answer is an empty list with exit 0 -- the point is that it
    # is not a usage error.
    my $repo = _board_with_tasks('ListArchived');

    my $rv = _run_karr( $repo, 'list', '--status', 'archived' );
    is( $rv->{exit}, 0, 'list --status archived exits 0 (not a usage error)' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
};

subtest 'list --status with a valid value still works' => sub {
    my $repo = _board_with_tasks('ListValid');

    my $rv = _run_karr( $repo, 'list', '--status', 'backlog,todo' );
    is( $rv->{exit}, 0, 'list --status backlog,todo exits 0' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
    like( $rv->{stdout}, qr/First task/, 'list --status backlog,todo shows the tasks' );
};

subtest 'pick --status with an unknown element is a usage error' => sub {
    my $repo = _board_with_tasks('PickStatus');

    for my $bad ( 'bogus', 'bogus,todo' ) {
        my $rv = _run_karr( $repo, 'pick', '--claim', 'agent-fox', '--status', $bad );
        is( $rv->{exit}, 2,
            "pick --status $bad is a usage error (2), not \"No available tasks\"" )
            or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
        is( $rv->{stdout}, '', "pick --status $bad prints no pick" );
        like( $rv->{stderr}, qr/invalid status "bogus"/,
            "pick --status $bad names the offending value" );
    }
};

subtest 'pick --status archived is accepted' => sub {
    # Same rule as list: `archived` is a valid filter value. No archived task
    # exists, so the pick finds nothing and says so with exit 0 -- the point is
    # that it is not a usage error.
    my $repo = _board_with_tasks('PickArchived');

    my $rv = _run_karr( $repo, 'pick', '--claim', 'agent-fox', '--status', 'archived' );
    is( $rv->{exit}, 0, 'pick --status archived exits 0 (not a usage error)' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
    like( $rv->{stdout}, qr/No available tasks to pick\./,
        'pick --status archived finds nothing and says so' );
};

subtest 'pick --move with an unknown status is a usage error' => sub {
    # Pins the pre-existing check (ticket #54) so the new --status validation
    # does not regress it.
    my $repo = _board_with_tasks('PickMove');

    my $rv = _run_karr( $repo, 'pick', '--claim', 'agent-fox', '--move', 'bogus' );
    is( $rv->{exit}, 2, 'pick --move bogus is a usage error (2)' )
        or diag "stderr: $rv->{stderr}\nstdout: $rv->{stdout}";
    like( $rv->{stderr}, qr/invalid status "bogus"/,
        'pick --move bogus names the offending value' );
};

done_testing;
