use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use YAML::XS qw( Dump );
use JSON::MaybeXS qw( decode_json );
use Encode qw( decode );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Dashboard;

# Ticket #220: `karr dashboard` -- a configuration-free, multi-board overview
# of every karr board found under a directory tree. This pins the five areas
# the spec called out as the minimum: a tree with boarded and board-less
# repos, the depth limit, a board with non-default status names (#67 -- status
# names are per-board configurable and nothing here may hardcode them), --json,
# and that NO_COLOR (in this rig, simply not writing to a real tty) leaves no
# escape sequences in the output. Two more are pinned alongside them because
# they were exercised manually while building the command and are cheap to
# keep: never descending into a symlinked directory (loop safety) and never
# aborting the whole scan on one unreadable directory.
#
# Always throwaway repos under File::Temp; this never touches the developer's
# real board.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub _git_repo {
  my ($dir) = @_;
  $dir->mkpath;
  system( 'git', 'init', '-q', "$dir" ) == 0        or die 'git init failed';
  system( 'git', '-C', "$dir", 'config', 'user.email', 'test@example.com' ) == 0
    or die 'git config email failed';
  system( 'git', '-C', "$dir", 'config', 'user.name', 'Test User' ) == 0
    or die 'git config name failed';
  return $dir;
}

# Git repo + an initialized karr board, ready for save_task. %opt: name,
# statuses (arrayref, to exercise #67 -- a board naming its own columns).
sub _board_repo {
  my ( $dir, %opt ) = @_;
  _git_repo($dir);
  my $git = App::karr::Git->new( dir => "$dir" );
  my %cfg = ( version => 1, board => { name => $opt{name} // 'Board' } );
  $cfg{statuses} = $opt{statuses} if $opt{statuses};
  $git->write_ref( 'refs/karr/config', Dump( \%cfg ) );
  return App::karr::BoardStore->new( git => $git );
}

sub _task {
  my ( $store, %a ) = @_;
  my $t = App::karr::Task->new(
    id     => $a{id},
    title  => $a{title} // "Task $a{id}",
    status => $a{status} // 'backlog',
    class  => 'standard',
  );
  $t->blocked( $a{blocked} ) if $a{blocked};
  $store->save_task($t);
  return $t;
}

# Runs Dashboard->new(%opt)->execute([$start], []) with STDOUT captured to a
# string, the same in-process render() pattern t/37-board-render.t uses for
# App::karr::Cmd::Board -- faster than shelling out to bin/karr, and this
# rig's STDOUT (a scalar-ref filehandle) is never a tty either way, so it
# already exercises the "no colour" path the real NO_COLOR env var exercises
# on a real terminal; setting it too keeps the assertion honest about intent.
sub _dashboard {
  my ( $start, %opt ) = @_;
  local $ENV{NO_COLOR} = 1;
  # Pin the width: _term_width consults COLUMNS first, so this makes the grid
  # deterministic instead of depending on whatever terminal `prove` ran under.
  local $ENV{COLUMNS} = delete $opt{columns} // 80;
  my $cmd = App::karr::Cmd::Dashboard->new(%opt);
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    binmode STDOUT, ':encoding(UTF-8)';    # bin/karr does this too (enable_std_utf8)
    $cmd->execute( [ "$start" ], [] );
  }
  # The capture handle carries the same :encoding(UTF-8) layer bin/karr puts
  # on STDOUT, so $buf holds octets. Decode back to characters before anyone
  # measures it: a terminal column is a character, and every bar block
  # (U+2588) is three UTF-8 bytes -- measuring the octets is what made the
  # first review read a 160-character line as 205.
  return decode( 'UTF-8', $buf );
}

# The visible width of the widest line: ANSI escapes occupy no columns, and
# trailing padding is not content -- both have to come off before measuring,
# or the assertion measures the wrong thing in both directions.
sub _max_line_width {
  my ($text) = @_;
  my $max = 0;
  for my $line ( split /\n/, $text, -1 ) {
    $line =~ s/\e\[[0-9;]*m//g;
    $line =~ s/\s+$//;
    $max = length($line) if length($line) > $max;
  }
  return $max;
}

# ---------------------------------------------------------------------------
# Fixture tree
#
#   root/
#     alpha/            -- board, 2 backlog + 1 todo (default statuses)
#     bravo/             -- plain git repo, no board
#     custom/            -- board with non-default statuses (#67):
#                            backlog,doing,shipped; 1 doing, 1 shipped (terminal)
#     nested/mid/charlie/            -- board, 0 tasks (depth 2)
#     nested/mid/deep/one/two/delta/ -- board, 1 backlog task (depth 5)
#     loop -> alpha                  -- symlink, must never be followed
#     locked/inner/                  -- board, but 'locked' is chmod 0000
# ---------------------------------------------------------------------------

my $root = path( tempdir( CLEANUP => 1 ) );

my $alpha_store = _board_repo( $root->child('alpha'), name => 'Alpha' );
_task( $alpha_store, id => 1, status => 'backlog' );
_task( $alpha_store, id => 2, status => 'backlog' );
_task( $alpha_store, id => 3, status => 'todo' );

_git_repo( $root->child('bravo') );    # no board at all

my $custom_store = _board_repo(
  $root->child('custom'),
  name     => 'Custom',
  statuses => [qw( backlog doing shipped )],    # 'shipped' is the terminal one
);
_task( $custom_store, id => 1, status => 'doing' );
_task( $custom_store, id => 2, status => 'shipped' );    # terminal: not open

my $charlie_dir = $root->child(qw( nested mid charlie ));
my $charlie_store = _board_repo( $charlie_dir, name => 'Charlie' );

my $delta_dir = $root->child(qw( nested mid deep one two delta ));
my $delta_store = _board_repo( $delta_dir, name => 'Delta' );
_task( $delta_store, id => 1, status => 'backlog' );

symlink( "$root/alpha", "$root/loop" ) or die "symlink: $!" unless $^O eq 'MSWin32';

my $locked_dir = $root->child('locked');
my $locked_inner_store = _board_repo( $locked_dir->child('inner'), name => 'Locked' );
_task( $locked_inner_store, id => 1, status => 'backlog' );
chmod 0000, "$locked_dir";

END { chmod 0755, "$locked_dir" if -d "$locked_dir" }    # tempdir cleanup needs it back

# ---------------------------------------------------------------------------

subtest 'tree with boarded and board-less repos, default depth' => sub {
  my $out = _dashboard($root);

  like $out, qr/alpha/,   'boarded repo alpha appears';
  like $out, qr/custom/,  'boarded repo custom appears';
  like $out, qr/charlie/, 'boarded repo charlie (depth 2) appears';
  unlike $out, qr/\bdelta\b/, 'delta (depth 5) is past the default depth-4 limit';

  like $out, qr/No board:.*bravo/, 'board-less bravo is named in the dimmed summary line';
  unlike $out, qr/^bravo\s/m, 'bravo is not rendered as a board entry';

  # 'loop' is a symlink to alpha's own board directory. It must not surface
  # anywhere -- not as its own grid entry, and not in the no-board summary --
  # because a symlinked directory is never descended into or inspected at all.
  unlike $out, qr/^loop\s/m,            'loop is not a board entry';
  unlike $out, qr/No board:.*\bloop\b/, 'loop is not in the no-board summary either';

  # chmod 0000 on $locked_dir keeps 'inner' unreachable for a normal user, but
  # root ignores directory permission bits entirely (CI's dzil test runs as
  # root inside the perl:<ver> container), so under root 'inner' IS found and
  # this assertion would fail on an environment difference, not a real bug.
  SKIP: {
    skip 'root bypasses directory permission bits, so inner is reachable', 1
      if $> == 0;

    unlike $out, qr/\binner\b/, 'a repo under an unreadable parent directory is never found';
  }
};

subtest 'depth limiting: --depth widened finds delta, narrowed drops charlie' => sub {
  my $wide = _dashboard( $root, depth => 6 );
  like $wide, qr/\bdelta\b/, '--depth 6 reaches delta (5 levels down)';

  my $narrow = _dashboard( $root, depth => 1 );
  unlike $narrow, qr/\bcharlie\b/, '--depth 1 does not reach charlie (2 levels down)';
  like $narrow, qr/\balpha\b/, '--depth 1 still finds alpha (1 level down)';
};

subtest 'board with non-default status names (#67): nothing hardcoded' => sub {
  my $out = _dashboard( $root, hide_no_board => 1 );

  # 'doing' is open, 'shipped' is this board's own terminal status and must
  # not count -- neither hardcoded name ('todo'/'done') exists on this board
  # at all, so any hardcoding would either crash or silently show 0 open.
  like $out, qr/custom.*\(1\)/, 'custom board shows exactly 1 open task (doing), not 2';
};

subtest '--json' => sub {
  my $cmd = App::karr::Cmd::Dashboard->new( json => 1 );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    binmode STDOUT, ':encoding(UTF-8)';    # bin/karr does this too (enable_std_utf8)
    $cmd->execute( [ "$root" ], [] );
  }
  my $doc = decode_json($buf);

  is $doc->{root}, "$root", 'root echoed back';
  # At the default depth (4), delta (5 levels down) and the repo behind the
  # unreadable 'locked' directory are both out of reach -- see the discovery
  # subtest above -- so only alpha, bravo, custom and charlie are found, and
  # of those only bravo has no board.
  # As above: root ignores the chmod 0000 on 'locked', so the 'inner' board
  # (1 backlog task) is found too, shifting these three counts by exactly one
  # repo/board/open task. Same environment difference, not a real bug.
  SKIP: {
    skip 'root bypasses directory permission bits, so inner inflates these counts', 3
      if $> == 0;

    is $doc->{summary}{repos},  4, 'summary counts all 4 repos found at this depth';
    is $doc->{summary}{boards}, 3, 'summary counts 3 of them as boarded (alpha, custom, charlie)';
    is $doc->{summary}{open},   4, 'summary open total: 3 (alpha) + 1 (custom) + 0 (charlie)';
  }

  my ($alpha) = grep { $_->{name} eq 'alpha' } @{ $doc->{boards} };
  ok $alpha, 'alpha present in boards[]';
  is $alpha->{open}, 3, 'alpha: 3 open tasks';
  is $alpha->{statuses}{backlog}, 2, 'alpha: 2 backlog';
  is $alpha->{statuses}{todo}, 1, 'alpha: 1 todo';

  my ($custom) = grep { $_->{name} eq 'custom' } @{ $doc->{boards} };
  ok $custom, 'custom present';
  is $custom->{open}, 1, 'custom: terminal "shipped" task excluded from open count';
  is $custom->{statuses}{doing}, 1, 'custom: doing count present under its own name';
  ok !exists $custom->{statuses}{shipped}, 'terminal status is not even listed in statuses{}';

  my @no_board_names = map { path($_)->basename } @{ $doc->{no_board} };
  ok( ( grep { $_ eq 'bravo' } @no_board_names ), 'bravo listed in no_board' );
};

subtest '--compact' => sub {
  my $cmd = App::karr::Cmd::Dashboard->new( compact => 1 );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    binmode STDOUT, ':encoding(UTF-8)';    # bin/karr does this too (enable_std_utf8)
    $cmd->execute( [ "$root" ], [] );
  }
  like $buf, qr/^alpha\t.*backlog:2.*todo:1.*blocked:0/m, 'alpha compact line has status:count tokens';
  like $buf, qr/^bravo\tno-board$/m, 'bravo compact line says no-board';
};

subtest 'blocked task stays visible in the counts' => sub {
  my $blocked_store = _board_repo( $root->child('echo'), name => 'Echo' );
  _task( $blocked_store, id => 1, status => 'backlog', blocked => 'waiting' );
  _task( $blocked_store, id => 2, status => 'backlog' );

  my $cmd = App::karr::Cmd::Dashboard->new( json => 1, hide_no_board => 1 );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    binmode STDOUT, ':encoding(UTF-8)';    # bin/karr does this too (enable_std_utf8)
    $cmd->execute( [ "$root" ], [] );
  }
  my $doc = decode_json($buf);
  my ($echo) = grep { $_->{name} eq 'echo' } @{ $doc->{boards} };
  is $echo->{blocked}, 1, 'echo: exactly one blocked task counted';
  is $echo->{open}, 2, 'echo: blocked task still counts toward open total';
  # A blocked task is excluded from its own status bucket (it renders in its
  # own bar segment instead -- see App::karr::Cmd::Dashboard/_bar_segments),
  # so 'backlog' only carries the non-blocked one.
  is $echo->{statuses}{backlog}, 1, 'echo: blocked task not double-counted under backlog';
};

subtest 'NO_COLOR: no escape sequences in default rendering' => sub {
  my $out = _dashboard($root);
  unlike $out, qr/\e\[/, 'no ANSI escape sequences anywhere in the output';
};

subtest '--hide-no-board omits the summary line and the JSON key' => sub {
  my $out = _dashboard( $root, hide_no_board => 1 );
  unlike $out, qr/No board:/, 'no-board summary line is gone from the default view';

  my $cmd = App::karr::Cmd::Dashboard->new( json => 1, hide_no_board => 1 );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>', \$buf or die $!;
    binmode STDOUT, ':encoding(UTF-8)';    # bin/karr does this too (enable_std_utf8)
    $cmd->execute( [ "$root" ], [] );
  }
  my $doc = decode_json($buf);
  ok !exists $doc->{no_board}, 'no_board key omitted entirely under --hide-no-board';
};

subtest 'usage errors: bad start path and negative depth' => sub {
  my $cmd = App::karr::Cmd::Dashboard->new;
  eval { $cmd->execute( [ "$root/does-not-exist" ], [] ) };
  like $@, qr/Usage error:.*not a directory/, 'non-existent start path is a usage error';

  my $cmd2 = App::karr::Cmd::Dashboard->new( depth => -1 );
  eval { $cmd2->execute( [ "$root" ], [] ) };
  like $@, qr/Usage error:.*--depth must be 0 or greater/, 'negative --depth is a usage error';
};

# ---------------------------------------------------------------------------
# Layout invariants (review of #220). Two escapes got through the first round
# because nothing measured the output:
#
#   1. a cell can be wider than the terminal (a long repo name on a narrow
#      terminal), and a one-column grid cannot shrink below its own content --
#      so the content has to be capped, or the row soft-wraps and the column
#      alignment the command exists for falls apart;
#   2. the board-less repositories were joined into ONE line -- 837 characters
#      for 46 repos on a real tree -- which soft-wrapped over seven terminal
#      lines and buried the summary underneath it.
#
# The grid capacity arithmetic itself was never wrong; the 205-character line
# in the review was measured in BYTES, and every bar block (U+2588) is three
# UTF-8 bytes. _max_line_width above measures characters, which is what a
# terminal column actually is.
# ---------------------------------------------------------------------------

my $wide_root = path( tempdir( CLEANUP => 1 ) );
for my $i ( 1 .. 12 ) {
  my $st = _board_repo(
    $wide_root->child( sprintf 'board-%02d-with-a-longish-name', $i ),
    name => "Board $i",
  );
  _task( $st, id => $_, status => 'backlog' ) for 1 .. ( $i % 5 ) + 1;
}
_git_repo( $wide_root->child( sprintf 'plain-repo-%02d-longish', $_ ) ) for 1 .. 20;

subtest 'no rendered line ever exceeds the terminal width' => sub {
  # 80/120/200 are the widths named in the review; 40 and 24 are narrow enough
  # that a single cell no longer fits and the name/bar caps have to engage.
  for my $w ( 24, 40, 80, 120, 200 ) {
    for my $mode ( [], [ show_no_board  => 1 ],
                       [ hide_no_board  => 1 ] ) {
      my %opt = ( @$mode, columns => $w );
      my $label = @$mode ? "--$mode->[0]" : 'default';
      $label =~ tr/_/-/;
      my $out = _dashboard( $wide_root, %opt );
      my $got = _max_line_width($out);
      ok $got <= $w, "COLUMNS=$w ($label): widest line is $got, within $w"
        or diag "offending output:\n$out";
    }
  }
};

subtest 'the grid really is multi-column at these widths' => sub {
  # Guards the assertion above from passing vacuously: a one-entry-per-line
  # list would satisfy "nothing too wide" while losing the whole point.
  for my $w ( 120, 200 ) {
    my $out = _dashboard( $wide_root, columns => $w, hide_no_board => 1 );
    my ($grid_line) = grep { /board-\d\d/ } split /\n/, $out;
    my $entries = () = $grid_line =~ /board-\d\d/g;
    cmp_ok $entries, '>', 1, "COLUMNS=$w: a grid row carries $entries entries side by side";
  }
};

subtest 'many board-less repos: collapsed by default, wrapped on request' => sub {
  my $out = _dashboard( $wide_root, columns => 80 );
  like $out, qr/^No board: 20 repos \(--show-no-board to list them\)$/m,
    'default collapses a too-long list to a count plus the flag that expands it';
  unlike $out, qr/plain-repo-01/, '...and names no repository on that line';
  like $out, qr/^\d+ repos  \d+ boards  \d+ open$/m,
    'the summary line is still there and still readable underneath it';

  my $shown = _dashboard( $wide_root, columns => 80, show_no_board => 1 );
  like $shown, qr/plain-repo-01/, '--show-no-board lists the names';
  like $shown, qr/plain-repo-20/, '...including the last one';
  my @nb = grep { /^No board: |^ {10}plain-repo/ } split /\n/, $shown;
  cmp_ok scalar @nb, '>', 1, '...wrapped over several lines rather than one long one';
  like $nb[1], qr/^ {10}\S/, '...with continuation lines indented under the prefix';
};

subtest 'a single over-wide entry is truncated, not allowed to overhang' => sub {
  my $narrow_root = path( tempdir( CLEANUP => 1 ) );
  my $st = _board_repo(
    $narrow_root->child( 'a-really-quite-excessively-long-repository-name-here' ),
    name => 'Long',
  );
  _task( $st, id => $_, status => 'backlog' ) for 1 .. 3;

  my $out = _dashboard( $narrow_root, columns => 30, hide_no_board => 1 );
  cmp_ok _max_line_width($out), '<=', 30, 'the over-wide entry is brought inside the width';
  like $out, qr/\.\./, '...and the cut is marked, so it cannot read as a real shorter name';
};

done_testing;
