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

# Ticket #124: depends_on could not be set from the CLI at all. Neither
# `create` nor `edit` had an option for it -- the field was reachable only
# through `karr import` of a file view or a hand edit, so after #123 karr
# warned about a relationship karr itself could not express (the #123 tests
# had to seed it through BoardStore directly).
#
#   create --depends-on 2,3            comma-separated ids, the --tags shape
#   edit   --add-depends-on 2,3        append-unique, the --add-tag shape
#   edit   --remove-depends-on 2       remove, absent ids are a no-op
#
# Set-time validation comes with it (kanban-md ValidateDependencyIDs,
# internal/task/validate.go:155), split along karr's own exit-code contract:
#
#   - a non-numeric id and an id the board does not have are wrong for every
#     id in the batch at once, so they condemn the whole invocation as a
#     usage error (exit 2) before anything is written -- on create, before
#     the id is allocated, so a rejected create burns no id (#54)
#   - a self-reference is per-id: `edit 4,5 --add-depends-on 5` is valid for
#     4 and wrong for 5, so it is a per-id failure inside the batch (#61),
#     exit 1, with the other ids still written
#
# Stored as numbers, not strings: the ids must round-trip numerically through
# the frontmatter and come out of --json as JSON numbers, the same care
# run_batch takes when it echoes ids.

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

sub _depends_on {
  my ( $repo, $id ) = @_;
  my $task = App::karr::Git->new( dir => $repo )->load_task_ref($id);
  return $task ? $task->depends_on : undef;
}

subtest 'create --depends-on sets the list' => sub {
  my $repo = _init_board( 'Create Board', 'Dep one', 'Dep two' );

  my $rv = _run_karr( $repo, 'create', 'Needs both', '--depends-on', '1,2' );
  is( $rv->{exit}, 0, 'create --depends-on succeeds' ) or diag( $rv->{stderr} );

  is_deeply( _depends_on( $repo, 3 ), [ 1, 2 ], 'the new card carries both ids' );

  # A repeated id inside one flag value carries no meaning and must not store
  # [1, 1] the way kanban-md's own unvalidated IntSlice would.
  is( _run_karr( $repo, 'create', 'Dup card', '--depends-on', '1,1' )->{exit},
    0, 'a duplicated id is accepted' );
  is_deeply( _depends_on( $repo, 4 ), [1], 'and collapsed to one entry' );
};

subtest 'the ids are numbers in the frontmatter and in --json' => sub {
  my $repo = _init_board( 'Numeric Board', 'Dep one', 'Dep two' );
  is( _run_karr( $repo, 'create', 'Needs both', '--depends-on', '1,2' )->{exit},
    0, 'card created with dependencies' );

  # The frontmatter must round-trip kanban-md's IntSlice: unquoted integers.
  # A Perl string "1" would dump as '1', which go-yaml then refuses to
  # unmarshal into an int.
  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'view materialized' );
  my $card = path($repo)->child( 'tasks', '003-needs-both.md' )->slurp_utf8;
  like( $card, qr/^depends_on:\n- 1\n- 2$/m,
    'the file view carries unquoted integers' )
    or diag("wrote:\n$card");

  # Same on the JSON side: numbers, not strings -- asserted on the raw text,
  # because a Perl-side decode cannot tell 1 from "1".
  my $json = _run_karr( $repo, 'show', '3', '--json' );
  is( $json->{exit}, 0, 'show --json succeeds' );
  like( $json->{stdout}, qr/"depends_on":\[1,2\]/,
    '--json emits the ids as JSON numbers' )
    or diag( $json->{stdout} );
};

subtest 'edit --add-depends-on appends without duplicating' => sub {
  my $repo = _init_board( 'Add Board', 'Dep one', 'Dep two', 'Dep three', 'Needs them' );

  is( _run_karr( $repo, 'edit', '4', '--add-depends-on', '1,2' )->{exit},
    0, 'first add succeeds' );
  is_deeply( _depends_on( $repo, 4 ), [ 1, 2 ], 'both ids are on the card' );

  # 2 is already there and must not double up; 3 is new and must land -- and a
  # duplicate within the flag itself (3,3) must collapse too.
  is( _run_karr( $repo, 'edit', '4', '--add-depends-on', '2,3,3' )->{exit},
    0, 'second add succeeds' );
  is_deeply( _depends_on( $repo, 4 ), [ 1, 2, 3 ],
    'both duplicates are dropped, the new id is appended once' );
};

subtest 'edit --remove-depends-on removes, absent ids are a no-op' => sub {
  my $repo = _init_board( 'Remove Board', 'Dep one', 'Dep two', 'Needs them' );
  is( _run_karr( $repo, 'edit', '3', '--add-depends-on', '1,2' )->{exit},
    0, 'dependencies added' );

  is( _run_karr( $repo, 'edit', '3', '--remove-depends-on', '1' )->{exit},
    0, 'remove succeeds' );
  is_deeply( _depends_on( $repo, 3 ), [2], 'the removed id is gone' );

  # Removing an id that is not on the card must stay a success: it is how a
  # dependency on a since-deleted task is cleaned up, which is exactly the
  # state the #123 move-time warning reports.
  my $rv = _run_karr( $repo, 'edit', '3', '--remove-depends-on', '99' );
  is( $rv->{exit}, 0, 'removing an absent id is a no-op, not an error' )
    or diag( $rv->{stderr} );
  is_deeply( _depends_on( $repo, 3 ), [2], 'and the card is unchanged' );
};

subtest 'a self-reference is a per-id failure, not a batch abort' => sub {
  my $repo = _init_board( 'Self Board', 'Dep one', 'Dep two', 'Card four', 'Card five' );

  # Valid for 3, a self-reference for 4: #61 semantics say 3 is still written,
  # the batch exits 1, and the failure names the id.
  my $rv = _run_karr( $repo, 'edit', '3,4', '--add-depends-on', '4' );
  is( $rv->{exit}, 1, 'the batch exits 1' ) or diag( $rv->{stderr} );
  like( $rv->{stderr}, qr/Task 4 cannot depend on itself/,
    'the self-reference is named' );
  like( $rv->{stderr}, qr/1 of 2 ids failed/, 'and counted' );

  is_deeply( _depends_on( $repo, 3 ), [4], 'the valid id was still written' );
  is_deeply( _depends_on( $repo, 4 ), [], 'the self-reference was not' );
};

subtest 'an unknown id condemns the whole invocation as a usage error' => sub {
  my $repo = _init_board( 'Unknown Board', 'Dep one', 'Target' );

  my $create = _run_karr( $repo, 'create', 'Never born', '--depends-on', '1,99' );
  is( $create->{exit}, 2, 'create exits 2' ) or diag( $create->{stderr} );
  like( $create->{stderr}, qr/dependency task 99 does not exist on this board/,
    'the missing id is named' );

  # The #54 rule: validation runs before the id is allocated, so the rejected
  # create burned nothing and the next create still gets id 3.
  my $next = _run_karr( $repo, 'create', 'Id three' );
  is( $next->{exit}, 0, 'the next create succeeds' );
  like( $next->{stdout}, qr/Created task 3:/,
    'and got the id the rejected create did not burn' )
    or diag( $next->{stdout} );

  my $edit = _run_karr( $repo, 'edit', '2', '--add-depends-on', '99' );
  is( $edit->{exit}, 2, 'edit exits 2' ) or diag( $edit->{stderr} );
  like( $edit->{stderr}, qr/dependency task 99 does not exist on this board/,
    'with the same message' );
  is_deeply( _depends_on( $repo, 2 ), [], 'and the card is untouched' );
};

subtest 'a non-numeric id is a usage error before anything is written' => sub {
  my $repo = _init_board( 'Format Board', 'Dep one', 'Target' );

  my $create = _run_karr( $repo, 'create', 'Never born', '--depends-on', '1,x9' );
  is( $create->{exit}, 2, 'create exits 2' ) or diag( $create->{stderr} );
  like( $create->{stderr}, qr/invalid --depends-on id "x9"/,
    'the flag and the offending value are named' );

  my $add = _run_karr( $repo, 'edit', '2', '--add-depends-on', 'abc' );
  is( $add->{exit}, 2, 'edit --add-depends-on exits 2' );
  like( $add->{stderr}, qr/invalid --add-depends-on id "abc"/,
    'the add flag is named' );

  my $remove = _run_karr( $repo, 'edit', '2', '--remove-depends-on', 'abc' );
  is( $remove->{exit}, 2, 'edit --remove-depends-on exits 2' );
  like( $remove->{stderr}, qr/invalid --remove-depends-on id "abc"/,
    'the remove flag is named' );

  is_deeply( _depends_on( $repo, 2 ), [], 'the card is untouched throughout' );
};

subtest 'a batch with an unknown dependency writes no id at all' => sub {
  # The whole point of checking before the loop (#54): the same invocation as
  # a per-id failure would have written the first id before dying on the flag.
  my $repo = _init_board( 'Batch Board', 'Dep one', 'Card two', 'Card three' );

  my $rv = _run_karr( $repo, 'edit', '2,3', '--add-depends-on', '99' );
  is( $rv->{exit}, 2, 'the invocation is condemned as a whole' );
  is_deeply( _depends_on( $repo, 2 ), [], 'the first id was not written' );
  is_deeply( _depends_on( $repo, 3 ), [], 'nor the second' );
};

done_testing;
