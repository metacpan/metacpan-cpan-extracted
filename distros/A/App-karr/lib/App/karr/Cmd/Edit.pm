# ABSTRACT: Modify an existing task

package App::karr::Cmd::Edit;
our $VERSION = '0.500';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr edit ID[,ID,...] [--title TEXT] [--priority LEVEL] [options]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::TaskMutation;
use App::karr::Role::DependencyArgs;
use App::karr::Task;
use App::karr::Config;
use Time::Piece;

# Both halves of the dependency pair, and the only command that needs both:
# --add-depends-on/--remove-depends-on are parsed by DependencyArgs, and
# --status takes the same warning path as move through TaskMutation, which
# brings App::karr::Role::DependencyCheck with it. Named here since ticket #137
# split the two; before that the set-time helpers arrived through TaskMutation
# by accident of them sharing a role.
with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::TaskMutation', 'App::karr::Role::DependencyArgs';


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

option add_depends_on => (
  is => 'ro',
  format => 's',
  doc => 'Add dependency ids (comma-separated)',
);

option remove_depends_on => (
  is => 'ro',
  format => 's',
  doc => 'Remove dependency ids (comma-separated)',
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

  $self->check_positional_args($args_ref, 1);

  $self->sync_before;
  $self->require_board;

  my @pos = $self->positional_args($args_ref);
  my $id_str = $pos[0] or die "Usage: karr edit ID[,ID,...] [FLAGS]\n";
  # See the note in Cmd::Move: a comma with no ids around it is truthy here and
  # splits to nothing, so the command used to exit 0 having done nothing.
  my @ids = $self->parse_ids($id_str);
  die "Usage: karr edit ID[,ID,...] [FLAGS]\n" unless @ids;

  # Once, before any task is touched: these are plain option values, so a bad
  # one must not update the first half of a batch (ticket #54). --status is not
  # here because it goes through apply_status_change, which is the one place a
  # status change happens and therefore the one place its name is checked.
  #
  # --claim and --release are mutually exclusive: --claim sets a claim --release
  # is about to discard, so the require_claim guard in apply_status_change would
  # be satisfied by a claim the same command is clearing and let the task land
  # in a require_claim column with no claim on it (ticket #150). kanban-md
  # rejects the pair at the flag layer too (cmd/edit.go:128-130); we match.
  $self->usage_error('cannot use --claim and --release together')
      if (defined $self->claim && length $self->claim) && $self->release;

  my $config = App::karr::Config->from_merged( $self->store->effective_config );
  $config->validate_priority( $self->priority ) if defined $self->priority;
  App::karr::Config->validate_due( $self->due ) if defined $self->due;

  # Same rule for the dependency flags (ticket #124): a malformed or unknown
  # id is wrong for every id in the batch at once. Only ids being *added* must
  # exist -- removing an id the board no longer has is how a dependency on a
  # deleted task is cleaned up. length, not truth (ticket #78).
  my $add_depends;
  if ( defined $self->add_depends_on && length $self->add_depends_on ) {
    $add_depends = $self->parse_dependency_ids( '--add-depends-on', $self->add_depends_on );
    $self->assert_dependencies_exist($add_depends);
  }
  my $remove_depends;
  if ( defined $self->remove_depends_on && length $self->remove_depends_on ) {
    $remove_depends = $self->parse_dependency_ids( '--remove-depends-on', $self->remove_depends_on );
  }

  # Every id is attempted, whatever the ones before it did: a missing id used to
  # die from inside this loop and take the rest of the batch with it (ticket
  # #61). The option-value checks above stay outside it, because they condemn
  # the whole invocation rather than one id.
  my ($results, $failed) = $self->run_batch(\@ids, sub {
    my ($id) = @_;

    # A self-reference is the one dependency error that is per-id rather than
    # per-invocation: `edit 4,5 --add-depends-on 5` is valid for 4 and wrong
    # for 5, so it fails this id and lets the batch carry on (ticket #61).
    # kanban-md rejects it at the same moment (ValidateDependencyIDs). The
    # numeric guard keeps a non-numeric batch id headed for its own "Task X
    # not found" instead of a numeric-comparison warning.
    die "Task $id cannot depend on itself\n"
      if $add_depends && $id =~ /\A[0-9]+\z/ && grep { $_ == $id } @$add_depends;

    my $task = $self->update_task_guarded($id, sub {
      my ($task) = @_;

      # --release is the one edit that may act on somebody else's claim: it
      # exists precisely to break a claim a crashed agent left behind, and it
      # is karr's only way out of one before the timeout. Everything else has
      # to own the claim, or find it expired. Same carve-out as kanban-md's
      # validateEditClaim (cmd/edit.go).
      $self->check_claim($task, $self->claim) unless $self->release;

      # Clear the claim BEFORE the status change so the require_claim guard
      # in apply_status_change sees the post-release state: --release sets up
      # a claim the guard was about to satisfy, and a status change into a
      # require_claim column would otherwise walk straight through and leave
      # the card with no owner (ticket #150). kanban-md's equivalent check
      # (validateEditPost, internal/board/mutate.go:442) fires after applyFn
      # regardless of release.
      if ($self->release) {
        $task->clear_claimed_by;
        $task->clear_claimed_at;
      }

      # length, not truth: a literal "0" is a meaningful title, status,
      # priority, assignee, due, body, append, tag or block reason (ticket
      # #153, extending ticket #78's rule from --body to its siblings).
      $task->title($self->title)       if defined $self->title && length $self->title;
      $self->apply_status_change($task, $self->status, $self->claim) if defined $self->status && length $self->status;
      $task->priority($self->priority) if defined $self->priority && length $self->priority;
      $task->assignee($self->assignee) if defined $self->assignee && length $self->assignee;
      $task->due($self->due)           if defined $self->due && length $self->due;
      $task->body($self->body)         if defined $self->body && length $self->body;

      if (defined $self->append_body && length $self->append_body) {
        # length, not truth: appending to a body of "0" must not replace it
        # (ticket #78). The outer guard had drifted back to truth while the
        # comment still read length-not-truth (ticket #153).
        my $have = defined $task->body && length $task->body;
        $task->body(($have ? $task->body . "\n" : '') . $self->append_body);
      }

      if (defined $self->add_tag && length $self->add_tag) {
        my @new = split /,/, $self->add_tag;
        my %existing = map { $_ => 1 } @{$task->tags};
        push @{$task->tags}, grep { !$existing{$_} } @new;
      }

      if (defined $self->remove_tag && length $self->remove_tag) {
        my %remove = map { $_ => 1 } split /,/, $self->remove_tag;
        $task->tags([grep { !$remove{$_} } @{$task->tags}]);
      }

      # The --add-tag/--remove-tag shape: append-unique and remove, so one
      # rule covers both list fields (ticket #124).
      if ($add_depends) {
        my %existing = map { $_ => 1 } @{$task->depends_on};
        push @{$task->depends_on}, grep { !$existing{$_} } @$add_depends;
      }

      if ($remove_depends) {
        my %remove = map { $_ => 1 } @$remove_depends;
        $task->depends_on([grep { !$remove{$_} } @{$task->depends_on}]);
      }

      if (defined $self->claim && length $self->claim) {
        $task->claimed_by($self->claim);
        $task->claimed_at(gmtime->datetime . 'Z');
      }

      if (defined $self->block && length $self->block) {
        $task->block($self->block);
      }

      if ($self->unblock) {
        $task->unblock;
      }
    });

    printf "Updated task %d: %s\n", $task->id, $task->title unless $self->json;
    # --status goes through apply_status_change, so an edit that takes a card
    # up gets the same dependency warning `karr move` does, for free and by
    # construction -- the #55 point again (ticket #123). An edit that changes
    # anything else records nothing, so this adds no key.
    return { id => $task->id, title => $task->title,
             $self->dependency_report( $task->id ) };
  });

  $self->sync_after;

  $self->print_json_results(@$results);

  $self->report_batch_failure($failed, scalar @ids);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Edit - Modify an existing task

=head1 VERSION

version 0.500

=head1 SYNOPSIS

    karr edit 5 --title "Updated title"
    karr edit 5 --add-tag urgent --remove-tag stale
    karr edit 5 --add-depends-on 2,3 --remove-depends-on 4
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
existing values. C<--status> is the same status change L<App::karr::Cmd::Move>
performs and obeys the same rules, C<require_claim> included.

=item * Claim ownership

Editing a task claimed by another agent is refused unless that claim has
expired. C<--claim> with the current claimant's name proceeds, and C<--release>
is exempt, since breaking a stale claim is what it is for.

=item * Body updates

C<--body> replaces the entire body; C<-a>/C<--append-body> appends a new line
to the existing body text.

=item * Claims and blocking

C<--claim> refreshes claim ownership and timestamp, C<--release> clears the
claim, C<--block> records a blocking reason, and C<--unblock> removes it.

=item * Tag management

C<--add-tag> and C<--remove-tag> accept comma-separated lists.

=item * Dependency management

C<--add-depends-on> and C<--remove-depends-on> accept comma-separated task
ids and follow the tag rule: add appends without duplicating, remove is a
no-op for ids the card does not carry. Ids being added must exist on this
board and must not name the task itself; an unknown or non-numeric id rejects
the whole invocation as a usage error before anything is written, while a
self-reference fails only the id it is wrong for and lets the rest of the
batch proceed. Removing an id the board no longer has stays legal -- it is
how a dependency on a deleted task is cleaned up.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Show>, L<App::karr::Cmd::Move>,
L<App::karr::Cmd::Handoff>, L<App::karr::Cmd::List>

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
