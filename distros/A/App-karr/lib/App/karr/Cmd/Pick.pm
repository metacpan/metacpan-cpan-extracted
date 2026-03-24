# ABSTRACT: Atomically find and claim the next available task

package App::karr::Cmd::Pick;
our $VERSION = '0.102';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr pick --claim NAME [--move STATUS] [--status LIST] [--tags LIST]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;
use App::karr::Config;
use Time::Piece;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output', 'App::karr::Role::ClaimTimeout';


option claim => (
  is => 'ro',
  format => 's',
  required => 1,
  doc => 'Agent name to claim the task for',
);

option status => (
  is => 'ro',
  format => 's',
  doc => 'Source status(es) to pick from (comma-separated)',
);

option move => (
  is => 'ro',
  format => 's',
  doc => 'Move picked task to this status',
);

option tags => (
  is => 'ro',
  format => 's',
  doc => 'Only pick tasks matching at least one tag',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->sync_before;

  my $config = App::karr::Config->new(
    file => $self->board_dir->child('config.yml'),
  );

  my @tasks = $self->load_tasks;

  # Filter by status
  if ($self->status) {
    my %allowed = map { $_ => 1 } split /,/, $self->status;
    @tasks = grep { $allowed{$_->status} } @tasks;
  } else {
    # Exclude terminal statuses
    @tasks = grep { $_->status ne 'done' && $_->status ne 'archived' } @tasks;
  }

  # Exclude claimed tasks (unless claim expired)
  my $timeout = $self->_parse_timeout($config->claim_timeout);
  @tasks = grep {
    !$_->has_claimed_by || $self->_claim_expired($_, $timeout)
  } @tasks;

  # Exclude blocked
  @tasks = grep { !$_->has_blocked } @tasks;

  # Filter by tags
  if ($self->tags) {
    my %wanted = map { $_ => 1 } split /,/, $self->tags;
    @tasks = grep {
      my $t = $_;
      grep { $wanted{$_} } @{$t->tags};
    } @tasks;
  }

  # Sort by class priority, then by priority
  my %class_order = (expedite => 0, 'fixed-date' => 1, standard => 2, intangible => 3);
  my %pri_order   = (critical => 0, high => 1, medium => 2, low => 3);

  @tasks = sort {
    ($class_order{$a->class} // 2) <=> ($class_order{$b->class} // 2)
    || ($pri_order{$a->priority} // 2) <=> ($pri_order{$b->priority} // 2)
    || $a->id <=> $b->id
  } @tasks;

  unless (@tasks) {
    print "No available tasks to pick.\n";
    return;
  }

  # Try to lock + claim
  require App::karr::Git;
  my $git = App::karr::Git->new(dir => $self->board_dir->parent->stringify);
  my $use_lock = $git->is_repo;
  my $lock;
  if ($use_lock) {
    require App::karr::Lock;
    $lock = App::karr::Lock->new(git => $git);
  }
  my $email = $use_lock ? ($git->git_user_email || $self->claim) : $self->claim;

  my $picked;
  for my $task (@tasks) {
    if ($use_lock) {
      my ($ok, $msg) = $lock->acquire($task->id, $email);
      next unless $ok;
    }

    $task->claimed_by($self->claim);
    $task->claimed_at(gmtime->datetime . 'Z');

    if ($self->move) {
      $task->status($self->move);
      if ($self->move eq 'in-progress' && !$task->has_started) {
        $task->started(gmtime->strftime('%Y-%m-%d'));
      }
    }

    $task->save;
    $picked = $task;
    last;
  }

  unless ($picked) {
    print "No available tasks to pick (all locked).\n";
    return;
  }

  # Serialize + push BEFORE releasing lock
  $self->sync_after;

  # Log the pick action
  if ($use_lock) {
    $self->append_log($git,
      agent   => $self->claim,
      action  => 'pick',
      task_id => $picked->id,
      detail  => $picked->status,
    );
  }

  # Release lock AFTER sync
  if ($use_lock) {
    $lock->release($picked->id, $email);
  }

  if ($self->json) {
    my $data = $picked->to_frontmatter;
    $data->{body} = $picked->body if $picked->body;
    $self->print_json($data);
    return;
  }

  printf "Picked task %d: %s (claimed by %s)\n", $picked->id, $picked->title, $self->claim;
  printf "Status: %s | Priority: %s | Class: %s\n", $picked->status, $picked->priority, $picked->class;
  if ($picked->body) {
    print "\n" . $picked->body . "\n";
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Pick - Atomically find and claim the next available task

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    karr pick --claim agent-fox
    karr pick --claim agent-fox --status todo --move in-progress
    karr pick --claim agent-fox --tags backend,urgent --json

=head1 DESCRIPTION

Selects the next available task for an agent, taking class of service,
priority, blocked state, and claim expiry into account. When the board lives in
a Git repository, the command also uses lock refs so concurrent agents do not
pick the same task.

=head1 SELECTION RULES

=over 4

=item * Eligible statuses

If C<--status> is omitted, tasks in C<done> and C<archived> are excluded.

=item * Claim timeout

Already claimed tasks are ignored unless their claim timestamp has expired
according to C<claim_timeout>.

=item * Ordering

Candidates are sorted by class of service, then by priority, then by task id.

=item * C<--move>

Optionally updates the picked task to a new status such as C<in-progress>.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::List>, L<App::karr::Cmd::Move>,
L<App::karr::Cmd::Handoff>, L<App::karr::Cmd::AgentName>

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
