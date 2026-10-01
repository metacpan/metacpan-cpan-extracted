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
use Path::Tiny qw( path );
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Foundation::Picker;

# t/216-ex-sandbox.t (ticket #216) -- coverage for the ex/ fleet sandbox that
# ex/setup.sh builds (ticket #212). #213 was already taken (the missing chain
# CLI) by the time this file was written, hence the gap.
#
# ex/setup.sh builds three demo repos (webapp, docs-site, fleet-hub) with real
# karr boards, .karr files, a karr-foundation config, demo agents under
# ex/bin/ and a chain in the hub, so the console examples in ex/README.md can
# be replayed against a real setup. Only ex/setup.sh, ex/bin/*, ex/scripts/*,
# ex/README.md and ex/.gitignore are tracked; the generated state
# (ex/webapp, ex/docs-site, ex/fleet-hub, ex/config.yml) is gitignored --
# git refs cannot be committed, so it is built at run time instead.
#
# ISOLATION (read this before touching this file): ex/setup.sh derives its
# target directory from its own script path
# (EX="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"), so invoking the real
# ex/setup.sh from a test would build -- and --reset would wipe -- the
# developer's actual sandbox in ex/. That must never happen. This test copies
# only the tracked pieces (setup.sh, bin/, scripts/, README.md, .gitignore)
# into a fresh File::Temp tempdir and runs them there; EX then resolves to
# the *copy*, so the real ex/ is never a cwd or an argument of anything this
# file runs. A snapshot/compare at the very bottom (see
# 'the real ex/ sandbox was never touched') is the regression guard for that
# promise -- if a future edit here accidentally starts operating on the real
# tree, that subtest fails loudly instead of the damage going unnoticed.
#
# STRUCTURAL WRINKLE this isolation has to satisfy: setup.sh derives
# REPO_ROOT as "$EX/.." and, unless KARR_BIN is set, shells out to
# "perl -I$REPO_ROOT/lib $REPO_ROOT/bin/karr"; ex/scripts/write-chain.pl
# separately does `use lib "$FindBin::Bin/../../lib"` for the same reason.
# Both resolve to <tempdir>/lib once EX is <tempdir>/ex, so this test
# symlinks the real repo's lib/ and bin/ into the tempdir root rather than
# copying them -- they are the distribution code under test, not sandbox
# state, and nothing here ever writes through those symlinks. With that in
# place the real setup.sh script runs completely unmodified and unfaked, so
# this is full end-to-end coverage (a real run, real refs, real CLI output),
# not a syntax-only check.
#
# WHAT STAYS UNTESTED, AND WHY: karr-foundation actually driving the demo
# agents (a real drain loop, ticket mode picking up KARR_TASK, cooldown /
# autoblock, the question mailbox) is not exercised here -- ex/README.md's
# later sections walk those through by hand against this same sandbox, and
# the underlying mechanics already have dedicated coverage against synthetic
# fixtures (t/185, t/186, t/191, t/193, ...). This file only proves the
# sandbox *builds* the state those sections and that coverage rely on,
# matching what setup.sh itself claims about it -- not that every demo agent
# script behaves as its comment promises when actually driven by
# karr-foundation.
#
# FIXED BUG, pinned below as a plain (non-TODO) assertion: the script's
# closing hint used to print
#   cd $EX && ../README.md
# which was not a runnable command (README.md is a file, not a program), and
# even read as a path it was wrong -- after "cd $EX" ($EX is already ex/),
# "../README.md" pointed at the repository ROOT's README.md, not
# ex/README.md. Fixed to print the walkthrough path in prose and offer only
# real commands under "Try:". The regression coverage below checks the
# *property* ("every line offered under Try: is an actually runnable
# command, not a bare file path") rather than matching the old broken
# wording, so it also catches the next way this hint could break, not only
# the one already seen.

my $ROOT = abs_path('.');

# ------------------------------------------------------------- generic runner
sub _run {
  my ( $cwd, @cmd ) = @_;
  my $old = getcwd();
  chdir $cwd or die "chdir $cwd: $!";

  my $stderr = gensym;
  my $pid = open3( my $in, my $out, $stderr, @cmd );
  close $in;

  my $stdout      = do { local $/; <$out> };
  my $stderr_text = do { local $/; <$stderr> };
  waitpid( $pid, 0 );
  my $exit = $? >> 8;

  chdir $old or die "chdir $old: $!";
  return {
    exit   => $exit,
    stdout => ( defined $stdout      ? $stdout      : '' ),
    stderr => ( defined $stderr_text ? $stderr_text : '' ),
  };
}

sub _karr {
  my ( $cwd, @argv ) = @_;
  return _run( $cwd, $^X, "-I$ROOT/lib", "$ROOT/bin/karr", @argv );
}

sub _foundation {
  my ( $cwd, @argv ) = @_;
  return _run( $cwd, $^X, "-I$ROOT/lib", "$ROOT/bin/karr-foundation", @argv );
}

# List-form git invocation (never a shell string) that returns stdout as
# chomped lines -- the same idiom t/46-global-dir-option.t uses for its
# never-through-karr ref dump, used here so "is it ignored" / "is it tracked"
# checks don't depend on karr's own code at all.
sub _git_lines {
  my (@cmd) = @_;
  open( my $fh, '-|', @cmd ) or die "can't run @cmd: $!";
  my @lines = <$fh>;
  close $fh;
  chomp @lines;
  return @lines;
}

# True iff $token is actually runnable: a path (has a '/') that exists and is
# +x, or a bare name resolvable to an executable file somewhere on $PATH.
# Used to check the property "this line is a real command", not the wording
# of any one command -- a bare path to a non-executable file (the shape of
# the ex/setup.sh "Next:" bug) always fails this, whatever the path says.
sub _is_runnable_command {
  my ($token) = @_;
  return 0 unless defined $token && length $token;
  return( -f $token && -x _ ) if $token =~ m{/};
  for my $dir ( split /:/, $ENV{PATH} // '' ) {
    next unless length $dir;
    my $candidate = "$dir/$token";
    return 1 if -f $candidate && -x $candidate;
  }
  return 0;
}

# Recursive size+mtime signature of a file or directory, used only to prove
# the real ex/ sandbox is byte-for-byte unchanged before vs. after this test
# runs. 'MISSING' is a valid, comparable signature (the maintainer's ex/ may
# or may not have been built yet).
sub _fs_signature {
  my ($target) = @_;
  return 'MISSING' unless -e $target;
  my $p = path($target);
  return 'FILE ' . join( ' ', ( stat("$p") )[ 7, 9 ] ) if $p->is_file;

  my @entries;
  $p->visit(
    sub {
      my ( $child, undef ) = @_;
      return if $child->is_dir;
      push @entries, $child->relative($p) . ' ' . join( ' ', ( stat("$child") )[ 7, 9 ] );
    },
    { recurse => 1 }
  );
  return join( "\n", sort @entries );
}

sub _list_json {
  my ( $sandbox, $repo ) = @_;
  my $res = _karr( $sandbox, '--dir', "$sandbox/ex/$repo", 'list', '--json' );
  is( $res->{exit}, 0, "karr --dir ex/$repo list --json exits 0" ) or diag $res->{stderr};
  my $tasks = eval { decode_json( $res->{stdout} ) };
  ok( $tasks, "karr --dir ex/$repo list --json produced parseable JSON" ) or diag $res->{stdout};
  return $tasks || [];
}

# Reduce a list --json payload to the fields this file makes claims about,
# keyed by id, with timestamps stripped -- so a --reset rebuild (new
# created/updated/claimed_at stamps) can still be compared against the first
# build for everything that is supposed to come out the same.
sub _normalize {
  my ($tasks) = @_;
  my %by_id;
  for my $t (@$tasks) {
    $by_id{ $t->{id} } = {
      title        => $t->{title},
      status       => $t->{status},
      priority     => $t->{priority},
      claimed_by   => $t->{claimed_by},
      blocked      => ( $t->{blocked} ? 1 : 0 ),
      block_reason => $t->{block_reason},
      depends_on   => $t->{depends_on} || [],
      tags         => [ sort @{ $t->{tags} || [] } ],
    };
  }
  return \%by_id;
}

sub _build_sandbox {
  my $tmp = tempdir( CLEANUP => 1 );
  symlink( "$ROOT/lib", "$tmp/lib" ) or die "symlink lib: $!";
  symlink( "$ROOT/bin", "$tmp/bin" ) or die "symlink bin: $!";
  mkdir "$tmp/ex" or die "mkdir $tmp/ex: $!";
  for my $item (qw( setup.sh bin scripts README.md .gitignore )) {
    my $rc = system( 'cp', '-a', "$ROOT/ex/$item", "$tmp/ex/$item" );
    die "cp -a ex/$item into sandbox failed" if $rc;
  }
  return $tmp;
}

# What setup.sh itself claims it builds (comments in the script and the
# maintainer's own manual --reset run agree): 6 webapp cards (2 claimed under
# agent-fox, 1 blocked) and 2 docs-site cards (1 claimed under agent-fox).
# Every card is seeded in todo, none in backlog: backlog is held back since
# k306 -- never picked, never actionable -- so a sandbox seeded there hands
# the demo agents nothing (k313). See also 'a fresh sandbox has work ...'.
my %EXPECT_WEBAPP = (
  1 => {
    title => 'Fix login bug', status => 'in-progress', priority => 'high',
    claimed_by => 'agent-fox', blocked => 0, block_reason => undef,
    depends_on => [], tags => [],
  },
  2 => {
    title => 'Rate limit the API', status => 'todo', priority => 'medium',
    claimed_by => undef, blocked => 0, block_reason => undef,
    depends_on => [1], tags => [],
  },
  3 => {
    title => 'Publish release notes', status => 'review', priority => 'low',
    claimed_by => 'agent-fox', blocked => 0, block_reason => undef,
    depends_on => [], tags => [],
  },
  4 => {
    title => 'Upgrade TLS on staging', status => 'todo', priority => 'critical',
    claimed_by => undef, blocked => 1,
    block_reason => 'waiting for the certificate from ops',
    depends_on => [], tags => [],
  },
  5 => {
    title => 'Write integration tests for checkout', status => 'todo', priority => 'high',
    claimed_by => undef, blocked => 0, block_reason => undef,
    depends_on => [], tags => [],
  },
  6 => {
    title => 'Deploy the 0.6 release', status => 'todo', priority => 'low',
    claimed_by => undef, blocked => 0, block_reason => undef,
    depends_on => [], tags => ['needs:docs-site#1'],
  },
);

my %EXPECT_DOCS = (
  1 => {
    title => 'Update the installation quickstart', status => 'todo', priority => 'medium',
    claimed_by => undef, blocked => 0, block_reason => undef,
    depends_on => [], tags => [],
  },
  2 => {
    title => 'Rewrite the deployment section', status => 'in-progress', priority => 'low',
    claimed_by => 'agent-fox', blocked => 0, block_reason => undef,
    depends_on => [], tags => [],
  },
);

sub _assert_board {
  my ( $sandbox, $repo, $expect, $label ) = @_;
  my $got = _normalize( _list_json( $sandbox, $repo ) );
  is( scalar( keys %$got ), scalar( keys %$expect ), "$label: $repo has the expected card count" );
  for my $id ( sort { $a <=> $b } keys %$expect ) {
    is_deeply( $got->{$id}, $expect->{$id}, "$label: $repo #$id matches what setup.sh claims to build" );
  }
}

# ---------------------------------------------------- snapshot the real ex/
# Taken before anything in this file runs, and compared again at the very
# end. Everything between the two is confined to a File::Temp tempdir; see
# 'the real ex/ sandbox was never touched' below.
my %REAL_BEFORE = map { $_ => _fs_signature("$ROOT/ex/$_") } qw( webapp docs-site fleet-hub config.yml );
my @SOURCE_DIFF_BEFORE = _git_lines(
  'git', '-C', $ROOT, 'diff', '--stat', '--',
  'ex/setup.sh', 'ex/bin', 'ex/scripts', 'ex/README.md', 'ex/.gitignore',
);

# ============================================================== static checks
# These run directly against the real, checked-in ex/ tree -- read-only
# (bash -n / perl -c / stat / git plumbing never mutate anything), so there is
# no isolation concern here at all.

subtest 'tracked shell scripts are syntactically valid and executable' => sub {
  for my $rel (
    qw( ex/setup.sh
      ex/bin/drain-agent.sh ex/bin/failing-agent.sh ex/bin/fake-agent.sh ex/bin/lazy-agent.sh
      ex/scripts/build-docs.sh ex/scripts/publish.sh ex/scripts/smoke-test.sh )
  ) {
    my $path = "$ROOT/$rel";
    ok( -f $path, "$rel exists" ) or next;
    ok( -x $path, "$rel is executable" );
    my $rc = system( 'bash', '-n', $path );
    is( $rc, 0, "bash -n $rel" );
  }
};

subtest 'ex/scripts/write-chain.pl is syntactically valid' => sub {
  my $path = "$ROOT/ex/scripts/write-chain.pl";
  ok( -f $path, 'ex/scripts/write-chain.pl exists' );

  # Unlike the .sh scripts above, this is only ever invoked as
  # `perl write-chain.pl ...` (from setup.sh, hardcoded) -- never as
  # `./write-chain.pl` -- so it does not need the executable bit, and indeed
  # does not have it on disk. Not asserted either way here on purpose: it
  # would be testing an assumption ("every script here is +x") the codebase
  # doesn't actually hold for this file, not a real property of it.
  my $rc = system( $^X, '-c', $path );
  is( $rc, 0, 'perl -c ex/scripts/write-chain.pl' );
};

subtest 'ex/.gitignore matches exactly what is tracked vs. generated' => sub {
  # This subtest checks a source-checkout invariant (what git tracks under
  # ex/, as seen from $ROOT) -- not anything this test builds itself. Under
  # `prove -l t/` from the repo root, $ROOT IS the source checkout, so
  # `ls-files ex` lists the tracked files. Under `dzil test`, $ROOT is
  # wherever dzil happened to run prove from (a .build/<hash>/... copy),
  # which git sees as living inside the real repo but ignored by its
  # top-level .gitignore (`.build/`) -- so `ls-files ex` from there returns
  # nothing, and `check-ignore` blames the wrong rule. Detect that up front
  # by asking whether a known tracked file is visible as tracked from
  # $ROOT, and skip with a clear reason instead of failing on an environment
  # this property was never about.
  my @probe = _git_lines( 'git', '-C', $ROOT, 'ls-files', 'ex/setup.sh' );
  plan skip_all =>
    "ex/ not tracked relative to \$ROOT ($ROOT) -- source-tree invariant, only checked under `prove -l t/`"
    unless @probe && $probe[0] eq 'ex/setup.sh';

  my @tracked = sort( _git_lines( 'git', '-C', $ROOT, 'ls-files', 'ex' ) );
  is_deeply(
    \@tracked,
    [
      sort qw(
        ex/.gitignore
        ex/README.md
        ex/bin/drain-agent.sh
        ex/bin/failing-agent.sh
        ex/bin/fake-agent.sh
        ex/bin/lazy-agent.sh
        ex/scripts/build-docs.sh
        ex/scripts/publish.sh
        ex/scripts/smoke-test.sh
        ex/scripts/write-chain.pl
        ex/setup.sh
      )
    ],
    'git tracks exactly setup.sh + bin/ + scripts/ + README.md + .gitignore -- nothing generated',
  );

  for my $generated (qw( ex/webapp ex/docs-site ex/fleet-hub ex/config.yml )) {
    my @lines = _git_lines( 'git', '-C', $ROOT, 'check-ignore', '-v', $generated );
    ok( scalar(@lines), "$generated is ignored" );
    like( $lines[0], qr{ex/\.gitignore}, "...via a rule in ex/.gitignore, not some other file" ) if @lines;
  }

  for my $tracked (qw( ex/setup.sh ex/bin/fake-agent.sh ex/README.md ex/.gitignore )) {
    my @lines = _git_lines( 'git', '-C', $ROOT, 'check-ignore', '-v', $tracked );
    is( scalar(@lines), 0, "$tracked is NOT ignored (it's a tracked source file)" );
  }
};

# ============================================================ execution checks
# Everything below runs the real, unmodified ex/setup.sh -- copied into a
# fresh tempdir with lib/ and bin/ symlinked back to this checkout (see the
# STRUCTURAL WRINKLE note up top). The real ex/ is never this sandbox's cwd
# and never one of its arguments.

my $sandbox = _build_sandbox();

my $fresh = _run( $sandbox, 'bash', "$sandbox/ex/setup.sh" );
is( $fresh->{exit}, 0, 'a fresh ./setup.sh run exits 0' ) or diag $fresh->{stderr};

subtest 'a fresh run reports building all three repos and the sample cards' => sub {
  like( $fresh->{stdout}, qr/ex\/webapp: board created/,          'webapp board created' );
  like( $fresh->{stdout}, qr/ex\/webapp: sample cards created/,   'webapp sample cards created' );
  like( $fresh->{stdout}, qr/ex\/docs-site: board created/,       'docs-site board created' );
  like( $fresh->{stdout}, qr/ex\/docs-site: sample cards created/, 'docs-site sample cards created' );
  like( $fresh->{stdout}, qr/ex\/fleet-hub: board created/,       'fleet-hub board created' );
  like( $fresh->{stdout}, qr/ex\/config\.yml: written/,           'config.yml written' );
  like( $fresh->{stdout}, qr/chain written into \Q$sandbox\E\/ex\/fleet-hub/, 'chain written into the hub' );
};

for my $repo (qw( webapp docs-site fleet-hub )) {
  ok( -d "$sandbox/ex/$repo/.git", "ex/$repo is a git repo after the fresh run" );
}

_assert_board( $sandbox, 'webapp',    \%EXPECT_WEBAPP, 'fresh run' );
_assert_board( $sandbox, 'docs-site', \%EXPECT_DOCS,   'fresh run' );

subtest '.karr files match what setup.sh writes' => sub {
  my $webapp_karr = path("$sandbox/ex/webapp/.karr")->slurp_utf8;
  like( $webapp_karr, qr/^mode:\s*ticket$/m, 'webapp/.karr is ticket mode' );
  like( $webapp_karr, qr/^agent:\s*demo$/m,  'webapp/.karr names the demo agent' );

  my $docs_karr = path("$sandbox/ex/docs-site/.karr")->slurp_utf8;
  like( $docs_karr, qr/^mode:\s*drain$/m, 'docs-site/.karr is drain mode' );
  like(
    $docs_karr,
    qr{^command:\s*\Q$sandbox\E/ex/bin/drain-agent\.sh$}m,
    'docs-site/.karr points at the sandbox copy of drain-agent.sh',
  );
};

subtest 'config.yml wires both repos, the hub and the demo agent' => sub {
  my $config = path("$sandbox/ex/config.yml")->slurp_utf8;
  like( $config, qr{^\s*-\s*\Q$sandbox\E/ex/webapp$}m,    'dirs lists webapp' );
  like( $config, qr{^\s*-\s*\Q$sandbox\E/ex/docs-site$}m, 'dirs lists docs-site' );
  like( $config, qr{^hub:\s*\Q$sandbox\E/ex/fleet-hub$}m, 'hub points at fleet-hub' );
  like(
    $config,
    qr{^\s*command:\s*\Q$sandbox\E/ex/bin/fake-agent\.sh$}m,
    'the demo agent command points at the sandbox copy of fake-agent.sh',
  );
  like( $config, qr/^default_agent:\s*demo$/m, 'default_agent is demo' );
};

subtest 'the chain is actually written into fleet-hub' => sub {
  my @refs = _git_lines(
    'git', '-C', "$sandbox/ex/fleet-hub", 'for-each-ref', '--format=%(refname)', 'refs/karr-foundation',
  );
  is_deeply(
    [ sort @refs ],
    [
      sort qw(
        refs/karr-foundation/chain/meta
        refs/karr-foundation/chain/step/docs
        refs/karr-foundation/chain/step/publish
        refs/karr-foundation/chain/step/registry
        refs/karr-foundation/chain/step/smoke
      )
    ],
    'fleet-hub carries the chain meta ref and all four step refs',
  );
};

subtest 'karr-foundation --status sees both boards and the demo agent' => sub {
  my $status = _foundation( $sandbox, '--config', "$sandbox/ex/config.yml", '--status' );
  is( $status->{exit}, 0, 'karr-foundation --status exits 0' ) or diag $status->{stderr};
  like( $status->{stdout}, qr/^webapp$/m,    'lists webapp' );
  like( $status->{stdout}, qr/^docs-site$/m, 'lists docs-site' );
  like( $status->{stdout}, qr/6 tasks/,      'webapp shows 6 tasks' );
  like( $status->{stdout}, qr/2 tasks/,      'docs-site shows 2 tasks' );
  like( $status->{stdout}, qr/blocked:\s*#4/, 'webapp #4 is reported blocked' );
  like( $status->{stdout}, qr/demo\s+ok/,    'the demo agent is reported ok' );
};

# The walkthrough in ex/README.md opens with a run in which webapp's ticket-mode
# agent is handed #5 and docs-site's drain agent picks #1. Both are read here
# without driving an agent: the Picker is karr pick's own rules
# (App::karr::Role::PickRules) asked read-only, and --dry-run shows foundation's
# ticket choice while writing no state and starting nothing. A sandbox seeded
# in backlog (held back since k306) answers undef and 'TICKET none
# assignable', which is how the walkthrough silently stopped happening (k313).
subtest 'a fresh sandbox has work for pick and karr-foundation to hand out' => sub {
  my %first_pick = ( webapp => 5, 'docs-site' => 1 );
  for my $repo ( sort keys %first_pick ) {
    my $store = App::karr::BoardStore->new(
      git => App::karr::Git->new( dir => "$sandbox/ex/$repo" ),
    );
    is( App::karr::Foundation::Picker->new( store => $store )->next_ticket,
      $first_pick{$repo}, "pick's rules hand out #$first_pick{$repo} first on ex/$repo" );
  }

  my $dry = _foundation( $sandbox, '--config', "$sandbox/ex/config.yml", '--dry-run', '--verbose' );
  is( $dry->{exit}, 0, 'karr-foundation --dry-run --verbose exits 0' ) or diag $dry->{stderr};
  like( $dry->{stdout}, qr/TICKET task#5$/m, 'webapp ticket mode names #5' );
  unlike( $dry->{stdout}, qr/TICKET none assignable/, '...and never finds nothing to assign' );
};

# ---------------------------------------------------------------- idempotency
my $again = _run( $sandbox, 'bash', "$sandbox/ex/setup.sh" );
is( $again->{exit}, 0, 'a second run without --reset exits 0' ) or diag $again->{stderr};

subtest 'a second run without --reset destroys nothing and reports what exists' => sub {
  like( $again->{stdout}, qr/ex\/webapp: already exists/,    'webapp reported as already existing' );
  like( $again->{stdout}, qr/ex\/docs-site: already exists/, 'docs-site reported as already existing' );
  like( $again->{stdout}, qr/ex\/fleet-hub: already exists/, 'fleet-hub reported as already existing' );
  unlike( $again->{stdout}, qr/wiped generated state/, 'no wipe message without --reset' );
};

_assert_board( $sandbox, 'webapp',    \%EXPECT_WEBAPP, 'idempotent re-run' );
_assert_board( $sandbox, 'docs-site', \%EXPECT_DOCS,   'idempotent re-run' );

# --------------------------------------------------------------------- --reset
my $reset = _run( $sandbox, 'bash', "$sandbox/ex/setup.sh", '--reset' );
is( $reset->{exit}, 0, './setup.sh --reset exits 0' ) or diag $reset->{stderr};

subtest '--reset wipes and rebuilds the same state' => sub {
  like( $reset->{stdout}, qr/ex\/: wiped generated state/, 'reports the wipe' );
  like( $reset->{stdout}, qr/ex\/webapp: board created/,    'webapp rebuilt' );
  like( $reset->{stdout}, qr/ex\/docs-site: board created/, 'docs-site rebuilt' );
  like( $reset->{stdout}, qr/ex\/fleet-hub: board created/, 'fleet-hub rebuilt' );
};

_assert_board( $sandbox, 'webapp',    \%EXPECT_WEBAPP, '--reset rebuild' );
_assert_board( $sandbox, 'docs-site', \%EXPECT_DOCS,   '--reset rebuild' );

subtest 'the closing hint names the walkthrough and offers only real commands' => sub {
  like(
    $fresh->{stdout},
    qr{walkthrough is \Q$sandbox\E/ex/README\.md\.},
    'the walkthrough sentence names the sandbox copy of ex/README.md, in prose (not as a fake command)',
  );

  my @lines = split /\n/, $fresh->{stdout};
  my ($try_at) = grep { $lines[$_] =~ /Try:\s*$/ } 0 .. $#lines;
  ok( defined $try_at, 'stdout has a line ending "Try:" that introduces the offered commands' )
    or return;

  my @offered = grep { length } @lines[ $try_at + 1 .. $#lines ];
  ok( scalar(@offered), 'at least one command is offered under Try:' );

  for my $line (@offered) {
    my ($first_token) = $line =~ /^\s*(\S+)/;
    ok(
      _is_runnable_command($first_token),
      qq{offered line starts with something actually runnable: "$line"},
    );
  }
};

# ------------------------------------------------------- the real ex/, again
subtest 'the real ex/ sandbox was never touched' => sub {
  for my $rel (qw( webapp docs-site fleet-hub config.yml )) {
    is( _fs_signature("$ROOT/ex/$rel"), $REAL_BEFORE{$rel}, "ex/$rel is byte-for-byte unchanged" );
  }
};

subtest 'the tracked ex/ sources were only read, never modified' => sub {
  my @diff_after = _git_lines(
    'git', '-C', $ROOT, 'diff', '--stat', '--',
    'ex/setup.sh', 'ex/bin', 'ex/scripts', 'ex/README.md', 'ex/.gitignore',
  );
  is_deeply( \@diff_after, \@SOURCE_DIFF_BEFORE, 'git diff --stat over the tracked ex/ files is unchanged' );
};

done_testing;
