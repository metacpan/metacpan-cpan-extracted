# ABSTRACT: Show board summary

package App::karr::Cmd::Board;
our $VERSION = '0.102';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr board [--json] [--compact]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;
use App::karr::Config;
use Term::ANSIColor qw( colored );

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


my %STATUS_STYLE = (
  backlog       => 'bold black on_white',
  todo          => 'bold black on_cyan',
  'in-progress' => 'bold black on_yellow',
  review        => 'bold black on_white',
  done          => 'bold black on_green',
  archived      => 'bold white on_black',
);

my %PRIORITY_COLOR = (
  critical => 'bold red',
  high     => 'red',
  medium   => 'yellow',
  low      => 'bright_black',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  my $config = App::karr::Config->new(
    file => $self->board_dir->child('config.yml'),
  );

  my @statuses = $config->statuses;
  my @tasks = $self->load_tasks;

  my %by_status;
  for my $t (@tasks) {
    push @{$by_status{$t->status}}, $t;
  }

  if ($self->json) {
    my $board_name = $config->data->{board}{name} // 'Kanban Board';
    my %board_data = (
      name     => $board_name,
      total    => scalar @tasks,
      columns  => [],
    );
    for my $status (@statuses) {
      my $tasks_in_status = $by_status{$status} // [];
      my %col = (
        status => $status,
        count  => scalar @$tasks_in_status,
        tasks  => [ map { $_->to_frontmatter } @$tasks_in_status ],
      );
      push @{$board_data{columns}}, \%col;
    }
    $self->print_json(\%board_data);
    return;
  }

  if ($self->compact) {
    for my $status (@statuses) {
      my $tasks_in_status = $by_status{$status} // [];
      my $count = scalar @$tasks_in_status;
      my $ids = join(',', map { $_->id } @$tasks_in_status);
      printf "%s(%d): %s\n", $status, $count, $ids || '-';
    }
    return;
  }

  my $board_name = $config->data->{board}{name} // 'Kanban Board';
  my $title = colored(" $board_name ", 'bold white on_black');
  print "\n $title\n\n";

  # Skip empty archived unless it has tasks
  my @display_statuses = grep {
    $_ ne 'archived' || @{$by_status{$_} // []}
  } @statuses;

  my $has_tasks = 0;
  for my $status (@display_statuses) {
    my $tasks = $by_status{$status} // [];
    my $count = scalar @$tasks;
    my $style = $STATUS_STYLE{$status} // 'bold white on_black';

    my $header = uc($status);
    printf " %s %s\n", colored(" $header ", $style), "[$count]";

    if (@$tasks) {
      $has_tasks = 1;
      print " " . ('-' x 52) . "\n";
      for my $t (@$tasks) {
        my $id_str = colored(sprintf('#%d', $t->id), 'bold');
        my $pri_color = $PRIORITY_COLOR{$t->priority} // 'white';
        my $pri_str = colored($t->priority, $pri_color);
        my $title = $t->title;

        my @badges;
        if ($t->has_claimed_by) {
          push @badges, colored('@' . $t->claimed_by, 'cyan');
        }
        if ($t->has_blocked) {
          push @badges, colored('BLOCKED', 'bold red');
        }
        if ($t->has_due) {
          push @badges, colored('due:' . $t->due, 'yellow');
        }

        printf "   %s  %-8s  %s", $id_str, $pri_str, $title;
        printf "  %s", join(' ', @badges) if @badges;
        print "\n";
      }
    }
    print "\n";
  }

  # Summary line
  my $blocked = grep { $_->has_blocked } @tasks;
  my $claimed = grep { $_->has_claimed_by } @tasks;
  my @summary;
  push @summary, colored(scalar(@tasks) . ' tasks', 'bold');
  push @summary, colored("$claimed claimed", 'cyan') if $claimed;
  push @summary, colored("$blocked blocked", 'red') if $blocked;
  printf " %s\n\n", join('  ', @summary);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Board - Show board summary

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    karr board
    karr board --compact
    karr board --json

=head1 DESCRIPTION

Renders a board-oriented summary grouped by status. The default output is a
human-friendly terminal dashboard with colors and task badges for claims,
blocked state, and due dates. Compact and JSON modes are available for
automation and scripting.

=head1 OUTPUT MODES

=over 4

=item * Default output

Shows statuses in board order with task counts and a task summary under each
populated column.

=item * C<--compact>

Prints one line per status in the form C<status(count): ids>.

=item * C<--json>

Emits the board name, total task count, and a structured C<columns> array with
per-status task lists.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::List>, L<App::karr::Cmd::Show>,
L<App::karr::Cmd::Pick>, L<App::karr::Cmd::Context>

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
