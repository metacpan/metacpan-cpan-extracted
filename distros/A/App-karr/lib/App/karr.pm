# ABSTRACT: Kanban Assignment & Responsibility Registry

package App::karr;
our $VERSION = '0.102';
use Moo;
use MooX::Cmd;
use MooX::Options;
use Term::ANSIColor qw( colored );
use App::karr::Role::BoardAccess;

with 'App::karr::Role::BoardAccess';


option dir => (
  is => 'ro',
  format => 's',
  doc => 'Path used as the starting point for Git repository discovery',
  predicate => 1,
);

my @COMMANDS = (
  [ init      => 'Initialize a new karr board' ],
  [ create    => 'Create a new task' ],
  [ list      => 'List and filter tasks' ],
  [ show      => 'Show full task details' ],
  [ board     => 'Show board summary' ],
  [ move      => 'Change task status' ],
  [ edit      => 'Modify task fields' ],
  [ delete    => 'Delete a task' ],
  [ pick      => 'Claim the next available task' ],
  [ archive   => 'Archive a task (soft-delete)' ],
  [ handoff   => 'Hand off a task for review' ],
  [ destroy   => 'Delete the entire refs/karr/* board' ],
  [ config    => 'View or modify board config' ],
  [ context   => 'Generate board context summary' ],
  [ backup    => 'Export refs/karr/* as YAML' ],
  [ restore   => 'Replace refs/karr/* from YAML' ],
  [ sync      => 'Sync board with remote' ],
  [ agentname => 'Generate a random agent name' ],
  [ skill     => 'Install/update agent skills' ],
  [ 'set-refs' => 'Store helper payloads in a Git ref' ],
  [ 'get-refs' => 'Fetch and print helper payloads from a Git ref' ],
);

sub _print_help {
  my ($self_or_class, $code) = @_;
  $code //= 0;

  my $out = '';
  $out .= colored("karr", 'bold') . " - Kanban Assignment & Responsibility Registry\n\n";
  $out .= colored("USAGE:", 'bold') . " karr [--dir PATH] <command> [options]\n\n";
  $out .= colored("COMMANDS:", 'bold') . "\n";

  my $max = 0;
  for (@COMMANDS) { $max = length($_->[0]) if length($_->[0]) > $max }

  for my $cmd (@COMMANDS) {
    $out .= sprintf "  %-*s  %s\n", $max, colored($cmd->[0], 'cyan'), $cmd->[1];
  }

  $out .= "\n" . colored("OPTIONS:", 'bold') . "\n";
  $out .= "  --dir PATH   Starting path for Git repository discovery\n";
  $out .= "  --json       JSON output (most commands)\n";
  $out .= "  --compact    Compact output (list, board)\n";
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

  if ($code > 0) { warn $out } else { print $out }
  exit $code if $code >= 0;
}

around options_usage      => sub { $_[1]->_print_help($_[2]) };
around options_help       => sub { $_[1]->_print_help($_[2]) };
around options_short_usage => sub { $_[1]->_print_help($_[2]) };

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;
  # Default action: show board summary
  eval {
    require App::karr::Cmd::Board;
    App::karr::Cmd::Board->new(
      board_dir => $self->board_dir,
    )->execute($args_ref, $chain_ref);
  };
  if ($@) {
    if ($@ =~ /No karr board found/) {
      die "No karr board found. Run 'karr init' to create one.\n";
    }
    die $@;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr - Kanban Assignment & Responsibility Registry

=head1 VERSION

version 0.102

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
transport and source of truth. Commands materialize a temporary board view only
for the lifetime of a command, then serialize changes back into refs and push
them onward. This keeps the repository free of a persistent F<karr/> board tree
and avoids ordinary file-level merge conflicts for shared task state.

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
repository that contains C<refs/karr/*>. The global C<--dir> option overrides
the starting directory used for that repository discovery.

=head1 DEFAULT BEHAVIOUR

Running C<karr> without a subcommand shows the board summary, which makes the
tool convenient as a quick project status command.

=head1 SEE ALSO

L<karr>, L<App::karr::Git>, L<App::karr::BoardStore>, L<App::karr::Task>,
L<App::karr::Config>, L<App::karr::Cmd::Init>, L<App::karr::Cmd::Skill>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
