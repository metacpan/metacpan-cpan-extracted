# ABSTRACT: Kanban Assignment & Responsibility Registry

package App::karr;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options;
use Term::ANSIColor qw( colored );
# Loaded without importing: this is a command class and runs no namespace::clean
# (MooX::Options forbids it), so `use ... qw( command_hint )` would compose
# command_hint as a method on the root. Called fully qualified below instead.
use App::karr::Error ();
use App::karr::Role::BoardAccess;
use App::karr::Role::Color;
use App::karr::Cmd::Board;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Color';


# The --dir option is provided by App::karr::Role::BoardDiscovery (composed via
# BoardAccess), so it is a single, shared declaration usable both here on the
# root (`karr --dir PATH CMD`) and on every subcommand (`karr CMD --dir PATH`).

# Forwarded to the default board view so bare `karr --done` behaves like
# `karr board --done`.
option done => (
  is => 'ro',
  doc => 'Include the board\'s final column in the default board view',
);

# The --no-color option is provided by App::karr::Role::Color (composed
# above), so it is a single, shared declaration usable both here on the root
# (`karr --no-color CMD`) and on the two renderers that colour their output
# (`karr board --no-color`, `karr dashboard --no-color`).

option version => (
  is  => 'ro',
  doc => 'Print the karr version and exit',
);

# MooX::Cmd derives a command name from the class basename, so
# App::karr::Cmd::SetRefs is only ever spelled "setrefs" -- the documented
# dashed forms need registering as extra keys in the command table.
#
# Registering them here rather than rewriting $ARGV[0] in bin/karr is what makes
# them reachable with a root option in front (ticket #71): MooX::Cmd looks the
# command up with a first_index over this very table across the WHOLE argv, so
# `karr --dir PATH get-refs REF` leaves the alias at index 2, where the old
# position-0-only rewrite never saw it. Leaving argv untouched also keeps a
# payload that merely spells an alias intact -- `karr set-refs REF set-refs`
# stores "set-refs", it does not store "setrefs" -- because only the token
# MooX::Cmd itself dispatches on is ever consulted.
my %COMMAND_ALIASES = (
  'set-refs'   => 'setrefs',
  'get-refs'   => 'getrefs',
  'agent-name' => 'agentname',
  'view'       => 'show',
);

around _build_command_commands => sub {
  my ($orig, $self, @args) = @_;
  my $commands = $orig->($self, @args);
  for my $alias (keys %COMMAND_ALIASES) {
    my $name = $COMMAND_ALIASES{$alias};
    $commands->{$alias} = $commands->{$name} if $commands->{$name};
  }
  return $commands;
};

my @COMMANDS = (
  [ init      => 'Initialize a new karr board' ],
  [ create    => 'Create a new task' ],
  [ list      => 'List and filter tasks' ],
  [ show      => 'Show full task details' ],
  [ board     => 'Show board summary' ],
  [ dashboard => 'Multi-board overview of boards under a directory' ],
  [ move      => 'Change task status' ],
  [ edit      => 'Modify task fields' ],
  [ delete    => 'Delete a task' ],
  [ pick      => 'Claim the next available task' ],
  [ unlock    => 'Show or break pick locks' ],
  [ archive   => 'Archive a task (soft-delete)' ],
  [ handoff   => 'Hand off a task for review' ],
  [ needs     => 'Report or resolve cross-board dependencies' ],
  [ destroy   => 'Delete the entire refs/karr/* board' ],
  [ config    => 'View or modify board config' ],
  [ disable   => 'Disable automated agent runs on this board' ],
  [ enable    => 'Re-enable automated agent runs on this board' ],
  [ context   => 'Generate board context summary' ],
  [ log       => 'Show activity log' ],
  [ metrics   => 'Show flow metrics' ],
  [ backup    => 'Export refs/karr/* as YAML' ],
  [ restore   => 'Replace refs/karr/* from YAML' ],
  [ materialize => 'Write refs/karr/* out as a tasks/ file view' ],
  [ import    => 'Import a tasks/ file view into refs/karr/*' ],
  [ repair    => 'Migrate a 0.402-or-earlier board off double-encoded UTF-8' ],
  [ sync      => 'Sync board with remote' ],
  [ 'agent-name' => 'Print the claim name for this checkout' ],
  [ skill     => 'Install/update agent skills' ],
  [ 'set-refs' => 'Store helper payloads in a Git ref' ],
  [ 'get-refs' => 'Fetch and print helper payloads from a Git ref' ],
  [ completion => 'Generate shell completion scripts' ],
);

# The command table `karr completion` generates from: every command with its
# description, aliases included. Completion needs the same table help prints,
# so it is exposed here rather than re-derived in the command.
sub command_table {
  my %desc = map { $_->[0] => $_->[1] } @COMMANDS;
  my @out  = @COMMANDS;
  for my $alias (keys %COMMAND_ALIASES) {
    push @out, [ $COMMAND_ALIASES{$alias}, $desc{$alias} ];
  }
  return @out;
}


sub _print_help {
  my ($self_or_class, $code) = @_;
  $code //= 0;

  my $out = '';
  $out .= colored("karr", 'bold') . " - Kanban Assignment & Responsibility Registry\n\n";
  $out .= colored("USAGE:", 'bold') . " karr [--dir PATH] <command> [options]\n\n";
  $out .= colored("COMMANDS:", 'bold') . "\n";

  my $max = 0;
  for (@COMMANDS) { $max = length($_->[0]) if length($_->[0]) > $max }

  # Pad on the VISIBLE width, then colour. sprintf's %-*s counts the ANSI
  # escapes colored() wraps around the name, and those alone already exceed
  # $max, so a "%-*s" over the coloured string never pads at all and the
  # descriptions come out ragged. Padding by hand off the bare command name
  # is correct whether or not colored() actually emits escapes (it returns
  # the text untouched under NO_COLOR/ANSI_COLORS_DISABLED).
  for my $cmd (@COMMANDS) {
    $out .= sprintf "  %s%s  %s\n",
      colored($cmd->[0], 'cyan'),
      ' ' x ($max - length $cmd->[0]),
      $cmd->[1];
  }

  $out .= "\n" . colored("OPTIONS:", 'bold') . "\n";
  $out .= "  --dir PATH   Starting path for Git repository discovery\n";
  $out .= "  --done       Bare karr: include the board's final column (karr board --done)\n";
  $out .= "  --no-color   Disable colour output for this invocation\n";
  $out .= "  --version    Print the karr version and exit\n";
  $out .= "  --json       JSON output (most commands)\n";
  # Named in full rather than "(list, board)": --compact is declared by
  # App::karr::Role::CompactOutput, which exactly these nine commands compose,
  # and anywhere else it is an unknown option that exits 2 (#254). The old
  # parenthesis named two of them and read like a shortened list.
  $out .= "  --compact    Compact output (board, config, context, dashboard,\n";
  $out .= "               list, log, metrics, pick, show)\n";
  $out .= "\n" . colored("EXAMPLES:", 'bold') . "\n";
  $out .= "  karr init --name \"My Project\"\n";
  $out .= "  karr create --title \"Fix login bug\" --priority high\n";
  $out .= "  karr list --status todo,in-progress\n";
  $out .= "  karr move 1 in-progress --claim agent-fox\n";
  $out .= "  karr pick --claim agent-fox --move in-progress\n";
  $out .= "  karr backup > karr-backup.yml\n";
  $out .= "  karr restore --yes < karr-backup.yml\n";
  $out .= "  karr set-refs superpowers/spec/1234.md draft ready\n";
  $out .= "  karr board\n";
  $out .= "\nRun " . colored("karr <command> --help", 'bold') . " for command-specific options.\n";

  # Exit-code contract (ADR 0002): a positive code here is a usage/option-parse
  # error from MooX::Options (unknown option, bad value on the root command), so
  # normalize it to 2. Help requests (-h/--help) arrive with code 0 -> exit 0.
  # A negative code means "print, do not exit" and is left untouched.
  $code = 2 if $code > 0;

  # The root reaches this instead of App::karr::Role::ExitCodes' options_usage
  # wrapper (the `around` below hands it $code and never calls $orig), so the
  # reordering of ticket k263 is asked for here by name: the diagnostic
  # MooX::Options already wrote is buffered, and this puts it back AFTER the
  # block above with the invocation that would have worked under it, then exits.
  # It returns 0 when there is nothing to move -- a help request, or a call
  # that did not come out of option parsing at all -- and has then printed
  # whatever was buffered unchanged, which is what the two lines below expect.
  $self_or_class->_usage_error_last( $out, $code );

  if ($code > 0) { warn $out } else { print $out }
  exit $code if $code >= 0;
}

around options_usage      => sub { $_[1]->_print_help($_[2]) };
around options_help       => sub { $_[1]->_print_help($_[2]) };
around options_short_usage => sub { $_[1]->_print_help($_[2]) };

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  # `karr --version` answers before anything else: no board, no repository,
  # no subcommand is needed for it.
  if ($self->version) {
    print "karr $VERSION\n";
    exit 0;
  }

  # A leftover positional here means MooX::Cmd could not dispatch it to any
  # App::karr::Cmd::* subcommand: it is an unknown command, not a request for
  # the default board view. MooX::Cmd echoes already-parsed option flags AND
  # the values they consumed (e.g. `--done`, or `--dir PATH` in space form)
  # back into $args_ref, so run the leftover argv through the option-aware
  # positional_args extractor rather than a raw non-dash grep -- otherwise a
  # space-form option value such as the `--dir PATH` path is misread as an
  # unknown bare command. Bare `karr` and `karr --done` legitimately fall
  # through to the board summary below.
  my ($unknown) = $self->positional_args($args_ref);
  if (defined $unknown) {
    # The way out was prose ("Run 'karr --help' ...") where it could be a line to
    # copy (ticket k264). The "Unknown command:" marker MUST stay at the start of
    # the first line -- App::karr::Error::is_usage_error and bin/karr classify the
    # exit code on it (ADR 0002, exit 2) -- so the hint goes on the line after it,
    # last, the way every k263 suggestion does. `--help` is a real token, not a
    # placeholder, so the line is printed rather than withheld.
    die "Unknown command: $unknown\n" . App::karr::Error::command_hint('--help') . "\n";
  }

  # Default action: show board summary. The default Board is constructed
  # directly (not dispatched by MooX::Cmd), so it has no command_chain to adopt
  # --dir from; forward the root's own --dir explicitly so bare
  # `karr --dir PATH` targets PATH rather than silently falling back to cwd.
  #
  # Board's own errors reach the CLI unchanged. This used to run in an eval that
  # rewrote anything matching /No karr board found/ into that same sentence --
  # a no-op while the sentence was all there was to say, and a downgrade the
  # moment it was not: bare `karr` in a fresh clone must say that refs/karr/*
  # are merely unfetched and name 'karr sync', which is precisely the wording
  # that rewrite would have thrown away (#135).
  my %board_args = (
    done      => $self->done,
  );
  $board_args{dir} = $self->dir if $self->has_dir;
  # The default Board is constructed directly (no command_chain to adopt
  # --no-color from), so forward the root's own decision explicitly.
  $board_args{color} = 0 if defined $self->color && !$self->color;
  App::karr::Cmd::Board->new(%board_args)->execute($args_ref, $chain_ref);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr - Kanban Assignment & Responsibility Registry

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr init --name "My Project"
    karr create "Fix login bug" --priority high
    karr list --status todo,in-progress
    karr board
    karr set-refs superpowers/spec/1234.md draft ready
    karr get-refs superpowers/spec/1234.md

=head1 DESCRIPTION

L<App::karr> is the central module behind the L<karr> command line client. The
distribution manages a Git-native kanban board stored in C<refs/karr/*>, where
task cards are Markdown payloads and board configuration is sparse YAML kept in
refs rather than in checked-in work tree files.

The distribution is intended for repositories that want Git to remain the
transport and source of truth. Ordinary commands read and write task cards
directly against refs through L<App::karr::BoardStore>; no board file is ever
written to the work tree for the lifetime of a command. C<karr materialize>
and C<karr import> are the two dedicated bridge commands that write and read
a disposable, gitignored F<tasks/> plus F<config.yml> view instead, for
kanban-md interop and for grepping the board as files. This keeps the
repository free of ordinary file-level merge conflicts for shared task
state.

This module gives the architectural overview. If you want day-to-day command
usage, command groups, and command-by-command navigation, start with L<karr>.

=head1 ARCHITECTURE

=over 4

=item * C<refs/karr/config>

Sparse board configuration overrides layered onto code defaults from
L<App::karr::Config>.

=item * C<refs/karr/meta/next-id>

Dedicated metadata ref for numeric id allocation.

=item * C<refs/karr/tasks/*/data>

Task payloads stored in the same Markdown plus YAML frontmatter shape used by
L<App::karr::Task>.

=item * C<refs/karr/log/*>

Append-style activity log entries written as per-agent JSON lines.

=back

L<App::karr::Git> provides the low-level Git ref operations, while
L<App::karr::BoardStore> handles the higher-level board model: merged config,
task loading, materialization, serialization, snapshots, and restore.

=head1 CLI ENTRY POINT

The installed executable is L<karr>. Running C<karr> without a subcommand shows
the board summary by default, and the command-specific modules under
C<App::karr::Cmd::*> implement the individual operations.

Use L<karr> when you want to learn:

=over 4

=item * which command to run for a task

=item * how backup, restore, destroy, and helper refs fit together

=item * which module implements each subcommand

=item * how to use the Docker-wrapped CLI day to day

=back

=head1 DOCKER RUNTIME

Perl installation remains the normal development path, but Docker is a
first-class runtime option for vendoring C<karr> into other repositories or
tooling environments.

The default C<raudssus/karr:latest> image starts as root only long enough to
inspect the mounted F</work> directory and then drops to the matching numeric
uid and gid before running C<karr>. This prevents root-owned project files when
the image is used through a shell alias. The companion C<raudssus/karr:user>
image is the fixed-user variant for environments that prefer a predictable
non-root runtime without that auto-adjustment.

See L<karr> and F<README.md> for the shell alias form and operator-focused
examples.

=head1 PROGRAMMATIC USAGE

Although the distribution is centered on the CLI, the lower-level modules are
usable from Perl when you want to inspect or manipulate board refs directly.

Reading the current board state:

    use App::karr::Git;
    use App::karr::BoardStore;

    my $git = App::karr::Git->new(dir => '.');
    my $store = App::karr::BoardStore->new(git => $git);

    my $config = $store->load_config;
    my @tasks  = $store->load_tasks;

Creating a task and writing it back:

    use App::karr::Task;

    my $id = $store->allocate_next_id;
    my $task = App::karr::Task->new(
      id       => $id,
      title    => 'Document the release process',
      status   => 'backlog',
      priority => 'high',
    );

    $store->save_task($task);
    $git->push;

Taking a full board snapshot for export logic:

    my $snapshot = $store->snapshot;

These modules are more appropriate for Perl automation than instantiating
L<App::karr> itself, which mainly exists as the MooX::Cmd dispatcher for the
CLI.

=head1 BOARD DISCOVERY

Most commands automatically search upward from the current directory for a Git
repository that contains C<refs/karr/*>. The C<--dir> option overrides the
starting directory used for that repository discovery and is accepted in either
position: before the subcommand (C<karr --dir PATH list>) or on the subcommand
itself (C<karr list --dir PATH>). Both forms behave identically. The upward walk
still applies from the given path, so C<--dir> names any directory inside the
target repository, not necessarily its root. If no Git repository is found from
the given path, the command fails loudly rather than falling back to the current
directory.

Two commands are the exception and B<refuse> C<--dir> in both positions, each
exiting C<2>: C<dashboard> and C<skill>. Both are board-less, and neither one's
target is the result of an upward search -- see
L<App::karr::Cmd::Dashboard> and L<App::karr::Cmd::Skill> for the details.

=head1 DEFAULT BEHAVIOUR

Running C<karr> without a subcommand shows the board summary, which makes the
tool convenient as a quick project status command.

=head1 SEE ALSO

L<karr>, L<App::karr::Git>, L<App::karr::BoardStore>, L<App::karr::Task>,
L<App::karr::Config>, L<App::karr::Cmd::Init>, L<App::karr::Cmd::Skill>

=head2 command_table

    my @rows = App::karr->command_table;

The full command list as two-element arrayrefs of name and description --
the same C<@COMMANDS> data C<_print_help> renders for C<karr --help>, plus
one extra row per entry in the internal alias table (C<set-refs>,
C<get-refs>, C<agent-name>, C<view>) under the spelling MooX::Cmd actually
dispatches commands on. Exposed here so L<App::karr::Cmd::Completion> can
read the same table rather than keeping its own copy, when generating the
static bash/zsh/fish completion scripts.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
