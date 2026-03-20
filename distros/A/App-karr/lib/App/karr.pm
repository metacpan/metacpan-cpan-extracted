# ABSTRACT: Kanban Assignment & Responsibility Registry

package App::karr;
our $VERSION = '0.003';
use Moo;
use MooX::Cmd;
use MooX::Options;
use Term::ANSIColor qw( colored );
use App::karr::Role::BoardAccess;

with 'App::karr::Role::BoardAccess';

option dir => (
  is => 'ro',
  format => 's',
  doc => 'Path to karr board directory (overrides auto-detection)',
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
  [ config    => 'View or modify board config' ],
  [ context   => 'Generate board context summary' ],
  [ sync      => 'Sync board with remote' ],
  [ agentname => 'Generate a random agent name' ],
  [ skill     => 'Install/update agent skills' ],
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
  $out .= "  --dir PATH   Board directory (default: auto-detect karr/)\n";
  $out .= "  --json       JSON output (most commands)\n";
  $out .= "  --compact    Compact output (list, board)\n";
  $out .= "\n" . colored("EXAMPLES:", 'bold') . "\n";
  $out .= "  karr init --name \"My Project\"\n";
  $out .= "  karr create --title \"Fix login bug\" --priority high\n";
  $out .= "  karr list --status todo,in-progress\n";
  $out .= "  karr move 1 in-progress --claim agent-fox\n";
  $out .= "  karr pick --claim agent-fox --move in-progress\n";
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

version 0.003

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
