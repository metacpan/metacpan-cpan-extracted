# ABSTRACT: Change a task's status

package App::karr::Cmd::Move;
our $VERSION = '0.003';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr move ID[,ID,...] STATUS [--claim NAME] [--next|--prev]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;
use App::karr::Config;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';

option next => (
  is => 'ro',
  doc => 'Advance to next status',
);

option prev => (
  is => 'ro',
  doc => 'Move to previous status',
);

option claim => (
  is => 'ro',
  format => 's',
  doc => 'Claim task for an agent',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->sync_before;

  my $id_str = $args_ref->[0] or die "Usage: karr move ID[,ID,...] [STATUS]\n";
  my @ids = $self->parse_ids($id_str);
  my $new_status = $args_ref->[1];

  my $config = App::karr::Config->new(
    file => $self->board_dir->child('config.yml'),
  );
  my @statuses = $config->statuses;

  my @results;
  for my $id (@ids) {
    my $task = $self->find_task($id);
    die "Task $id not found\n" unless $task;

    my $task_new_status = $new_status;

    if ($self->next) {
      my $idx = $self->_status_index(\@statuses, $task->status);
      die "Already at last status\n" if $idx >= $#statuses;
      $task_new_status = $statuses[$idx + 1];
    } elsif ($self->prev) {
      my $idx = $self->_status_index(\@statuses, $task->status);
      die "Already at first status\n" if $idx <= 0;
      $task_new_status = $statuses[$idx - 1];
    }

    die "New status required\n" unless $task_new_status;

    # Check require_claim
    my $sc = $config->status_config($task_new_status);
    if ($sc && $sc->{require_claim} && !$self->claim && !$task->has_claimed_by) {
      die "Status '$task_new_status' requires --claim\n";
    }

    if ($self->claim) {
      $task->claimed_by($self->claim);
      require Time::Piece;
      $task->claimed_at(Time::Piece::gmtime()->datetime . 'Z');
    }

    my $old_status = $task->status;
    $task->status($task_new_status);

    # Set started/completed timestamps
    if ($task_new_status eq 'in-progress' && !$task->has_started) {
      require Time::Piece;
      $task->started(Time::Piece::gmtime()->strftime('%Y-%m-%d'));
    }
    if ($task_new_status eq 'done' && !$task->has_completed) {
      require Time::Piece;
      $task->completed(Time::Piece::gmtime()->strftime('%Y-%m-%d'));
    }

    $task->save;

    push @results, { id => $task->id, title => $task->title, old_status => $old_status, new_status => $task_new_status };
    printf "Moved task %d: %s -> %s\n", $task->id, $old_status, $task_new_status unless $self->json;
  }

  $self->sync_after;

  if ($self->json) {
    $self->print_json(@results == 1 ? $results[0] : \@results);
  }
}

sub _status_index {
  my ($self, $statuses, $status) = @_;
  for my $i (0..$#$statuses) {
    return $i if $statuses->[$i] eq $status;
  }
  die "Unknown status: $status\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Move - Change a task's status

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
