use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );
use Cwd qw( abs_path );
use Path::Tiny qw( path );

# Ticket #176 filed the claim-continuity bug: `karr agentname` minted a NEW
# random name every call, so `karr pick --claim "$(karr agentname)"` followed by
# `karr handoff ID --claim "$(karr agentname)"` claimed under one name and handed
# off under another. The fix recorded on #176 was documentation only -- keep the
# generator random and stateless, warn against the inline shape, show only the
# capture-once idiom.
#
# ADR 0005 (ticket #281) SUPERSEDES that decision. `karr agent-name` is no longer
# random: it returns the checkout's own directory name, sanitised to a claim-safe
# token, which is STABLE across calls. So the very shape #176 warned about now
# agrees with itself, and the recommended carrier is `KARR_CLAIM`, exported once,
# from which every claiming command defaults. This test now pins the new
# contract: the name is stable, the inline substitution is safe, and the mismatch
# #176 was about no longer happens by construction. (The precise agent-name
# behaviour and the KARR_CLAIM default across commands live in t/281.)

# Always a throwaway repo; never the developer's real board.
sub _run_karr { return run_karr(@_) }

sub _setup_repo {
    # A named directory: agent-name derives the claim from the worktree root's
    # basename, so a stable, predictable name needs a stable, predictable dir.
    my $parent = tempdir( CLEANUP => 1 );
    my $repo   = path($parent)->child('continuity-board');
    $repo->mkpath;
    $repo = "$repo";
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
      or die 'git config failed';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
      or die 'git config failed';

    my $init = _run_karr( $repo, 'init', '--name', 'Ticket176 Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    return $repo;
}

sub _name {
    my ( $repo, @args ) = @_;
    my $rv = _run_karr( $repo, 'agent-name', @args );
    is( $rv->{exit}, 0, 'karr agent-name exits 0' ) or diag $rv->{stderr};
    my $name = $rv->{stdout};
    chomp $name;
    return $name;
}

subtest 'agent-name is stable: repeated calls agree (ADR 0005)' => sub {
    my $repo = _setup_repo();

    # The opposite of the property #176 pinned. Six draws must ALL be the same
    # value now -- and be the sanitised checkout basename, not a random word.
    my %seen;
    $seen{ _name($repo) }++ for 1 .. 6;

    is( scalar keys %seen, 1,
        'six karr agent-name calls all return the same name' )
      or diag "calls returned: " . join( ', ', keys %seen );
    is( ( keys %seen )[0], 'continuity-board',
        'and it is the sanitised worktree directory name' );
};

subtest 'the inline substitution #176 warned about now agrees with itself' => sub {
    my $repo = _setup_repo();

    my $create = _run_karr( $repo, 'create', 'Claim continuity' );
    is( $create->{exit}, 0, 'task created' ) or diag $create->{stderr};

    # Claim with one $(karr agent-name), hand off with another: the exact pair
    # #176 said must never be written inline. Because the name is now stable,
    # both substitutions produce the same value, so the handoff matches the claim
    # and succeeds -- the continuity #176 wanted, achieved without a variable.
    my $claimed = _name($repo);
    my $again   = _name($repo);
    is( $again, $claimed, 'two separate agent-name calls produce one name' );

    my $move = _run_karr( $repo, 'move', '1', 'in-progress', '--claim', $claimed );
    is( $move->{exit}, 0, 'move claims the task' ) or diag $move->{stderr};

    my $handoff = _run_karr( $repo, 'handoff', '1', '--claim', $again, '--note', 'x' );
    is( $handoff->{exit}, 0, 'handoff under the same stable name is accepted' )
      or diag $handoff->{stderr};

    my $show = _run_karr( $repo, 'show', '1' );
    like( $show->{stdout}, qr/^Claimed:\s+\Q$claimed\E$/m,
        'the card is held under the checkout name throughout' );
};

subtest 'KARR_CLAIM defaults every claiming call to the checkout name' => sub {
    my $repo = _setup_repo();

    _run_karr( $repo, 'create', 'Exported' );

    my $name = _name($repo);
    is( $name, 'continuity-board', 'the name to export' );

    # The recommended shape: export once, omit --claim everywhere after.
    local $ENV{KARR_CLAIM} = $name;

    my $move = _run_karr( $repo, 'move', '1', 'in-progress' );
    is( $move->{exit}, 0, 'move with no --claim takes it from KARR_CLAIM' )
      or diag $move->{stderr};

    my $handoff = _run_karr( $repo, 'handoff', '1', '--note', 'done' );
    is( $handoff->{exit}, 0, 'handoff with no --claim agrees, via the same env' )
      or diag $handoff->{stderr};

    my $show = _run_karr( $repo, 'show', '1' );
    like( $show->{stdout}, qr/^Claimed:\s+\Q$name\E$/m,
        'the card is held under the exported name' );
};

done_testing;
