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
use App::karr::Error qw( clean_error command_hint );

# Ticket k263: every error about a missing or malformed option prints the
# invocation that would have worked, built from the words the caller actually
# typed, and prints it LAST.
#
# The case that prompted it -- an agent spending four calls on one move:
#
#   karr move 79 in-progress          -> "Status 'in-progress' requires --claim"
#   karr move 79 in-progress --claim  -> "Option claim requires an argument" + usage
#   karr move --help | head -30       -> read the usage
#   karr move 79 in-progress --claim main-agent
#
# Two faults, and this file pins both closed. The wording named the option but
# not that a value follows it, which is what provoked the second call. And the
# answer, when it finally appeared, sat high up inside a 15-line usage block
# while the agent was reading through `tail -3` -- so placement is asserted as
# hard as content here. Every check below is one of:
#
#   (a) the suggestion carries the REAL id and the REAL status, never a
#       placeholder id;
#   (b) it is the last line of the error (behind, at most, the batch summary --
#       the ticket's own reproduction is `2>&1 | tail -3`);
#   (c) the exit code is exactly what it was before (ADR 0002 is untouched).
#
# Scope is the six commands an agent meets rarely: move, handoff, needs,
# import, materialize, repair. list/show/create/edit stay as they are except
# where App::karr::Role::TaskMutation pulls edit in.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3( my $in, my $out, $stderr,
        $^X, "-I$ROOT/lib", $BIN, @argv );
    close $in;
    my $stdout      = do { local $/; <$out> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";

    return {
        exit   => $exit,
        stdout => defined $stdout      ? $stdout      : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _bare_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0                                     or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0         or die 'git config';
    return $repo;
}

sub _board_repo {
    my (@titles) = @_;
    my $repo = _bare_repo();
    my $init = _run_karr( $repo, 'init', '--name', 'Hint Board' );
    is( $init->{exit}, 0, 'setup: karr init' ) or diag $init->{stderr};
    for my $title (@titles) {
        my $rv = _run_karr( $repo, 'create', $title, '--status', 'todo' );
        is( $rv->{exit}, 0, "setup: created '$title'" ) or diag $rv->{stderr};
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

# The suggestion is the last line, except that a batch command still owes its
# "N of M ids failed" summary after the per-id output. That is exactly why the
# ticket's reproduction pipes through `tail -3` rather than `tail -1`.
sub _hint_is_last {
    my ( $text, $want, $name ) = @_;
    my @lines = _lines($text);
    my $at    = $lines[-1] =~ /\A\d+ of \d+ ids failed\z/ ? -2 : -1;
    is( $lines[$at], $want, $name )
        or diag "full output was:\n$text";
    return;
}

#### The helper itself

subtest 'command_hint renders one copy-pasteable line' => sub {
    is( command_hint( 'move', 79, 'in-progress', '--claim', 'NAME' ),
        '  karr move 79 in-progress --claim NAME',
        'the words after karr, indented, no trailing newline' );

    is( command_hint( 'edit', 5, '--body', 'two words' ),
        q{  karr edit 5 --body 'two words'},
        'a token with whitespace is quoted, so the line can be pasted as it stands' );

    is( command_hint( 'edit', 5, '--body', "it's here" ),
        q{  karr edit 5 --body 'it'\\''s here'},
        'and a quote inside it closes, escapes and reopens' );

    is( command_hint( 'needs', undef, '--resolve' ), '  karr needs --resolve',
        'an undef token contributes nothing rather than the string "undef"' );
};

subtest 'clean_error keeps the suggestion, and keeps it last' => sub {
    # This is what makes the whole ticket work for `move`: every per-id failure
    # is reduced by clean_error before the batch runner prints it, and the old
    # reduction kept the first line only.
    my $msg = "Status 'in-progress' requires a claim:\n"
        . command_hint( 'move', 79, 'in-progress', '--claim', 'NAME' ) . "\n";
    is( clean_error($msg),
        "Status 'in-progress' requires a claim:\n  karr move 79 in-progress --claim NAME",
        'message and suggestion both survive' );

    my $two = "Nothing to import:\n" . command_hint('materialize') . "\n"
        . command_hint( 'delete', 'ID' ) . "\n";
    is( clean_error($two), "Nothing to import:\n  karr materialize\n  karr delete ID",
        'two suggestions keep their order' );

    # And the reduction it exists for is unchanged.
    is( clean_error("git noise\nmore noise\nyet more\n"), 'git noise',
        'backend chatter still collapses to its first line' );
    is( clean_error("boom at /some/Module.pm line 42.\n"), 'boom',
        'and a call site is still cut away' );
};

#### move -- the case from the ticket

subtest 'move into a require_claim status names the move that would have worked' => sub {
    my $repo = _board_repo('Something to move');

    my $rv = _run_karr( $repo, 'move', 1, 'in-progress' );

    is( $rv->{exit}, 1, 'exit 1, exactly as before (ADR 0002)' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr},
        qr/^Status 'in-progress' requires a claim, and KARR_CLAIM is unset:$/m,
        'the wording says a VALUE is wanted, not just that --claim exists (ADR 0005)' );
    like( $rv->{stderr}, qr/^  export KARR_CLAIM=\$\(karr agent-name\)/m,
        'and the once-per-session export is the other way named' );
    _hint_is_last( $rv->{stderr}, '  karr move 1 in-progress --claim NAME',
        'the immediate copy-paste fix is still the last line of the error' );

    # (a): the real id and the real status, not a placeholder or an example.
    unlike( $rv->{stderr}, qr/karr move ID/, 'no placeholder id in the suggestion' );
    unlike( $rv->{stderr}, qr/karr move \d+ STATUS/, 'no placeholder status either' );

    # The ticket's own reproduction, verbatim.
    my @tail3 = ( _lines( $rv->{stdout} . $rv->{stderr} ) )[ -3 .. -1 ];
    ok( ( grep { $_ eq '  karr move 1 in-progress --claim NAME' } @tail3 ),
        'and `2>&1 | tail -3` still holds it' )
        or diag join "\n", @tail3;

    # It really is the command that works.
    my $ok = _run_karr( $repo, 'move', 1, 'in-progress', '--claim', 'NAME' );
    is( $ok->{exit}, 0, 'running the suggested line succeeds' ) or diag $ok->{stderr};
};

subtest 'a second card gets its own id in the suggestion' => sub {
    my $repo = _board_repo( 'first', 'second' );

    my $rv = _run_karr( $repo, 'move', 2, 'review' );
    is( $rv->{exit}, 1, 'exit 1' ) or diag $rv->{stderr};
    _hint_is_last( $rv->{stderr}, '  karr move 2 review --claim NAME',
        'the id and the status are the ones typed, not the ones from the last test' );
};

subtest 'move usage errors keep the marker first and the suggestion last' => sub {
    my $repo = _board_repo('a card');

    # Nothing was typed that could be quoted back, so there is no suggestion:
    # `karr move ID STATUS` would only spell the "Usage:" line again in
    # placeholders, which is the generic example k263 forbids -- and the one
    # line an agent reading `tail -1` would be left holding.
    my $none = _run_karr( $repo, 'move' );
    is( $none->{exit}, 2, 'no id at all is still a usage error (2)' );
    like( $none->{stderr}, qr/\AUsage:/,
        'the marker bin/karr classifies on is still at the start of the first line' );
    unlike( $none->{stderr}, qr/^  karr /m,
        'no suggestion at all when none of it would be the caller\'s own words' )
        or diag $none->{stderr};
    is( ( _lines( $none->{stderr} ) )[-1], 'Usage: karr move ID[,ID,...] [STATUS]',
        'the Usage: line is itself the actionable line, and it is last' );

    # `karr move , todo` splits to an empty id list. The status IS known here,
    # so the suggestion quotes it back instead of printing a placeholder.
    my $comma = _run_karr( $repo, 'move', ',', 'todo' );
    is( $comma->{exit}, 2, 'an empty id list is still a usage error (2)' );
    like( $comma->{stderr}, qr/\AUsage:/, 'marker first' );
    _hint_is_last( $comma->{stderr}, '  karr move ID todo',
        'the status the caller typed survives into the suggestion' );
};

subtest 'move without a status names the card and the board vocabulary' => sub {
    my $repo = _board_repo('a card');

    my $rv = _run_karr( $repo, 'move', 1 );
    is( $rv->{exit}, 1, 'exit 1, unchanged' ) or diag $rv->{stderr};
    like( $rv->{stderr}, qr/\QNew status required (valid: backlog, todo, in-progress, review, done, archived)\E/,
        'the placeholder in the suggestion is backed by the list of real values' );
    _hint_is_last( $rv->{stderr}, '  karr move 1 STATUS', 'suggestion last' );
};

subtest '--next and --prev at the ends of the board' => sub {
    my $repo = _board_repo('a card');

    is( _run_karr( $repo, 'move', 1, 'backlog' )->{exit}, 0, 'setup: park it at the first column' );
    my $prev = _run_karr( $repo, 'move', 1, '--prev' );
    is( $prev->{exit}, 1, 'exit 1' ) or diag $prev->{stderr};
    like( $prev->{stderr}, qr/\QTask 1 is already at the first status 'backlog'\E/,
        'the card and the column it is in are named' );
    _hint_is_last( $prev->{stderr}, '  karr move 1 STATUS', 'suggestion last' );

    is( _run_karr( $repo, 'move', 1, 'archived' )->{exit}, 0, 'setup: park it at the last column' );
    my $next = _run_karr( $repo, 'move', 1, '--next' );
    is( $next->{exit}, 1, 'exit 1' ) or diag $next->{stderr};
    like( $next->{stderr}, qr/\QTask 1 is already at the last status 'archived'\E/,
        'same on the other end' );
    _hint_is_last( $next->{stderr}, '  karr move 1 STATUS', 'suggestion last' );
};

subtest 'a card in a column the board does not configure' => sub {
    my $repo = _board_repo('a card');

    # No command can produce this state, which is the point: the card was
    # written by a board with a different status list, or by kanban-md.
    my $git  = App::karr::Git->new( dir => $repo );
    my $task = $git->load_task_ref(1);
    $task->status('nowhere');
    $git->save_task_ref($task);

    my $rv = _run_karr( $repo, 'move', 1, '--next' );
    is( $rv->{exit}, 1, 'exit 1' ) or diag $rv->{stderr};
    like( $rv->{stderr},
        qr/\QTask 1 is at 'nowhere', which this board does not configure (valid: backlog, todo, in-progress, review, done, archived)\E/,
        'the card, its column and the board vocabulary are all named' );
    _hint_is_last( $rv->{stderr}, '  karr move 1 STATUS',
        'and the explicit form is the way out' );
};

subtest '--json is untouched: one-line error, no suggestion in the payload' => sub {
    my $repo = _board_repo('a card');

    my $rv = _run_karr( $repo, 'move', 1, 'in-progress', '--json' );
    is( $rv->{exit}, 1, 'exit 1' ) or diag $rv->{stderr};
    unlike( $rv->{stdout}, qr/karr move/, 'the shell line is not in the JSON' );
    like( $rv->{stdout},
        qr/\Q"error":"Status 'in-progress' requires a claim, and KARR_CLAIM is unset"\E/,
        'the error field is one line, with no dangling colon where the suggestion was cut' );
};

#### handoff

subtest 'handoff without an id carries no suggestion, having nothing to quote' => sub {
    my $repo = _board_repo('a card');

    # --claim is required on this command, so MooX::Options answers a bare
    # `karr handoff` first; the id guard is reached with the claim in hand --
    # and the id is the only thing it could have quoted back. A suggestion here
    # could only be `karr handoff ID --claim NAME`, the "Usage:" line a second
    # time in placeholders, so this guard deliberately has none.
    my $rv = _run_karr( $repo, 'handoff', '--claim', 'agent-fox' );

    is( $rv->{exit}, 2, 'a missing positional is still a usage error (2)' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/\AUsage:/, 'marker first' );
    unlike( $rv->{stderr}, qr/^  karr /m, 'and no placeholder-only suggestion' )
        or diag $rv->{stderr};
    is( ( _lines( $rv->{stderr} ) )[-1],
        'Usage: karr handoff ID --claim NAME [--note TEXT] [--block REASON] [--release]',
        'the Usage: line is the actionable line, and it is last' );
};

#### needs

subtest 'needs --board keeps the board name the caller typed' => sub {
    my $repo = _board_repo('a card');

    my $rv = _run_karr( $repo, 'needs', '--board', 'other-repo' );
    is( $rv->{exit}, 2, 'a bad option value is still a usage error (2)' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/\AUsage error: invalid --board "other-repo"/, 'marker first' );
    _hint_is_last( $rv->{stderr}, '  karr needs --board other-repo=PATH',
        'the name is salvaged and only PATH stays a placeholder' );

    # The half-typed form salvages the same name.
    my $half = _run_karr( $repo, 'needs', '--board', 'other-repo=' );
    is( $half->{exit}, 2, 'still 2' );
    _hint_is_last( $half->{stderr}, '  karr needs --board other-repo=PATH',
        'NAME= is the same mistake and gets the same answer' );

    # Nothing to salvage: the placeholder is the honest answer.
    my $empty = _run_karr( $repo, 'needs', '--board', '=/srv/x' );
    is( $empty->{exit}, 2, 'still 2' );
    _hint_is_last( $empty->{stderr}, '  karr needs --board NAME=PATH',
        'with no name typed, both halves stay placeholders' );
};

subtest 'needs for an id that is not on the board' => sub {
    my $repo = _board_repo('a card');

    my $rv = _run_karr( $repo, 'needs', 99 );
    is( $rv->{exit}, 1, 'a missing card is a runtime failure (1), unchanged' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/\QTask 99 not found on this board\E/, 'the id is named' );
    _hint_is_last( $rv->{stderr}, '  karr list --compact',
        'and the way to find the ids that do exist is the last line' );
};

#### import

subtest 'import spells out --yes instead of asking for it' => sub {
    my $repo = _board_repo('a card');

    my $rv = _run_karr( $repo, 'import' );
    is( $rv->{exit}, 1, 'a refused destructive operation is still 1' )
        or diag $rv->{stdout} . $rv->{stderr};
    _hint_is_last( $rv->{stderr}, '  karr import --yes',
        'the whole command, not "re-run with --yes"' );
};

subtest 'import with no file view offers the command that writes one' => sub {
    my $repo = _board_repo('a card');

    my $rv = _run_karr( $repo, 'import', '--yes' );
    is( $rv->{exit}, 1, 'exit 1' ) or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/\QNo materialized task view found\E/, 'says what is missing' );
    _hint_is_last( $rv->{stderr}, '  karr materialize', 'suggestion last' );
};

subtest 'an empty file view offers both intents, in order' => sub {
    my $repo = _board_repo('a card');
    path($repo)->child('tasks')->mkpath;

    my $rv = _run_karr( $repo, 'import', '--yes' );
    is( $rv->{exit}, 1, 'exit 1' ) or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/\Qthe file view is empty\E/, 'says what it found' );

    my @lines = _lines( $rv->{stderr} );
    is_deeply( [ @lines[ -2, -1 ] ], [ '  karr materialize', '  karr delete ID' ],
        'refresh the view first, delete deliberately second -- both last' )
        or diag $rv->{stderr};
};

#### materialize and repair

# Five commands raise this, four off App::karr::BoardStore/has_board_refs and
# one through App::karr::Role::BoardDiscovery/require_board. They are asserted
# together and character for character: the first pass of k263 converted only
# materialize and repair, which left the same sentence spelled two ways
# depending on which command a caller happened to type -- worse than either
# wording on its own, and invisible to a test that checks one command at a time.
subtest 'every board-less repository gets the same message, word for word' => sub {
    my @argv = (
        [ 'backup' ],
        [ 'destroy', '--yes' ],
        [ 'materialize' ],
        [ 'repair' ],
        [ 'create', 'a card' ],   # via require_board, not has_board_refs
    );

    for my $argv (@argv) {
        my $repo = _bare_repo();
        my $name = join ' ', 'karr', @$argv;
        my $rv   = _run_karr( $repo, @$argv );

        is( $rv->{exit}, 1, "$name: a missing board is a runtime failure (1), unchanged" )
            or diag $rv->{stdout} . $rv->{stderr};
        is_deeply( [ _lines( $rv->{stderr} ) ],
            [ 'No karr board found:', '  karr init' ],
            "$name: the sentence, then the command, and nothing else" )
            or diag $rv->{stderr};
    }
};

subtest 'repair dry run ends on the command that applies it' => sub {
    my $repo = _board_repo('a card');

    # A bare-date `started` that precedes the card's own `created` is what the
    # clamp pass reports; without it the dry run has nothing to offer. `created`
    # is set at construction, so the card is rebuilt rather than edited.
    App::karr::Git->new( dir => $repo )->save_task_ref(
        do {
            my $t = App::karr::Task->new(
                id      => 1,
                title   => 'a card',
                status  => 'done',
                created => '2026-07-02T10:00:00Z',
                updated => '2026-07-09T18:00:00Z',
            );
            $t->started('2026-07-02');
            $t;
        } );

    my $rv = _run_karr( $repo, 'repair' );
    is( $rv->{exit}, 0, 'a dry run still exits 0' ) or diag $rv->{stderr};
    _hint_is_last( $rv->{stdout}, '  karr repair --yes',
        'the offer is a command, and it is the last thing printed' );
};

#### Part B: where the answer stands

# The ticket's second fault, and the one that is only about placement. The
# answer was always in the output -- it just sat above a fifteen-line usage
# block, and the agent that hit it was reading through `tail -3`:
#
#   $ karr move 1 in-progress --claim
#   Option claim requires an argument            <- the answer
#   USAGE: karr move ID[,ID,...] STATUS [--claim NAME] [--next|--prev]
#       --claim=String  Claim task for an agent  <- the second answer
#       ... thirteen more lines ...
#       --man           show the manual          <- all `tail -3` saw
#
# App::karr::Role::ExitCodes buffers STDERR for the length of new_with_options
# and puts the diagnostic back AFTER the block, with the invocation that would
# have worked under it. MooX::Options' wording is untouched: it only moves, and
# gains the colon that introduces the suggestion.
#
# Both writers are covered here, because they are two different mechanisms and
# only one of them is a warning: Getopt::Long warns "Option claim requires an
# argument" (move), while a `required => 1` option that was never given fails in
# the constructor and MooX::Options reports it with a bare `print STDERR`
# (handoff). "Unknown option" is the third shape, and the one that gets the
# reordering without a suggestion.

# Everything part B asserts about one invocation. $hint is undef where no
# suggestion is expected, and the diagnostic is then the last line itself.
sub _answer_is_last {
    my ( $rv, $diagnostic, $hint, $name ) = @_;

    is( $rv->{exit}, 2, "$name: an option-parse error is still a usage error (2)" )
        or diag $rv->{stdout} . $rv->{stderr};
    is( $rv->{stdout}, '', "$name: nothing of it reaches stdout" );

    # The USAGE: line, wherever the block starts -- the root's own help writes
    # it through Term::ANSIColor, so the marker is not at the start of the line
    # there the way it is for a subcommand.
    my @lines = _lines( $rv->{stderr} );
    my ($usage_at) = grep { $lines[$_] =~ /USAGE:/ } 0 .. $#lines;
    my $wanted = defined $hint ? $diagnostic . ':' : $diagnostic;
    my ($at)   = grep { $lines[$_] eq $wanted } 0 .. $#lines;

    ok( defined $usage_at, "$name: the usage block is still printed" )
        or diag $rv->{stderr};
    ok( defined $at, "$name: MooX::Options' own wording, unchanged: '$wanted'" )
        or diag $rv->{stderr};
    return unless defined $usage_at && defined $at;

    cmp_ok( $at, '>', $usage_at, "$name: the diagnostic stands AFTER the usage block" );
    is( $lines[-1], defined $hint ? $hint : $wanted,
        "$name: and the actionable line is the last line of all" )
        or diag $rv->{stderr};
    return;
}

subtest 'a missing option value answers under the block, not over it' => sub {
    my $repo = _board_repo('a card');

    my $rv = _run_karr( $repo, 'move', 1, 'in-progress', '--claim' );
    _answer_is_last( $rv, 'Option claim requires an argument',
        '  karr move 1 in-progress --claim NAME', 'move 1 in-progress --claim' );

    # NAME is not invented here: it is the word Move's own usage_string uses
    # for that value (`[--claim NAME]`), which is the word the require_claim
    # message quotes back two subtests up. One option, one placeholder, in
    # every message about it -- and a command that renames its placeholder
    # drags this line along with it.
    like( $rv->{stderr}, qr/^USAGE: karr move .*\Q[--claim NAME]\E/m,
        'the same word the usage block itself uses' );
    like( $rv->{stderr}, qr/\Q--claim NAME\E$/m,
        'and it stands where the value was missing, not at the end of the line' );

    # The ticket's own reproduction, verbatim.
    my @tail3 = ( _lines( $rv->{stdout} . $rv->{stderr} ) )[ -3 .. -1 ];
    ok( ( grep { $_ eq '  karr move 1 in-progress --claim NAME' } @tail3 ),
        '`2>&1 | tail -3` now holds the answer instead of the -h/--help/--man lines' )
        or diag join "\n", @tail3;

    # It really is the command that works.
    is( _run_karr( $repo, 'move', 1, 'in-progress', '--claim', 'NAME' )->{exit},
        0, 'running the suggested line succeeds' );
};

subtest 'handoff with neither --claim nor KARR_CLAIM names both ways out' => sub {
    my $repo = _board_repo('a card');

    # --claim was MooX::Options `required => 1` before ADR 0005 -- a constructor
    # error saying "claim is missing". Now KARR_CLAIM fills it when the flag is
    # omitted, and a handoff with neither is karr's own usage error (still
    # exit 2), naming both ways: the once-per-session export, and the immediate
    # --claim invocation last, for the agent reading `tail -1`.
    local $ENV{KARR_CLAIM};
    delete $ENV{KARR_CLAIM};

    my $rv = _run_karr( $repo, 'handoff', 1 );

    is( $rv->{exit}, 2, 'still a usage error (2), as the old required was' )
        or diag $rv->{stdout} . $rv->{stderr};
    is( $rv->{stdout}, '', 'nothing of it reaches stdout' );
    like( $rv->{stderr}, qr/needs a claim, and KARR_CLAIM is unset/,
        'the diagnostic names the empty environment' );
    like( $rv->{stderr}, qr/^  export KARR_CLAIM=\$\(karr agent-name\)/m,
        'the once-per-session export is named' );
    is( ( _lines( $rv->{stderr} ) )[-1], '  karr handoff 1 --claim NAME',
        'and the immediate --claim invocation is the last line' )
        or diag $rv->{stderr};

    is( _run_karr( $repo, 'handoff', 1, '--claim', 'NAME' )->{exit},
        0, 'running the suggested line succeeds' );
};

subtest 'an unknown option gets the reordering and no suggestion' => sub {
    my $repo = _board_repo('a card');

    # The one k263 shape karr has no honest answer for. The other two are
    # missing a VALUE and the value is what gets filled in, so the caller's
    # intent survives whole; here the only line that would run is the caller's
    # own word deleted -- `karr move 1 todo`, a card being moved that nobody
    # asked to move, handed to an agent reading `tail -1`. So: the diagnostic
    # moves behind the block, and stops there. No suggestion, and therefore no
    # colon on it either. The names that DO exist are in the block above.
    my $rv = _run_karr( $repo, 'move', 1, 'todo', '--bogus' );
    _answer_is_last( $rv, 'Unknown option: bogus', undef, 'move 1 todo --bogus' );
    unlike( $rv->{stderr}, qr/^  karr /m, 'no command is offered in its place' )
        or diag $rv->{stderr};

    # Nothing ran: the card is still where it was.
    my $show = _run_karr( $repo, 'show', 1 );
    like( $show->{stdout}, qr/^Status:\s+todo$/m, 'and the card was not touched' );

    # The root command reaches none of this through Role::ExitCodes -- its own
    # _print_help override is what MooX::Options calls -- so it is asserted
    # separately, and answers the same way.
    # No `unlike qr/^  karr /` here: the root's help block ends in an EXAMPLES
    # list whose lines are indented invocations of exactly that shape. That the
    # diagnostic is the LAST line is the assertion that carries the meaning --
    # a suggestion would have to stand behind it.
    my $root = _run_karr( $repo, '--bogus' );
    _answer_is_last( $root, 'Unknown option: bogus', undef, 'karr --bogus' );
};

subtest 'the suggestion carries the spelling the caller typed' => sub {
    my $repo = _board_repo('a card');

    # bin/karr rewrites --claimed-by to --claimed_by before MooX::Options sees
    # it (#256), and Getopt::Long reports the underscored name back. The
    # suggestion is built from the argv bin/karr recorded BEFORE that rewrite,
    # so it shows the dashes the caller actually typed.
    # CLAIMED_BY is the other half of the placeholder rule: List's usage_string
    # does not name --claimed-by at all, so there is no word to quote and the
    # option's own name upper-cased is the fallback.
    my $rv = _run_karr( $repo, 'list', '--json', '--claimed-by' );
    _answer_is_last( $rv, 'Option claimed_by requires an argument',
        '  karr list --json --claimed-by CLAIMED_BY', 'list --json --claimed-by' );

    # And where the usage_string DOES name one, it wins even for an option
    # reached by abbreviation: List writes `[--priority LIST]`.
    my $abbrev = _run_karr( $repo, 'list', '--prio' );
    _answer_is_last( $abbrev, 'Option priority requires an argument',
        '  karr list --prio LIST', 'list --prio' );
};

subtest 'no recorded argv, no suggestion -- and the diagnostic still moves' => sub {
    my $repo = _bare_repo();

    # karr-foundation records no argv (only bin/karr does), so there is nothing
    # to quote back and the suggestion is left out rather than invented. The
    # reordering is not conditional on it: the diagnostic goes last either way.
    my $old = getcwd();
    chdir $repo or die "chdir $repo: $!";
    my $stderr = gensym;
    my $pid = open3( my $in, my $out, $stderr,
        $^X, "-I$ROOT/lib", "$ROOT/bin/karr-foundation", '--totally-bogus' );
    close $in;
    my $stdout_text = do { local $/; <$out> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;
    chdir $old or die "chdir $old: $!";

    is( $exit, 2, 'karr-foundation --totally-bogus still exits 2' ) or diag $stderr_text;
    my @lines = _lines($stderr_text);
    my ($usage_at) = grep { $lines[$_] =~ /\AUSAGE: karr-foundation / } 0 .. $#lines;
    my ($at)       = grep { $lines[$_] eq 'Unknown option: totally_bogus' } 0 .. $#lines;
    ok( defined $usage_at && defined $at, 'block and diagnostic are both there' )
        or diag $stderr_text;
    cmp_ok( $at, '>', $usage_at, 'the diagnostic still stands after the block' );
    is( $lines[-1], 'Unknown option: totally_bogus',
        'and with no suggestion to print it is itself the last line' )
        or diag $stderr_text;
    unlike( $stderr_text, qr/^  karr/m, 'nothing was guessed at' );
};

subtest 'a help request is untouched by any of it' => sub {
    my $repo = _board_repo('a card');

    # ADR 0002: -h/--help/--usage print to STDOUT and exit 0. They travel
    # through the very methods the reordering hooks, so they are pinned here
    # rather than assumed.
    for my $flag (qw( --help -h --usage )) {
        my $rv = _run_karr( $repo, 'move', $flag );
        is( $rv->{exit}, 0, "karr move $flag exits 0" ) or diag $rv->{stderr};
        is( $rv->{stderr}, '', "karr move $flag writes nothing to stderr" );
        like( $rv->{stdout}, qr/\AUSAGE: karr move /,
            "karr move $flag prints the usage on stdout" );
        unlike( $rv->{stdout}, qr/^  karr /m,
            "karr move $flag is offered no suggestion" );
    }

    my $root = _run_karr( $repo, '--help' );
    is( $root->{exit}, 0, 'karr --help exits 0' );
    is( $root->{stderr}, '', 'and writes nothing to stderr' );
};

# Ticket k263 rule two: buffering STDERR may not cost a single line of anything
# else. A warning raised while options are being parsed is still printed when
# the parse then succeeds, and a warning from a command body -- which is outside
# the buffered window entirely -- passes through untouched.
subtest 'nothing else on stderr is swallowed by the buffering' => sub {
    my $repo = _board_repo('a card');

    my $probe = tempdir( CLEANUP => 1 );
    path($probe)->child('KarrWarnProbe.pm')->spew_utf8( <<'PROBE' );
package KarrWarnProbe;
use strict;
use warnings;
use App::karr::Cmd::AgentName;

no warnings 'redefine';
my $parse = App::karr::Cmd::AgentName->can('parse_options');
*App::karr::Cmd::AgentName::parse_options = sub {
    warn "probe: raised while options were being parsed\n";
    return $parse->(@_);
};
my $execute = App::karr::Cmd::AgentName->can('execute');
*App::karr::Cmd::AgentName::execute = sub {
    warn "probe: raised from the command body\n";
    return $execute->(@_);
};
1;
PROBE

    # -I rather than PERL5LIB, which would replace the paths this perl was
    # started with rather than add to them.
    local $ENV{PERL5OPT} = "-I$probe -MKarrWarnProbe";
    my $rv = _run_karr( $repo, 'agent-name' );

    is( $rv->{exit}, 0, 'the run still succeeds' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/\A\S+\n\z/, 'and still prints one agent name' );
    is_deeply(
        [ _lines( $rv->{stderr} ) ],
        [ 'probe: raised while options were being parsed',
          'probe: raised from the command body' ],
        'both warnings arrive, unchanged and in the order they were raised' )
        or diag $rv->{stderr};
};

done_testing;
