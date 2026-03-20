# ABSTRACT: Show board summary

package App::karr::Cmd::Board;
our $VERSION = '0.003';
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

my %STATUS_COLOR = (
  backlog       => 'white',
  todo          => 'cyan',
  'in-progress' => 'yellow',
  review        => 'magenta',
  done          => 'green',
  archived      => 'bright_black',
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
      my $wip = $config->wip_limit($status);
      my %col = (
        status => $status,
        count  => scalar @$tasks_in_status,
        tasks  => [ map { $_->to_frontmatter } @$tasks_in_status ],
      );
      $col{wip_limit} = $wip if $wip;
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
  my $title = colored(" $board_name ", 'bold white on_blue');
  print "\n $title\n\n";

  # Skip empty archived unless it has tasks
  my @display_statuses = grep {
    $_ ne 'archived' || @{$by_status{$_} // []}
  } @statuses;

  my $has_tasks = 0;
  for my $status (@display_statuses) {
    my $tasks = $by_status{$status} // [];
    my $wip = $config->wip_limit($status);
    my $count = scalar @$tasks;
    my $color = $STATUS_COLOR{$status} // 'white';

    # Status header with count and optional WIP
    my $header = uc($status);
    my $count_str;
    if ($wip) {
      my $over = $count > $wip;
      $count_str = $over
        ? colored("$count/$wip", 'bold red')
        : "$count/$wip";
    } else {
      $count_str = "$count";
    }
    printf " %s %s\n", colored($header, "bold $color"), "[$count_str]";

    if (@$tasks) {
      $has_tasks = 1;
      # Separator line
      my $line = colored('─' x 50, $color);
      print " $line\n";
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
