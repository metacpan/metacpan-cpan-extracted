use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );

# Ticket #269. The claim refusal used to name the holder and stop:
#
#   karr delete 1 --yes        -> Task 1 is claimed by bob
#                                1 of 1 ids failed
#
# ... with no way out named, and `karr delete` had no --claim to take, so the
# only path through was `karr edit 1 --release` then `karr delete 1 --yes` --
# and nothing said so. Now every command that applies the rule takes --claim
# (delete and archive gained it), and the refusal ends on the caller's own
# command line with --claim HOLDER added, the shape ticket k263 settled on:
#
#   Task 1 is claimed by bob:
#     karr edit 1 --release
#     karr delete 1 --yes --claim bob
#
# The release line is the honest door for a caller who is not the holder; the
# working-command line is the door for the holder (or an agent acting for it).
# Both are asserted for all five commands that apply the rule -- move, edit,
# handoff, delete, archive -- together with the exit codes (ADR 0002, 1) and
# the --json single-line error field.

# In-process runner (t/lib/TestKarr.pm): same ($cwd, @argv) signature and
# { exit, stdout, stderr } return as the open3 helper, dispatched through the
# shared App::karr::Dispatch path -- which is also what records the caller's
# argv for the working-command line.
sub _run_karr { return run_karr(@_) }

# Always a throwaway repo; never the developer's real board.
sub _setup_repo {
    my (%opt) = @_;
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
      or die 'git config failed';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
      or die 'git config failed';

    is( _run_karr( $repo, 'init', '--name', 'Ticket269 Board' )->{exit}, 0,
        'setup: karr init exits 0' );

    for my $n ( 1 .. ( $opt{tasks} || 1 ) ) {
        is( _run_karr( $repo, 'create', "Card $n" )->{exit}, 0,
            "setup: card $n created" );
    }

    return $repo;
}

# The lines a caller actually sees, trailing blanks dropped, so "last line"
# means the last line with anything on it.
sub _lines {
    my ($text) = @_;
    my @lines = split /\n/, $text;
    pop @lines while @lines && $lines[-1] !~ /\S/;
    return @lines;
}

# The working-command line is the last line, except that a batch command still
# owes its "N of M ids failed" summary after the per-id output -- the same
# adjustment t/263 makes for the same reason.
sub _hint_is_last {
    my ( $text, $want, $name ) = @_;
    my @lines = _lines($text);
    my $at    = $lines[-1] =~ /\A\d+ of \d+ ids failed\z/ ? -2 : -1;
    is( $lines[$at], $want, $name ) or diag "full output was:\n$text";
    return;
}

my $HOLDER = 'agent-holder';
my $OTHER  = 'agent-other';

# One refusal, asserted for the parts every command shares: exit 1, the holder
# named, and the release door offered. The working-command line is asserted by
# the caller, whose argv differs per command.
sub _refusal_of {
    my ( $repo, $id, @argv ) = @_;
    my $rv = _run_karr( $repo, @argv );
    is( $rv->{exit}, 1, "karr @argv: exit 1, unchanged (ADR 0002)" )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/\ATask $id is claimed by \Q$HOLDER\E:/,
        '...names the holder' );
    like( $rv->{stderr}, qr/^  karr edit $id --release$/m,
        '...and the release door, which needs no claim knowledge' );
    return $rv;
}

subtest 'every command that applies the rule names both doors' => sub {
    my $repo = _setup_repo( tasks => 5 );

    is( _run_karr( $repo, 'move', '1,2,3,4,5', 'in-progress',
            '--claim', $HOLDER )->{exit}, 0, 'setup: the holder claims all five cards' );

    my %cases = (
        'move'    => [ 'move',    '1', 'review' ],
        'edit'    => [ 'edit',    '2', '--block', 'waiting' ],
        'handoff' => [ 'handoff', '3', '--claim', $OTHER, '--note', 'back for another look' ],
        'delete'  => [ 'delete',  '4', '--yes' ],
        'archive' => [ 'archive', '5' ],
    );

    my %hint = (
        'move'    => "  karr move 1 review --claim $HOLDER",
        'edit'    => "  karr edit 2 --block waiting --claim $HOLDER",
        'handoff' => "  karr handoff 3 --claim $HOLDER --note 'back for another look'",
        'delete'  => "  karr delete 4 --yes --claim $HOLDER",
        'archive' => "  karr archive 5 --claim $HOLDER",
    );

    for my $cmd ( sort keys %cases ) {
        my $rv = _refusal_of( $repo, ( $cases{$cmd}[1] ), @{ $cases{$cmd} } );
        _hint_is_last( $rv->{stderr}, $hint{$cmd},
            "karr @{ $cases{$cmd} }: the caller's own line, with --claim $HOLDER, is last" );
    }
};

subtest 'the suggested line is the invocation that works' => sub {
    my $repo = _setup_repo( tasks => 5 );

    is( _run_karr( $repo, 'move', '1,2,3,4,5', 'in-progress',
            '--claim', $HOLDER )->{exit}, 0, 'setup: the holder claims all five cards' );

    is( _run_karr( $repo, 'move', '1', 'review', '--claim', $HOLDER )->{exit}, 0,
        'karr move 1 review --claim HOLDER works' ) or diag 'move failed';
    is( _run_karr( $repo, 'edit', '2', '--block', 'waiting',
            '--claim', $HOLDER )->{exit}, 0, 'karr edit 2 --block waiting --claim HOLDER works' )
        or diag 'edit failed';
    is( _run_karr( $repo, 'handoff', '3', '--claim', $HOLDER,
            '--note', 'back for another look' )->{exit}, 0,
        'karr handoff 3 --claim HOLDER --note ... works' ) or diag 'handoff failed';
    is( _run_karr( $repo, 'delete', '4', '--yes', '--claim', $HOLDER )->{exit}, 0,
        'karr delete 4 --yes --claim HOLDER works' ) or diag 'delete failed';
    is( _run_karr( $repo, 'archive', '5', '--claim', $HOLDER )->{exit}, 0,
        'karr archive 5 --claim HOLDER works' ) or diag 'archive failed';
};

subtest '--json keeps the error field one line, hint and all' => sub {
    my $repo = _setup_repo();

    is( _run_karr( $repo, 'move', '1', 'in-progress', '--claim', $HOLDER )->{exit},
        0, 'setup: the holder claims the card' );

    my $rv = _run_karr( $repo, 'delete', '1', '--yes', '--json' );
    is( $rv->{exit}, 1, 'exit 1' ) or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stdout}, qr/\Q"error":"Task 1 is claimed by $HOLDER"\E/,
        'the error field is the one line, with no colon where the suggestion was cut' );
    unlike( $rv->{stdout}, qr/karr /, 'no shell line in the JSON payload' );
    like( $rv->{stderr}, qr/\A1 of 1 ids failed\n\z/, 'the batch summary is still on stderr' );
};

subtest 'a batch carries the caller\'s full id list into the hint' => sub {
    my $repo = _setup_repo( tasks => 2 );

    is( _run_karr( $repo, 'move', '1,2', 'in-progress', '--claim', $HOLDER )->{exit},
        0, 'setup: both cards claimed' );
    is( _run_karr( $repo, 'edit', '2', '--release' )->{exit}, 0,
        'setup: card 2 released, so the batch has a success to report' );

    my $rv = _run_karr( $repo, 'delete', '1,2', '--yes' );
    is( $rv->{exit}, 1, 'exit 1' ) or diag $rv->{stdout} . $rv->{stderr};
    _hint_is_last( $rv->{stderr}, "  karr delete 1,2 --yes --claim $HOLDER",
        'the hint quotes the whole id list the caller typed' );
    like( $rv->{stdout}, qr/Deleted task 2: Card 2/,
        'the free card is still deleted' );
    is( ( _lines( $rv->{stderr} ) )[-1], '1 of 2 ids failed',
        'and the summary reports the one failure, last' );
};

subtest 'the = spelling is answered in the = spelling' => sub {
    my $repo = _setup_repo();

    is( _run_karr( $repo, 'move', '1', 'in-progress', '--claim', $HOLDER )->{exit},
        0, 'setup: the holder claims the card' );

    my $rv = _run_karr( $repo, 'edit', '1', "--claim=$OTHER" );
    is( $rv->{exit}, 1, 'exit 1' ) or diag $rv->{stderr};
    _hint_is_last( $rv->{stderr}, "  karr edit 1 --claim=$HOLDER",
        'the hint keeps the spelling the caller typed' );
};

subtest 'release stays the door that needs no claim knowledge' => sub {
    my $repo = _setup_repo();

    is( _run_karr( $repo, 'move', '1', 'in-progress', '--claim', $HOLDER )->{exit},
        0, 'setup: the holder claims the card' );

    my $rv = _run_karr( $repo, 'edit', '1', '--release' );
    is( $rv->{exit}, 0, 'karr edit 1 --release succeeds with no --claim at all' )
        or diag $rv->{stderr};
    is( _run_karr( $repo, 'move', '1', 'review', '--claim', $OTHER )->{exit}, 0,
        'and another agent can now take the card' );
};

done_testing;
