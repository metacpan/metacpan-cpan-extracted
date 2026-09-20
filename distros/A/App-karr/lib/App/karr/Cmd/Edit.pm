# ABSTRACT: Modify an existing task

package App::karr::Cmd::Edit;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr edit ID[,ID,...] [--title TEXT] [--priority LEVEL] [options]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::TaskMutation;
use App::karr::Role::DependencyArgs;
use App::karr::Role::ClaimDefault;
use App::karr::Task;
use App::karr::Config;
use App::karr::CrossBoard;
use Time::Piece;

# Both halves of the dependency pair, and the only command that needs both:
# --add-depends-on/--remove-depends-on are parsed by DependencyArgs, and
# --status takes the same warning path as move through TaskMutation, which
# brings App::karr::Role::DependencyCheck with it. Named here since ticket #137
# split the two; before that the set-time helpers arrived through TaskMutation
# by accident of them sharing a role.
with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::TaskMutation', 'App::karr::Role::DependencyArgs',
     'App::karr::Role::ClaimDefault';


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

option add_needs => (
  is => 'ro',
  format => 's',
  doc => 'Add cross-board dependencies (comma-separated BOARD#ID)',
);

option remove_needs => (
  is => 'ro',
  format => 's',
  doc => 'Remove cross-board dependencies (comma-separated BOARD#ID)',
);

option due => (
  is => 'ro',
  format => 's',
  doc => 'New due date',
);

option clear_due => (
  is => 'ro',
  doc => 'Clear due date',
);

option class => (
  is => 'ro',
  format => 's',
  doc => 'New class of service',
);

option estimate => (
  is => 'ro',
  format => 's',
  doc => 'New time estimate',
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

# Opt-in, exactly as on karr handoff, and for the same reason it is opt-in
# there: --append-body appends arbitrary Markdown, not only notes, and the
# stamp is an inline prefix -- forced on every append it would turn
# `-a "## Findings"` into a line that is no longer a heading, with no way to
# say no. kanban-md's edit has the same flag (cmd/edit.go:38); the format is
# handoff's UTC one, not kanban-md's local-time wiki link (ticket #238).
option timestamp => (
  is => 'ro',
  short => 't',
  doc => 'Prefix the appended text with the current UTC timestamp',
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

# Every option above that can change a card, in the order they are declared:
# the ones that carry a value, and the three that are flags. --json and --quiet
# are deliberately absent -- they decide how the result is printed, not what it
# is, so `karr edit 5 --json` asks for a change just as little as `karr edit 5`
# does. (--compact stood here too until #254, when this command stopped taking
# it: it never rendered one, and an option accepted and thrown away is not a
# rendering.) --timestamp is absent for the same reason on the write
# side: it decorates the text --append-body appends and appends nothing of its
# own, so `karr edit 5 --timestamp` names no change either (ticket #238). A new
# field option belongs on one of these lists; leaving it off makes it invisible
# to the check below, which would then reject an invocation that does have
# something to do.
my @FIELD_OPTIONS = qw(
  title status priority assignee add_tag remove_tag add_depends_on
  remove_depends_on add_needs remove_needs due class estimate body append_body
  claim block
);
my @FIELD_FLAGS = qw( clear_due release unblock );

sub _has_field_change {
  my ($self) = @_;
  for my $option (@FIELD_OPTIONS) {
    my $value = $self->$option;
    return 1 if defined $value && length $value;
  }
  for my $flag (@FIELD_FLAGS) {
    return 1 if $self->$flag;
  }
  return 0;
}

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 1);

  $self->sync_before;
  $self->require_board;

  my @pos = $self->positional_args($args_ref);
  my $id_str = $pos[0];
  # See the note in Cmd::Move: length, not truth, or the id "0" is read as no
  # id at all and answered with a usage error instead of "not found" (#239).
  die "Usage: karr edit ID[,ID,...] [FLAGS]\n"
    unless defined $id_str && length $id_str;
  # And a comma with no ids around it passes that guard and
  # splits to nothing, so the command used to exit 0 having done nothing.
  my @ids = $self->parse_ids($id_str);
  die "Usage: karr edit ID[,ID,...] [FLAGS]\n" unless @ids;

  # An edit that names no field asks for nothing, so there is nothing to do and
  # nothing to write. It used to run the whole path with an empty callback:
  # `updated` was stamped (App::karr::BoardStore/save_task_cas), an `edit` entry
  # was appended to the activity log, and stdout said "Updated task N" about a
  # card nothing had touched -- the same false signal `karr move` gave on a
  # same-status move, and the effect t/153-falsy-option-values.t already names
  # as the bug for a value the length guards below discard (#231).
  #
  # A usage error (exit 2), where the same-status move is a success (exit 0),
  # and the two answers come from opposite sides of ADR 0002. A move to the
  # status a card already has is a request whose outcome already holds -- "a
  # no-op like re-archiving an archived task", which the ADR files under 0.
  # This is not a request at all: no field is named, so there is no state to
  # reach and nothing that could have held. That is "an argument list that is
  # syntactically fine but semantically empty", which is what
  # App::karr::Role::ExitCodes/usage_error exists for, and the same answer
  # `karr move , todo` gets one command over. kanban-md refuses it too
  # (internal/board/mutate.go:413-415, "no changes specified"); it exits 1
  # there only because cobra exits 1 for everything.
  #
  # length, not defined, so this asks the same question the write path answers:
  # every guard inside the callback below is `defined && length` (tickets #78,
  # #153), so an empty value sets nothing, and an option whose value the write
  # path discards has not named a change. On the command line MooX::Options
  # refuses an empty value first ("Option title requires an argument", exit 2
  # through App::karr::Role::ExitCodes), so this half of the rule is for an
  # in-process caller -- and for the two lists staying in step rather than
  # drifting into disagreeing about what counts.
  $self->usage_error('no changes specified -- karr edit needs at least one field option')
      unless $self->_has_field_change;

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

  # The two pairs kanban-md rejects on the same layer for the same reason, which
  # this command had left running instead (ticket #235). Both used to take the
  # write callback below through both branches and let the second one win:
  # `--block "waiting" --unblock` left the card unblocked, and
  # `--body neu --append-body note` left it holding "neu\nnote" -- a body the
  # caller asked for neither half of. A caller naming both halves of a pair has
  # contradicted themselves, and the guard above already says what karr does
  # about that. (cmd/edit.go:366-369 and cmd/edit.go:202-206, both
  # StatusConflict; ADR 0002 makes it exit 2 here.)
  #
  # length, not truth, on every value-carrying half, exactly as above: an empty
  # --block names no reason and sets nothing in the callback, so it is not a
  # change for --unblock to contradict (tickets #78, #153) -- the same rule
  # _has_field_change reads one guard up.
  $self->usage_error('cannot use --block and --unblock together')
      if (defined $self->block && length $self->block) && $self->unblock;

  $self->usage_error('cannot use --body and --append-body together')
      if (defined $self->body && length $self->body)
      && (defined $self->append_body && length $self->append_body);

  # The same pair rule, one field over: --due sets a date --clear-due is about
  # to remove, so naming both halves contradicts the caller (ticket #273).
  # length, not truth, on the value-carrying half, exactly as above: an empty
  # --due names no date and sets nothing in the callback, so it is not a change
  # for --clear-due to contradict (tickets #78, #153).
  $self->usage_error('cannot use --due and --clear-due together')
      if (defined $self->due && length $self->due) && $self->clear_due;

  my $config = App::karr::Config->from_merged( $self->store->effective_config );
  $config->validate_priority( $self->priority ) if defined $self->priority;
  $config->validate_class( $self->class )       if defined $self->class;
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

  # The cross-board pair (ticket #192), under the same rule: a malformed
  # BOARD#ID is wrong for every id in the batch at once, so it is checked here
  # and condemns the invocation. Nothing checks whether the far card exists --
  # that is local configuration's question and `karr needs` asks it.
  my $add_needs;
  if ( defined $self->add_needs && length $self->add_needs ) {
    $add_needs = App::karr::CrossBoard->parse_refs( '--add-needs', $self->add_needs );
  }
  my $remove_needs;
  if ( defined $self->remove_needs && length $self->remove_needs ) {
    $remove_needs = App::karr::CrossBoard->parse_refs( '--remove-needs', $self->remove_needs );
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

      # The effective claim: --claim when given, else KARR_CLAIM (ADR 0005).
      # --claim/--release mutual exclusion above stays on the explicit flag, so
      # an env-default claim never turns a plain --release into a usage error.
      my $claim = $self->resolved_claim;

      # --release is the one edit that may act on somebody else's claim: it
      # exists precisely to break a claim a crashed agent left behind, and it
      # is karr's only way out of one before the timeout. Everything else has
      # to own the claim, or find it expired. Same carve-out as kanban-md's
      # validateEditClaim (cmd/edit.go).
      $self->check_claim($task, $claim) unless $self->release;

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
      # priority, assignee, due, class, estimate, body, append, tag or block
      # reason (ticket #153, extending ticket #78's rule from --body to its
      # siblings).
      $task->title($self->title)       if defined $self->title && length $self->title;
      $self->apply_status_change($task, $self->status, $claim) if defined $self->status && length $self->status;
      $task->priority($self->priority) if defined $self->priority && length $self->priority;
      $task->assignee($self->assignee) if defined $self->assignee && length $self->assignee;
      $task->due($self->due)           if defined $self->due && length $self->due;
      $task->clear_due                 if $self->clear_due;
      $task->class($self->class)       if defined $self->class && length $self->class;
      $task->estimate($self->estimate) if defined $self->estimate && length $self->estimate;
      $task->body($self->body)         if defined $self->body && length $self->body;

      # length, not truth: appending to a body of "0" must not replace it
      # (ticket #78). The outer guard had drifted back to truth while the
      # comment still read length-not-truth (ticket #153). What the append
      # itself does -- blank-line separator, no leading separator on an empty
      # body, optional UTC stamp -- lives in App::karr::Task::append_body,
      # shared with handoff, which held a copy of it (ticket #238).
      $task->append_body( $self->append_body, $self->timestamp )
        if defined $self->append_body && length $self->append_body;

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

      # Same shape once more, one field over: a cross-board link is a tag, so
      # append-unique and remove are literally the tag rules (see
      # App::karr::CrossBoard for why the link lives there and not in a
      # frontmatter field of its own).
      App::karr::CrossBoard->add_needs( $task, $add_needs )       if $add_needs;
      App::karr::CrossBoard->remove_needs( $task, $remove_needs ) if $remove_needs;

      if (defined $claim && length $claim) {
        $task->claimed_by($claim);
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
    # --release skips check_claim entirely, so an edit that breaks a claim on
    # purpose records nothing and adds no key here either: it is not an override
    # that went unnoticed, it is the one command whose whole job is saying so
    # (App::karr::Role::ClaimTimeout/expired_claim_report, #177).
    return { id => $task->id, title => $task->title,
             $self->expired_claim_report( $task->id ),
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

version 0.601

=head1 SYNOPSIS

    karr edit 5 --title "Updated title"
    karr edit 5 --add-tag urgent --remove-tag stale
    karr edit 5 --add-depends-on 2,3 --remove-depends-on 4
    karr edit 5 --add-needs other-repo#7 --block "needs other-repo#7: API change first"
    karr edit 5 -a "Waiting for review"
    karr edit 5 -a "Handed the API question upstream" --timestamp
    karr edit 5 --claim agent-fox --block "waiting on API"
    karr edit 5 --class expedite --estimate 3d --due 2026-09-15
    karr edit 5 --clear-due

=head1 DESCRIPTION

Updates one or more existing tasks in place. Use it to adjust metadata, append
notes, manage tags, claim or release ownership, and mark tasks as blocked or
unblocked without changing the task id.

At least one field option is required. C<karr edit 5> on its own, or with only
output options such as C<--json>, names nothing to change and is rejected as a
usage error (exit 2) before any task is read -- it used to report C<Updated
task 5>, bump C<updated> and append an activity-log entry for a card nothing
had touched. An option carrying an empty value counts as no option at all here,
matching the write path, which discards such a value rather than storing it.

=head1 COMMON OPERATIONS

=over 4

=item * Metadata updates

C<--title>, C<--status>, C<--priority>, C<--assignee>, C<--class>,
C<--estimate>, and C<--due> replace existing values. C<--clear-due> removes
the due date, and is rejected together with C<--due> as a usage error (exit 2)
before any task is read. C<--status> is the same status change
L<App::karr::Cmd::Move> performs and obeys the same rules, C<require_claim>
included.

=item * Claim ownership

Editing a task claimed by another agent is refused unless that claim has
expired. C<--claim> with the current claimant's name proceeds, and C<--release>
is exempt, since breaking a stale claim is what it is for.

=item * Body updates

C<--body> replaces the entire body; C<-a>/C<--append-body> appends text to the
existing body as a paragraph of its own, separated from it by a blank line, so
a note reads as a note and not as a continuation of the line above it. An empty
body gains no separator. C<-t>/C<--timestamp> prefixes the appended text with
the current UTC time (C<YYYY-MM-DD HH:MM>), the same stamp
L<App::karr::Cmd::Handoff> writes; without it the text is appended verbatim, so
appending Markdown structure stays possible. C<--body> and C<--append-body> are
alternatives, not a sequence: naming both is rejected as a usage error (exit 2)
before any task is read, rather than writing the one concatenated body neither
of them asked for. Existing cards are not rewritten: the separator rule applies
to appends made from here on.

=item * Claims and blocking

C<--claim> refreshes claim ownership and timestamp, C<--release> clears the
claim, C<--block> records a blocking reason, and C<--unblock> removes it. Each
of those two pairs contradicts itself, so C<--claim> with C<--release> and
C<--block> with C<--unblock> are rejected as usage errors (exit 2) before any
task is read.

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

=item * Cross-board dependency management

C<--add-needs> and C<--remove-needs> accept comma-separated
C<< <board>#<id> >> references naming a card in another repository of the
fleet, and follow the tag rule as well. Only the syntax is checked: whether
that board is on this machine is local configuration, which is
L<App::karr::Cmd::Needs>'s question, not this command's. A reference that is
not C<< <board>#<id> >> -- a path in particular -- rejects the whole
invocation.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Show>, L<App::karr::Cmd::Move>,
L<App::karr::Cmd::Handoff>, L<App::karr::Cmd::List>,
L<App::karr::Cmd::Needs>, L<App::karr::CrossBoard>

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
