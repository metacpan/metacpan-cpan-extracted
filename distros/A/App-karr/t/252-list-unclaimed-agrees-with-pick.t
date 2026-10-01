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
use Path::Tiny qw( path );
use Time::Piece;
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::List;
use App::karr::Cmd::Pick;
use App::karr::Foundation::Picker;

# Ticket #252, part four -- the option the first build halted on rather than
# approximate. Its one hard requirement was that `karr list --unclaimed` reuse
# the claim test `karr pick` applies instead of spelling a second one, and that
# was not reachable: App::karr::Role::PickRules/pickable computed the claim as
# three lines mid-chain with `return 0 if $task->has_blocked` on the very next
# line, so borrowing it meant inheriting "and not blocked" with it.
#
# So the claim test moved into App::karr::Role::ClaimTimeout/claim_held, beside
# the expiry parser it calls, and pickable's three lines became a call to it.
# That refactor is the risk in this change, not the option: `karr pick` and
# karr-foundation's ticket mode both hang off pickable. t/198-pick-rules-shared.t
# and t/72-claim-timeout.t hold the behaviour that must not have moved; this
# file holds what is new.
#
# Three things are pinned here, in rising order of what they are worth:
#
#   * the option answers about the claim and nothing else -- an expired claim
#     is free, `claimed_by: ""` is free (#59), a claim with no stamp is held,
#     and a blocked card is still listed, because blocked is pick's rule and
#     not a statement about who holds the card;
#
#   * the pair with --claimed-by is refused, and the POD's correction of #237
#     is real: --claimed-by matches an expired claim, --unclaimed matches the
#     same card, so the two are not each other's negation;
#
#   * and the one that the refactor exists for: what `list --unclaimed
#     --not-blocked` shows outside backlog is what `karr pick` will actually
#     hand out, drained card by card on the same board.
#
# The two share the claim half of the rule and only that half. Where they part
# -- a blocked card, and since k306 a card held back in backlog -- is pinned
# too, so the difference stays a decision (ticket k309) and not a drift.

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or die "git init failed";
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
  return $repo;
}

# The board's own config, written straight into the ref, so the claim window
# under test is the board's and not a default that happens to agree.
sub _board {
  my (%override) = @_;
  my $repo = _init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config',
    Dump( { version => 1, board => { name => 'Unclaimed Board' }, %override } ) );
  return $repo;
}

# A fresh store per question: both commands here are read paths onto the same
# refs, and a cached store would let an earlier answer stand for a later state.
sub _store {
  my ($repo) = @_;
  return App::karr::BoardStore->new( git => App::karr::Git->new( dir => $repo ) );
}

sub ago {
  my ($secs) = @_;
  return gmtime( time - $secs )->datetime . 'Z';
}

sub mk {
  my ( $repo, %a ) = @_;
  my $t = App::karr::Task->new(
    id       => $a{id},
    title    => $a{title} // "task $a{id}",
    status   => $a{status}   // 'todo',
    priority => $a{priority} // 'medium',
    class    => $a{class}    // 'standard',
    ( exists $a{blocked}    ? ( blocked    => $a{blocked} )    : () ),
    ( exists $a{claimed_by} ? ( claimed_by => $a{claimed_by} ) : () ),
    ( exists $a{claimed_at} ? ( claimed_at => $a{claimed_at} ) : () ),
  );
  _store($repo)->save_task($t);
  return $t;
}

sub list_out {
  my ( $repo, %opt ) = @_;
  my $cmd = App::karr::Cmd::List->new( store => _store($repo), %opt );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$buf or die $!;
    $cmd->execute( [], [] );
  }
  return $buf;
}

sub list_ids {
  my ( $repo, %opt ) = @_;
  return [ list_out( $repo, %opt ) =~ /^#(\d+)/mg ];
}

sub list_error {
  my ( $repo, %opt ) = @_;
  my $cmd = App::karr::Cmd::List->new( store => _store($repo), %opt );
  my $buf = '';
  my $ok  = eval {
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$buf or die $!;
    $cmd->execute( [], [] );
    1;
  };
  return $ok ? undef : $@;
}

# `karr pick` end to end, returning the id it handed out (or undef). It claims
# what it takes, which is what lets the drain below terminate.
sub pick_id {
  my ( $repo, %opt ) = @_;
  my $cmd = App::karr::Cmd::Pick->new( store => _store($repo), %opt );
  my $buf = '';
  my $err = do {
    local $@;
    eval {
      local *STDOUT;
      local *STDERR;
      open STDOUT, '>', \$buf or die $!;
      open STDERR, '>', \my $noise or die $!;
      $cmd->execute( [], [] );
    };
    $@;
  };
  die "pick died: $err" if $err;
  return $buf =~ /^Picked task (\d+):/m ? $1 : undef;
}

#### what --unclaimed answers

# One board carrying every state the claim field can be in. The two that make
# this more than a `claimed_by` presence check are 3 and 6: an expired claim is
# free even though the name is still on the card, and a claim with no timestamp
# is held even though nothing can date it.
sub _mixed_board {
  my $repo = _board();
  mk( $repo, id => 1, title => 'never claimed' );
  mk( $repo, id => 2, title => 'live claim',    claimed_by => 'agent-busy', claimed_at => ago(60) );
  mk( $repo, id => 3, title => 'expired claim', claimed_by => 'agent-gone', claimed_at => ago( 3 * 3600 ) );
  mk( $repo, id => 4, title => 'blocked and free', blocked => 'waiting on the vendor' );
  mk( $repo, id => 5, title => 'done',          status => 'done' );
  mk( $repo, id => 6, title => 'claim with no stamp', claimed_by => 'agent-nostamp' );
  return $repo;
}

subtest '--unclaimed keeps the cards no live claim holds' => sub {
  my $repo = _mixed_board();

  is_deeply list_ids($repo), [ 1, 2, 3, 4, 6 ],
    'without the flag the list is every open card, claimed or not';

  is_deeply list_ids( $repo, unclaimed => 1 ), [ 1, 3, 4 ],
    '--unclaimed drops the live claim and the undated one, keeps the expired';

  # Each exclusion for its own reason, so a single wrong predicate cannot pass
  # the list above by accident.
  my $ids = { map { $_ => 1 } @{ list_ids( $repo, unclaimed => 1 ) } };
  ok $ids->{1},  'a card that was never claimed is free';
  ok !$ids->{2}, 'a claim taken a minute ago holds the card';
  ok $ids->{3},  'a claim three hours old no longer holds it under a 1h timeout';
  ok $ids->{4},  'a blocked card is unpickable but not claimed, so it is still free';
  ok !$ids->{6}, 'a claim with no claimed_at never expires, so it holds';
};

subtest 'the expired claim is what separates --unclaimed from --claimed-by' => sub {
  # The correction #252 makes to #237, which had assumed the two options were
  # each other's negation. --claimed-by is an exact match on a field that keeps
  # the name until something re-stamps it; --unclaimed asks who holds the card
  # now. Card 3 satisfies both, which is why the pair is refused rather than
  # answered (see the usage-error subtest).
  my $repo = _mixed_board();

  is_deeply list_ids( $repo, claimed_by => 'agent-gone' ), [3],
    '--claimed-by still matches the expired claim by name';
  ok grep( { $_ == 3 } @{ list_ids( $repo, unclaimed => 1 ) } ),
    '...and --unclaimed matches the same card, because nobody holds it';

  # Without expiry there would be nothing to tell the two options apart: on a
  # board whose claims never expire, --unclaimed is exactly "claimed_by empty".
  my $frozen = _board( claim_timeout => '0s' );
  mk( $frozen, id => 1, title => 'never claimed' );
  mk( $frozen, id => 2, title => 'ancient claim',
      claimed_by => 'agent-gone', claimed_at => ago( 86400 * 30 ) );

  is_deeply list_ids( $frozen, unclaimed => 1 ), [1],
    'claim_timeout: 0s means never, so a month-old claim still holds (#232)';
};

subtest '--blocked --unclaimed is a real query, not an empty one' => sub {
  # The reason the first build of #252 halted instead of calling pickable with
  # neutralised filters: pickable also refuses a blocked card, so this pair
  # would have been permanently empty and --unclaimed would have quietly meant
  # "free AND not blocked". kanban-md's IsUnclaimed (internal/board/filter.go)
  # asks about the claim and nothing else, and so does this.
  my $repo = _board();
  mk( $repo, id => 1, title => 'blocked and free',  blocked => 'waiting' );
  mk( $repo, id => 2, title => 'blocked and held',  blocked => 'waiting',
      claimed_by => 'agent-busy', claimed_at => ago(60) );
  mk( $repo, id => 3, title => 'open and free' );

  is_deeply list_ids( $repo, unclaimed => 1, blocked => 1 ), [1],
    'the blocked card nobody holds is the answer, not an empty list';
  is_deeply list_ids( $repo, unclaimed => 1, not_blocked => 1 ), [3],
    'and --not-blocked is how you ask for the pickable ones';
};

subtest 'the claim test itself, including the states the load path hides' => sub {
  # Straight at the method, because two of its cases cannot be put on a board:
  # App::karr::Task/BUILD normalizes `claimed_by: ""` back to unset on the
  # parse path (#98), so the emptiness guard the #59 fix put in pickable is
  # only reachable on a task object held in memory. It is still the guard that
  # keeps a hand-written or third-party card from looking held, and it moved
  # into claim_held verbatim, so it is pinned where it lives.
  my $repo = _board();
  my $cmd  = App::karr::Cmd::List->new( store => _store($repo) );

  my $mk = sub {
    my (%a) = @_;
    return App::karr::Task->new(
      id => 1, title => 'card', status => 'todo', priority => 'medium', %a );
  };

  ok !$cmd->claim_held( $mk->() ), 'no claim at all: free';

  my $empty = $mk->();
  $empty->claimed_by('');
  ok !$cmd->claim_held($empty),
    '`claimed_by: ""` is kanban-md for unclaimed, not for held (#59)';

  ok $cmd->claim_held( $mk->( claimed_by => 'a', claimed_at => ago(60) ) ),
    'a fresh claim holds';
  ok !$cmd->claim_held( $mk->( claimed_by => 'a', claimed_at => ago( 3 * 3600 ) ) ),
    'a claim past the board timeout does not';
  ok $cmd->claim_held( $mk->( claimed_by => 'a' ) ),
    'a claim with no stamp cannot expire, so it holds';

  # The explicit window, which is how a whole-board filter asks once for the
  # run. 0 is no window rather than the shortest one.
  my $old = $mk->( claimed_by => 'a', claimed_at => ago( 3 * 3600 ) );
  ok !$cmd->claim_held( $old, 3600 ), 'expired under an explicit 1h window';
  ok $cmd->claim_held( $old, 4 * 3600 ),  '...still held under a wider one';
  ok $cmd->claim_held( $old, 0 ), '...and held under 0, which disables expiry';
};

#### one definition of "free"

subtest 'list and pick resolve the claim test to the same coderef' => sub {
  # Not "both are correct today" but "both are the same method". A copy that
  # happens to agree is what #59 and #198 are about, and it is what a
  # behavioural test alone cannot rule out.
  ok( App::karr::Cmd::List->does('App::karr::Role::ClaimTimeout'),
    'karr list composes the claim role' );
  ok( App::karr::Cmd::Pick->does('App::karr::Role::PickRules'),
    'karr pick composes the pick rules' );

  my $listed = App::karr::Cmd::List->can('claim_held');
  my $picked = App::karr::Cmd::Pick->can('claim_held');
  ok $listed, 'list has claim_held';
  is $listed, $picked, 'and it is literally pick\'s claim_held, not a twin';
  is $listed, App::karr::Foundation::Picker->can('claim_held'),
    'karr-foundation\'s ticket mode resolves to the same one';
};

subtest 'neither caller keeps a claim test of its own to drift with' => sub {
  # The re-fork guard, in the shape t/198 uses for pick and foundation. POD and
  # comments are stripped: every file here discusses the rule at length.
  my $strip = sub {
    my $src = path(shift)->slurp_utf8;
    $src =~ s/^=\w+.*?^=cut\b.*?$//msg;
    $src =~ s/^\s*#.*$//mg;
    return $src;
  };

  my $rules = $strip->('lib/App/karr/Role/PickRules.pm');
  like $rules, qr/\$self->claim_held\(/,
    'pickable asks for the claim test';
  unlike $rules, qr/_claim_expired/,
    '...and no longer parses the expiry itself';
  unlike $rules, qr/has_claimed_by/,
    '...nor reads the claim field itself';

  my $list = $strip->('lib/App/karr/Cmd/List.pm');
  like $list, qr/\$self->claim_held\(/,
    '--unclaimed asks the same method';
  unlike $list, qr/_claim_expired/,
    '...and does not reach past it to the expiry parser';
  unlike $list, qr/claim_timeout(?!_secs)/,
    '...nor read the board timeout setting for itself';

  # And the expiry test exists once in the whole distribution: a third caller
  # reaching past claim_held to _claim_expired is the same fork by another
  # route.
  my @spellers;
  path('lib')->visit(
    sub {
      my ($p) = @_;
      return unless $p->is_file && $p =~ /\.pm\z/;
      my $rel = $p->relative('.')->stringify;
      return if $rel eq 'lib/App/karr/Role/ClaimTimeout.pm';
      push @spellers, $rel if $strip->($rel) =~ /_claim_expired/;
    },
    { recurse => 1 }
  );
  is_deeply \@spellers, [],
    'App::karr::Role::ClaimTimeout is the only file that reads a claim stamp';
};

subtest 'the board timeout is read once per run, not once per card' => sub {
  # The window has to cover the whole listing, or a long run could judge its
  # first card against one number and its last against another. Counted rather
  # than reasoned about, because "pass it in" is exactly the kind of detail a
  # later edit drops back to a per-card default.
  my $repo = _board();
  mk( $repo, id => $_, title => "task $_" ) for 1 .. 8;

  my $calls = 0;
  my $orig  = App::karr::Cmd::List->can('claim_timeout_secs');
  {
    no warnings 'redefine';
    no strict 'refs';
    local *App::karr::Cmd::List::claim_timeout_secs = sub { $calls++; goto &$orig };
    is_deeply list_ids( $repo, unclaimed => 1 ), [ 1 .. 8 ], 'all eight are free';
  }
  is $calls, 1, 'eight cards, one read of the board claim_timeout';

  $calls = 0;
  {
    no warnings 'redefine';
    no strict 'refs';
    local *App::karr::Cmd::List::claim_timeout_secs = sub { $calls++; goto &$orig };
    list_ids($repo);
  }
  is $calls, 0, 'and a list without --unclaimed never reads it at all';
};

#### the guarantee the refactor was made for

subtest 'what --unclaimed shows free is what pick hands out' => sub {
  # The whole point of reusing pickable's test. `list --unclaimed --not-blocked`
  # is the claim rule plus two of pick's other exclusions -- blocked, and the
  # board's terminal statuses, which list hides by default -- so on a board
  # with nothing in backlog the set has to be exactly what pick will give up,
  # one card at a time, until it has none. Backlog, pick's third exclusion, is
  # the next subtest.
  my $repo = _mixed_board();
  mk( $repo, id => 7, title => 'archived',  status => 'archived' );
  mk( $repo, id => 8, title => 'also free' );

  my @free = sort { $a <=> $b } @{ list_ids( $repo, unclaimed => 1, not_blocked => 1 ) };
  ok scalar @free, 'the board has free cards to compare -- ' . join( ',', @free );

  my @drained;
  for my $round ( 1 .. 20 ) {
    my $id = pick_id( $repo, claim => "agent-$round" );
    last unless defined $id;
    push @drained, $id;
  }

  is_deeply [ sort { $a <=> $b } @drained ], \@free,
    'pick hands out exactly the cards the list called free, and no others';

  # And once pick has drained the board the list agrees it is empty -- the same
  # question asked from the other end, which is what catches a filter that is
  # merely a subset of the rule.
  is_deeply list_ids( $repo, unclaimed => 1, not_blocked => 1 ), [],
    'after the drain nothing is free, because pick claimed it all';
  is pick_id( $repo, claim => 'agent-last' ), undef, 'and pick agrees';
};

subtest 'a backlog card is unclaimed and still not pickable (k309)' => sub {
  # Decided in ticket k309: --unclaimed keeps kanban-md's IsUnclaimed meaning,
  # "no live claim holds this card", and does not grow into "pick would take
  # it". Since k306 a backlog card is held back -- pick never hands it out and
  # it cannot gain a claim -- so it is always unclaimed and never pickable,
  # the same parting a blocked card already had. The pickable set is `list
  # --unclaimed --not-blocked` minus backlog. Narrowing --unclaimed or widening
  # pick both fail here, which is what keeps the difference deliberate.
  my $repo = _board();
  mk( $repo, id => 1, title => 'held back', status => 'backlog' );
  mk( $repo, id => 2, title => 'released',  status => 'todo' );

  is_deeply list_ids( $repo, unclaimed => 1 ), [ 1, 2 ],
    '--unclaimed lists the backlog card: nobody holds it';
  is_deeply list_ids( $repo, unclaimed => 1, not_blocked => 1 ), [ 1, 2 ],
    '...and --not-blocked does not take it out either';

  is pick_id( $repo, claim => 'agent-a' ), 2, 'pick hands out the todo card';
  is pick_id( $repo, claim => 'agent-b' ), undef,
    '...and nothing after it: the backlog card is not pickable';

  is_deeply list_ids( $repo, unclaimed => 1, not_blocked => 1 ), [1],
    'while the list still calls the backlog card unclaimed';
  ok !App::karr::Git->new( dir => $repo )->load_task_ref(1)->has_claimed_by,
    'because it still carries no claim';
};

#### the contradicting pair

subtest '--unclaimed with --claimed-by is a usage error' => sub {
  # Decided the way #235 decided the other pairs in this file, and deliberately
  # so even though this pair -- unlike --blocked/--not-blocked -- has a
  # non-empty common case: a card NAME claimed and no longer holds satisfies
  # both. That is the argument for refusing rather than against it. The
  # invocation's author meant "free cards" or "NAME's cards", and a silent
  # answer hands back a plausible, non-empty third list instead of saying so.
  my $repo = _mixed_board();

  my $err = list_error( $repo, unclaimed => 1, claimed_by => 'agent-gone' );
  ok defined $err, 'the pair dies';
  like $err, qr/^Usage error: cannot use --unclaimed and --claimed-by together/,
    'the message names both flags and carries the exit-2 marker';
  unlike $err, qr/List\.pm line \d+/, 'no karr source location leaks out';

  is list_error( $repo, unclaimed  => 1 ),              undef, 'each alone is fine';
  is list_error( $repo, claimed_by => 'agent-gone' ),   undef, '...both of them';

  # The guard asks `defined`, the same way the --class validation two lines
  # below it does, and not truth. #243's argv gate means an empty string cannot
  # arrive from a shell (`karr list --claimed-by ''` is refused before the
  # command is built), so this is reachable programmatically only -- but a
  # truthiness guard here is the shape #153, #239 and #244 keep having to undo,
  # and it would quietly turn the refused pair into a bare --unclaimed.
  ok defined list_error( $repo, unclaimed => 1, claimed_by => '' ),
    'an empty --claimed-by does not slip past the guard as "absent"';
};

#### the CLI, where the exit codes live

subtest 'the CLI wires --unclaimed and its exit code (ADR 0002)' => sub {
  my $ROOT = abs_path('.');
  my $repo = _init_repo();

  my $run = sub {
    my (@argv) = @_;
    my $old = getcwd();
    chdir $repo or die "chdir $repo: $!";
    my $errfh = gensym;
    my $pid = open3( undef, my $outfh, $errfh, $^X, "-I$ROOT/lib", "$ROOT/bin/karr", @argv );
    my $out = do { local $/; <$outfh> };
    my $err = do { local $/; <$errfh> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;
    chdir $old or die "chdir $old: $!";
    return { exit => $exit, stdout => $out // '', stderr => $err // '' };
  };

  is $run->( 'init', '--name', 'Unclaimed Board' )->{exit}, 0, 'setup: karr init exits 0';
  is $run->( 'create', '--title', 'free' )->{exit},    0, 'setup: task 1';
  # In todo: a backlog card holds no claim (ticket k306).
  is $run->( 'create', '--title', 'held', '--status', 'todo' )->{exit}, 0, 'setup: task 2';
  is $run->( 'create', '--title', 'blocked' )->{exit}, 0, 'setup: task 3';
  is $run->( 'edit', '2', '--claim', 'agent-fox' )->{exit}, 0, 'setup: task 2 claimed';
  is $run->( 'edit', '3', '--block', 'waiting' )->{exit},   0, 'setup: task 3 blocked';

  my $free = $run->('list', '--unclaimed');
  is $free->{exit}, 0, '--unclaimed is accepted';
  is_deeply [ $free->{stdout} =~ /^#(\d+)/mg ], [ 1, 3 ],
    'the fresh claim is out and the blocked-but-free card is in';

  # --claimed-by first on purpose: a boolean flag in front of a dashed long
  # option swallows its name before MooX::Options rewrites the dash, so
  # `--unclaimed --claimed-by X` answers "Unknown option: claimed-by" today.
  # Not this option's bug -- `karr list --json --claimed-by NAME` has always
  # failed the same way -- and filed as #256. This asserts the message karr
  # owns, in the order that reaches it.
  my $both = $run->( 'list', '--claimed-by', 'agent-fox', '--unclaimed' );
  is $both->{exit}, 2, 'the contradicting pair exits 2';
  like $both->{stderr}, qr/cannot use --unclaimed and --claimed-by together/,
    'stderr refuses the pair rather than picking one';
  is $both->{stdout}, '', 'and nothing was printed on stdout first';
};

done_testing;
