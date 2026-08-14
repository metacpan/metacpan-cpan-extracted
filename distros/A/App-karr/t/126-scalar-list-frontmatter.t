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

use App::karr::Git;
use App::karr::Task;

# Ticket #125: a scalar where a list belongs -- `depends_on: 1`, `tags: urgent`
# -- passed the parse gate and died only when the write dereferenced it in
# to_frontmatter:
#
#   Can't use string ("1") as an ARRAY ref while "strict refs" in use
#     at lib/App/karr/Task.pm line 335.
#
# A raw Perl message with a source location (the #77 class), and worse, it fired
# mid-import: `karr import --yes` of a hand-edited view had already run
# save_config and written every card sorted before the bad one when it died, and
# the prune never ran -- exactly the half-import serialize_from promises cannot
# happen (ticket #70). Nothing karr writes itself can carry a scalar there; a
# hand-written or third-party card in a materialized view can, and `tags` is the
# field people actually type by hand.
#
# The fix refuses the scalar at the parse gate, in Task::BUILD next to the other
# frontmatter normalisation (#58, #98), so from_file names the field and the
# file, and serialize_from's all-or-nothing gate catches it before any ref
# moves. An empty or null value is not a scalar value: per the #98 interop rule
# it is the same state as "absent" and loads as the empty list.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
  my ( $cwd, @argv ) = @_;
  my $old = getcwd();
  chdir $cwd or die "chdir $cwd: $!";

  my $stderr = gensym;
  my $pid = open3( my $in, my $out, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
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

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
}

sub _init_board {
  my ( $name, @titles ) = @_;
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', $name )->{exit}, 0, "board '$name' initialized" );
  is( _run_karr( $repo, 'create', $_ )->{exit}, 0, "created: $_" ) for @titles;
  return $repo;
}

sub _task_ids {
  my ($repo) = @_;
  return [ sort { $a <=> $b } App::karr::Git->new( dir => $repo )->list_task_refs ];
}

sub _titles {
  my ($repo) = @_;
  my $git = App::karr::Git->new( dir => $repo );
  return { map { $_ => $git->load_task_ref($_)->title } $git->list_task_refs };
}

sub card {
  my (%extra) = @_;
  my $fm = join '', map { "$_: $extra{$_}\n" } sort keys %extra;
  return "---\nid: 1\ntitle: Interop card\nstatus: backlog\n"
    . "priority: medium\nclass: standard\n"
    . "created: 2026-01-01T00:00:00Z\nupdated: 2026-01-01T00:00:00Z\n"
    . $fm . "---\n";
}

subtest 'a scalar list field is refused at the parse gate' => sub {
  for my $case ( [ tags => 'urgent' ], [ depends_on => 1 ] ) {
    my ( $field, $value ) = @$case;
    my $err = '';
    eval { App::karr::Task->from_string( card( $field => $value ) ); 1 }
      or $err = $@;
    ok( length $err, "$field: $value does not pass the parse gate" )
      or next;
    like( $err, qr/\AFrontmatter field '\Q$field\E' must be a list, not a single value\n\z/,
      "$field: the refusal names the field" );
  }
};

subtest 'a mapping is refused too' => sub {
  # `depends_on: {a: 1}` used to die as "Not an ARRAY reference" at the same
  # dereference. Same gate, same shape of message.
  for my $field (qw( tags depends_on )) {
    my $err = '';
    eval { App::karr::Task->from_string( card( $field => '{a: 1}' ) ); 1 }
      or $err = $@;
    like( $err, qr/\AFrontmatter field '\Q$field\E' must be a list\n\z/,
      "$field: a mapping is refused by field name" );
  }
};

subtest 'the refusal carries no source location' => sub {
  # The #77 rule: where karr keeps its source is never the reader's problem.
  for my $field (qw( tags depends_on )) {
    my $err = '';
    eval { App::karr::Task->from_string( card( $field => 'scalar' ) ); 1 }
      or $err = $@;
    unlike( $err, qr/ at \S+ line \d+/, "$field: no 'at ... line N'" );
    unlike( $err, qr{lib/App/karr},     "$field: no lib path" );
  }
};

subtest 'an empty or null list field loads as the empty list' => sub {
  # Present but empty is "absent" on the kanban-md side (omitempty), the same
  # interop state ticket #98 normalizes for the optional scalars. Pre-fix these
  # died in to_markdown as "Can't use an undefined value as an ARRAY ref".
  for my $spelling ( q{""}, '~' ) {
    my $task = App::karr::Task->from_string(
      card( tags => $spelling, depends_on => $spelling ) );
    is_deeply( $task->tags,       [], "tags: $spelling loads as []" );
    is_deeply( $task->depends_on, [], "depends_on: $spelling loads as []" );
    my $md = eval { $task->to_markdown };
    ok( defined $md, "and the card writes ($spelling)" ) or diag($@);
    unlike( $md, qr/^(?:tags|depends_on):/m, 'with neither key in the document' );
  }
};

subtest 'from_file names the file as well as the field' => sub {
  my $dir  = path( tempdir( CLEANUP => 1 ) );
  my $file = $dir->child('002-scalar-depends.md');
  $file->spew_utf8( card( depends_on => 1 ) );

  my $err = '';
  eval { App::karr::Task->from_file($file); 1 } or $err = $@;
  like( $err, qr/Frontmatter field 'depends_on' must be a list/,
    'the field is named' );
  like( $err, qr/\Q002-scalar-depends.md\E/, 'and so is the file' );
};

# The ticket's reproduced scenario: a view edited on every axis import touches
# -- a renamed card, a scalar depends_on, a deleted card. Pre-fix the import
# died mid-write: card 1 was rewritten, card 2 was not, card 3 was never pruned,
# and stderr was the raw Perl line with the lib path.
subtest 'a scalar list field aborts the whole import, changing nothing' => sub {
  my $repo = _init_board( 'Gate Board', 'Task one', 'Task two', 'Task three' );
  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'view materialized' );

  my $before = _titles($repo);
  my $tasks  = path($repo)->child('tasks');

  my $one = $tasks->child('001-task-one.md');
  ( my $edited = $one->slurp_utf8 ) =~ s/^title: Task one$/title: Renamed one/m;
  $one->spew_utf8($edited);

  my $two = $tasks->child('002-task-two.md');
  ( my $scalar = $two->slurp_utf8 ) =~ s/\A---\n/---\ndepends_on: 1\n/;
  $two->spew_utf8($scalar);

  $tasks->child('003-task-three.md')->remove;

  my $rv = _run_karr( $repo, 'import', '--yes' );
  isnt( $rv->{exit}, 0, 'import fails on the scalar list field' );
  like( $rv->{stderr}, qr/002-task-two\.md/, 'the offending file is named' );
  like( $rv->{stderr}, qr/Frontmatter field 'depends_on' must be a list/,
    'and so is the field' );
  like( $rv->{stderr}, qr/No refs were changed/,
    'stderr promises the board is untouched' );
  unlike( $rv->{stderr}, qr/ARRAY ref|lib\/App\/karr\/Task\.pm| at \S+ line \d+/,
    'and carries no raw Perl dereference error' );

  is_deeply( _titles($repo), $before, 'no task ref was rewritten' );
  is_deeply( _task_ids($repo), [ 1, 2, 3 ], 'and the prune never ran either' );
};

done_testing;
