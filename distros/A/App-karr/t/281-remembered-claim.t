use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use Encode qw( encode );

use App::karr::AgentName qw( agent_name checkout_basename sanitize_claim_token );

# Ticket #281 / ADR 0005: the claim name is derived from the checkout directory
# (`karr agent-name`) and carried per process in KARR_CLAIM, from which every
# claiming command defaults when --claim is omitted. This test pins:
#
#   * agent-name = sanitised worktree-root basename, stable, subdir-independent
#   * --unique appends a short distinguishing suffix
#   * a dir name with spaces / uppercase / non-ASCII sanitises correctly
#   * KARR_CLAIM defaults --claim on move, pick, edit, create, handoff, and
#     --claimed-by on list; an explicit flag always wins
#   * pick no longer requires --claim once KARR_CLAIM is set; with neither, it
#     and handoff are usage errors naming both ways out
#   * the require_claim refusal names both ways, with the "unset" clause only
#     when KARR_CLAIM really is empty
#   * a non-ASCII KARR_CLAIM survives the character/octet boundary

sub _run_karr { return run_karr(@_) }

# A repository whose directory has a chosen name, so the derived agent-name is
# predictable. Returns the repo path (a child of a CLEANUP tempdir).
sub _named_repo {
    my ( $dirname, %opt ) = @_;
    my $parent = tempdir( CLEANUP => 1 );
    my $repo   = path($parent)->child($dirname);
    $repo->mkpath;
    $repo = "$repo";
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
      or die 'git config failed';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
      or die 'git config failed';
    unless ( $opt{no_board} ) {
        my $init = _run_karr( $repo, 'init', '--name', 'k281 Board' );
        is( $init->{exit}, 0, "init in $dirname" ) or diag $init->{stderr};
    }
    return $repo;
}

sub _claimed_of {
    my ( $repo, $id ) = @_;
    my $show = _run_karr( $repo, 'show', $id );
    return $show->{stdout} =~ /^Claimed:\s+(\S.*?)\s*$/m ? $1 : undef;
}

#### The reusable module (what Foundation::Runner will also call)

subtest 'App::karr::AgentName::sanitize_claim_token folds to a claim-safe token' => sub {
    is( sanitize_claim_token('My Project!'), 'my-project', 'space and punctuation' );
    is( sanitize_claim_token('UPPER'),        'upper',      'lowercased' );
    is( sanitize_claim_token('a__b--c'),      'a-b-c',      'runs collapse to one dash' );
    is( sanitize_claim_token('---x---'),      'x',          'ends trimmed' );
    is( sanitize_claim_token("caf\x{e9}-bar"),'caf-bar',    'non-ASCII folds to a dash' );
    is( sanitize_claim_token('!!!'),          '',           'nothing survives -> empty' );
};

subtest 'agent_name(dir => ...) is the sanitised worktree basename' => sub {
    my $repo = _named_repo('Graphify Fix');
    is( agent_name( dir => $repo ), 'graphify-fix',
        'the checkout name, sanitised' );
    # From a nested subdirectory: the worktree root is discovered, not the cwd.
    my $sub = path($repo)->child('a/b/c');
    $sub->mkpath;
    is( agent_name( dir => "$sub" ), 'graphify-fix',
        'subdirectory resolves to the same worktree root' );
};

subtest 'agent_name(unique => 1) keeps the base and adds a short suffix' => sub {
    my $repo = _named_repo('unique-repo', no_board => 1 );
    my $base = agent_name( dir => $repo );
    is( $base, 'unique-repo', 'the base name' );

    my %seen;
    for ( 1 .. 8 ) {
        my $u = agent_name( dir => $repo, unique => 1 );
        like( $u, qr/\Aunique-repo-[a-z0-9]{3}\z/,
            'base plus a 3-char alphanumeric suffix' );
        $seen{$u}++;
    }
    cmp_ok( scalar keys %seen, '>', 1,
        'the suffix actually varies between calls' );
};

subtest 'agent_name falls back to the cwd basename outside a work tree' => sub {
    my $bare = tempdir( CLEANUP => 1 );
    my $dir  = path($bare)->child('Loose Dir');
    $dir->mkpath;
    is( agent_name( dir => "$dir" ), 'loose-dir',
        'no git repo: the sanitised directory basename' );
};

#### The command

subtest 'karr agent-name prints the checkout name; --unique adds a suffix' => sub {
    my $repo = _named_repo('My Project');
    my $rv = _run_karr( $repo, 'agent-name' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    is( $rv->{stdout}, "my-project\n", 'the sanitised checkout name' );

    my $u = _run_karr( $repo, 'agent-name', '--unique' );
    is( $u->{exit}, 0, '--unique exit 0' ) or diag $u->{stderr};
    like( $u->{stdout}, qr/\Amy-project-[a-z0-9]{3}\n\z/,
        '--unique keeps the base and adds a distinguishing suffix' );

    my $j = _run_karr( $repo, 'agent-name', '--json' );
    like( $j->{stdout}, qr/\A\{"name":"my-project"\}/, '--json wraps the name' );
};

#### KARR_CLAIM as the default across the claiming commands

subtest 'KARR_CLAIM defaults --claim on move, and an explicit flag wins' => sub {
    my $repo = _named_repo('board');
    _run_karr( $repo, 'create', 'A' );
    _run_karr( $repo, 'create', 'B' );

    {
        local $ENV{KARR_CLAIM} = 'env-agent';
        my $rv = _run_karr( $repo, 'move', '1', 'in-progress' );
        is( $rv->{exit}, 0, 'move with no --claim succeeds via env' )
          or diag $rv->{stderr};
        is( _claimed_of( $repo, 1 ), 'env-agent', 'claimed under KARR_CLAIM' );

        my $rv2 = _run_karr( $repo, 'move', '2', 'in-progress', '--claim', 'flag-agent' );
        is( $rv2->{exit}, 0, 'move with --claim succeeds' ) or diag $rv2->{stderr};
        is( _claimed_of( $repo, 2 ), 'flag-agent',
            'explicit --claim beats KARR_CLAIM' );
    }
};

subtest 'KARR_CLAIM defaults create and edit' => sub {
    my $repo = _named_repo('board');
    {
        local $ENV{KARR_CLAIM} = 'env-agent';
        my $c = _run_karr( $repo, 'create', 'Claimed at birth', '--status',
            'in-progress' );
        is( $c->{exit}, 0, 'create --status in-progress satisfied by env' )
          or diag $c->{stderr};
        is( _claimed_of( $repo, 1 ), 'env-agent', 'create stamped the env claim' );

        my $e = _run_karr( $repo, 'edit', '1', '-a', 'note' );
        is( $e->{exit}, 0, 'edit succeeds (owns the claim via env)' )
          or diag $e->{stderr};
    }
};

subtest 'pick no longer requires --claim when KARR_CLAIM is set' => sub {
    my $repo = _named_repo('board');
    _run_karr( $repo, 'create', 'Pick me' );
    {
        local $ENV{KARR_CLAIM} = 'env-agent';
        my $rv = _run_karr( $repo, 'pick', '--move', 'in-progress' );
        is( $rv->{exit}, 0, 'pick with no --claim succeeds via env' )
          or diag $rv->{stderr};
        like( $rv->{stdout}, qr/claimed by env-agent/,
            'the pick line reports the env claim' );
        is( _claimed_of( $repo, 1 ), 'env-agent', 'and the card holds it' );
    }
};

subtest 'pick and handoff with neither flag nor env are usage errors' => sub {
    my $repo = _named_repo('board');
    _run_karr( $repo, 'create', 'Card' );
    local $ENV{KARR_CLAIM};
    delete $ENV{KARR_CLAIM};

    my $pick = _run_karr( $repo, 'pick' );
    is( $pick->{exit}, 2, 'pick without a claim is a usage error (2)' )
      or diag $pick->{stderr};
    like( $pick->{stderr}, qr/needs a claim, and KARR_CLAIM is unset/,
        'and names the empty environment' );
    like( $pick->{stderr}, qr/^  export KARR_CLAIM=\$\(karr agent-name\)/m,
        'the once-per-session export is named' );
    like( $pick->{stderr}, qr/^  karr pick --claim NAME$/m,
        'the immediate --claim invocation is named too' );

    my $ho = _run_karr( $repo, 'handoff', '1' );
    is( $ho->{exit}, 2, 'handoff without a claim is a usage error (2)' )
      or diag $ho->{stderr};
    like( $ho->{stderr}, qr/needs a claim, and KARR_CLAIM is unset/,
        'handoff names it the same way' );
};

subtest 'handoff defaults its claim from KARR_CLAIM' => sub {
    my $repo = _named_repo('board');
    _run_karr( $repo, 'create', 'Card' );
    {
        local $ENV{KARR_CLAIM} = 'env-agent';
        _run_karr( $repo, 'move', '1', 'in-progress' );
        my $ho = _run_karr( $repo, 'handoff', '1', '--note', 'done' );
        is( $ho->{exit}, 0, 'handoff with no --claim succeeds via env' )
          or diag $ho->{stderr};
    }
};

#### require_claim refusal names both ways

subtest 'require_claim refusal names both ways, unset clause only when unset' => sub {
    my $repo = _named_repo('board');
    _run_karr( $repo, 'create', 'Card' );

    {
        local $ENV{KARR_CLAIM};
        delete $ENV{KARR_CLAIM};
        my $rv = _run_karr( $repo, 'move', '1', 'in-progress' );
        is( $rv->{exit}, 1, 'refused (exit 1) with neither flag nor env' );
        like( $rv->{stderr},
            qr/^Status 'in-progress' requires a claim, and KARR_CLAIM is unset:$/m,
            'the unset clause is present when the env is empty' );
        like( $rv->{stderr}, qr/^  export KARR_CLAIM=\$\(karr agent-name\)/m,
            'the export way is named' );
        like( $rv->{stderr}, qr/^  karr move 1 in-progress --claim NAME$/m,
            'the --claim way is named' );
    }

    # With KARR_CLAIM set the column is satisfied, so the refusal never fires --
    # which is exactly why the "unset" clause is only ever seen when true.
    {
        local $ENV{KARR_CLAIM} = 'env-agent';
        my $ok = _run_karr( $repo, 'move', '1', 'in-progress' );
        is( $ok->{exit}, 0, 'and KARR_CLAIM satisfies the require_claim column' )
          or diag $ok->{stderr};
    }
};

#### list --claimed-by

subtest 'list --claimed-by defaults from KARR_CLAIM; --unclaimed suppresses it' => sub {
    my $repo = _named_repo('board');
    _run_karr( $repo, 'create', 'Mine' );
    _run_karr( $repo, 'create', 'Theirs' );
    _run_karr( $repo, 'move', '1', 'in-progress', '--claim', 'mine' );
    _run_karr( $repo, 'move', '2', 'in-progress', '--claim', 'theirs' );

    {
        local $ENV{KARR_CLAIM} = 'mine';
        my $list = _run_karr( $repo, 'list', '--compact' );
        like( $list->{stdout},   qr/Mine/,   'a bare list shows the env owner card' );
        unlike( $list->{stdout}, qr/Theirs/, 'and hides the other owner card' );

        # --unclaimed asks the opposite question; the env default steps aside
        # rather than colliding with it into a usage error.
        my $un = _run_karr( $repo, 'list', '--unclaimed', '--compact' );
        is( $un->{exit}, 0, '--unclaimed with KARR_CLAIM set is not a usage error' )
          or diag $un->{stderr};
        unlike( $un->{stdout}, qr/Mine|Theirs/,
            'both cards are claimed, so --unclaimed lists neither' );
    }
};

#### encoding boundary

subtest 'a non-ASCII KARR_CLAIM survives the character/octet boundary' => sub {
    my $repo = _named_repo('board');
    _run_karr( $repo, 'create', 'Card' );

    # The environment holds octets, as a real shell would set them: UTF-8 bytes.
    my $claim_chars = "caf\x{e9}-fox";
    my $claim_bytes = encode( 'UTF-8', $claim_chars );
    local $ENV{KARR_CLAIM} = $claim_bytes;

    my $rv = _run_karr( $repo, 'move', '1', 'in-progress' );
    is( $rv->{exit}, 0, 'move via a non-ASCII env claim succeeds' )
      or diag $rv->{stderr};
    # The captured STDOUT is octets, as it is off a real terminal. A correct
    # round trip renders the claim as the SAME UTF-8 bytes that went in; a double
    # encode (the bug this boundary prevents) would render c3 83 c2 a9 instead.
    is( _claimed_of( $repo, 1 ), $claim_bytes,
        'the card holds the decoded name, re-emitted as clean UTF-8 (no mojibake)' );
};

done_testing;
