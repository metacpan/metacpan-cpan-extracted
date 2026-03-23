# ABSTRACT: Modify an existing task

package App::karr::Cmd::Edit;
our $VERSION = '0.101';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr edit ID[,ID,...] [--title TEXT] [--priority LEVEL] [options]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Task;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


option title => (
  is => 'ro',
  format => 's',
  doc => 'New title',
);

option status => (
  is => 'ro',
  format => 's',
  doc => 'New status',
);

option priority => (
  is => 'ro',
  format => 's',
  doc => 'New priority',
);

option assignee => (
  is => 'ro',
  format => 's',
  doc => 'New assignee',
);

option add_tag => (
  is => 'ro',
  format => 's',
  doc => 'Add tags (comma-separated)',
);

option remove_tag => (
  is => 'ro',
  format => 's',
  doc => 'Remove tags (comma-separated)',
);

option due => (
  is => 'ro',
  format => 's',
  doc => 'New due date',
);

option body => (
  is => 'ro',
  format => 's',
  doc => 'New body text',
);

option append_body => (
  is => 'ro',
  format => 's',
  short => 'a',
  doc => 'Append text to body',
);

option claim => (
  is => 'ro',
  format => 's',
  doc => 'Claim task for an agent',
);

option release => (
  is => 'ro',
  doc => 'Release claim',
);

option block => (
  is => 'ro',
  format => 's',
  doc => 'Mark as blocked with reason',
);

option unblock => (
  is => 'ro',
  doc => 'Clear blocked state',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->sync_before;

  my $id_str = $args_ref->[0] or die "Usage: karr edit ID[,ID,...] [FLAGS]\n";
  my @ids = $self->parse_ids($id_str);

  my @results;
  for my $id (@ids) {
    my $task = $self->find_task($id);
    die "Task $id not found\n" unless $task;

    $task->title($self->title)       if $self->title;
    $task->status($self->status)     if $self->status;
    $task->priority($self->priority) if $self->priority;
    $task->assignee($self->assignee) if $self->assignee;
    $task->due($self->due)           if $self->due;
    $task->body($self->body)         if defined $self->body;

    if ($self->append_body) {
      $task->body(($task->body ? $task->body . "\n" : '') . $self->append_body);
    }

    if ($self->add_tag) {
      my @new = split /,/, $self->add_tag;
      my %existing = map { $_ => 1 } @{$task->tags};
      push @{$task->tags}, grep { !$existing{$_} } @new;
    }

    if ($self->remove_tag) {
      my %remove = map { $_ => 1 } split /,/, $self->remove_tag;
      $task->tags([grep { !$remove{$_} } @{$task->tags}]);
    }

    if ($self->claim) {
      $task->claimed_by($self->claim);
      require Time::Piece;
      $task->claimed_at(Time::Piece::gmtime()->datetime . 'Z');
    }

    if ($self->release) {
      $task->claimed_by(undef);
      $task->claimed_at(undef);
    }

    if ($self->block) {
      $task->blocked($self->block);
    }

    if ($self->unblock) {
      $task->blocked(undef);
    }

    # Handle title change -> file rename
    if ($self->title && $task->has_file_path) {
      my $old_file = $task->file_path;
      my $new_file = $self->tasks_dir->child($task->filename);
      $task->save($self->tasks_dir);
      $old_file->remove if "$old_file" ne "$new_file";
    } else {
      $task->save;
    }

    push @results, { id => $task->id, title => $task->title };
    printf "Updated task %d: %s\n", $task->id, $task->title unless $self->json;
  }

  $self->sync_after;

  if ($self->json) {
    $self->print_json(@results == 1 ? $results[0] : \@results);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Edit - Modify an existing task

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    karr edit 5 --title "Updated title"
    karr edit 5 --add-tag urgent --remove-tag stale
    karr edit 5 -a "Waiting for review"
    karr edit 5 --claim agent-fox --block "waiting on API"

=head1 DESCRIPTION

Updates one or more existing tasks in place. Use it to adjust metadata, append
notes, manage tags, claim or release ownership, and mark tasks as blocked or
unblocked without changing the task id.

=head1 COMMON OPERATIONS

=over 4

=item * Metadata updates

C<--title>, C<--status>, C<--priority>, C<--assignee>, and C<--due> replace
existing values.

=item * Body updates

C<--body> replaces the entire body; C<-a>/C<--append-body> appends a new line
to the existing body text.

=item * Claims and blocking

C<--claim> refreshes claim ownership and timestamp, C<--release> clears the
claim, C<--block> records a blocking reason, and C<--unblock> removes it.

=item * Tag management

C<--add-tag> and C<--remove-tag> accept comma-separated lists.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Show>, L<App::karr::Cmd::Move>,
L<App::karr::Cmd::Handoff>, L<App::karr::Cmd::List>

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
