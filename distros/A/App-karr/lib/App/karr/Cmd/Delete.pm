# ABSTRACT: Delete a task

package App::karr::Cmd::Delete;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr delete ID[,ID,...] [--yes] [--claim NAME] [--json]',
);
use IO::Handle;
use App::karr::CrossBoard;
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::TaskMutation;
use App::karr::Task;

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::TaskMutation';


option yes => (
  is => 'ro',
  short => 'y',
  doc => 'Skip confirmation',
);

option claim => (
  is => 'ro',
  format => 's',
  doc => 'Delete a task claimed by this agent',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  $self->check_positional_args($args_ref, 1);

  $self->sync_before;
  $self->require_board;

  my @pos = $self->positional_args($args_ref);
  my $id_str = $pos[0];
  # See the note in Cmd::Move: length, not truth, or the id "0" is read as no
  # id at all and answered with a usage error instead of "not found" (#239).
  die "Usage: karr delete ID[,ID,...] [--yes] [--claim NAME] [--json]\n"
    unless defined $id_str && length $id_str;
  # And a comma with no ids around it passes that guard and
  # splits to nothing, so the command used to exit 0 having done nothing --
  # which on a delete reads as "deleted", and is the worst possible place for
  # that ambiguity.
  my @ids = $self->parse_ids($id_str);
  die "Usage: karr delete ID[,ID,...] [--yes] [--claim NAME] [--json]\n" unless @ids;

  # Every id is attempted, whatever the ones before it did. A missing id used to
  # die from inside this loop, which on delete was the worst version of the bug
  # in ticket #61: the ids already removed locally never reached sync_after, so
  # the batch reported failure with the remote still holding cards karr had
  # deleted.
  my ($results, $failed) = $self->run_batch(\@ids, sub {
    my ($id) = @_;

    my $task = $self->find_task($id);
    # The unguarded pre-read fires before delete_task_guarded below, so this is
    # the not-found a caller normally meets; the guard raises the same line only
    # on the race where the card vanishes in the window. One spelling for both,
    # and for every other command on the mutation path (ticket k264).
    die $self->task_not_found($id) unless $task;

    # A live claim blocks the delete whoever holds it -- unless --claim names
    # the holder, which is the key the refusal message now offers (ticket
    # #269). kanban-md's cmd/delete.go still passes an empty claimant and has
    # no --claim option; karr's delete takes one so the hint the claim check
    # prints is followable. Releasing the claim (or letting it expire) stays
    # the other way through, for the holder as much as for anybody else.
    $self->check_claim($task, $self->claim);

    # Before the confirmation, never after it. The point of the warning is that
    # it can still change the answer, and the operator who reads it and types
    # "n" is the one it worked on -- so it deliberately does not wait for the
    # write the way App::karr::Role::DependencyCheck/dependency_report waits for
    # its own. That rule ("a warning about a move that then lost its
    # compare-and-swap is a warning about something that did not happen") is
    # about a card that survives to be read afterwards. Here the write is what
    # removes the card, so a warning that waits for it is a warning about
    # something nobody can choose to keep any more.
    #
    # Under --yes there is no prompt to precede and it comes anyway: --yes is
    # the mode agents delete in, so a warning only on the interactive path warns
    # exactly where nobody is left to read it.
    my @dependents = $self->_dependent_warnings($task);
    # And what this card says about the boards it cannot see (#242): the far end
    # of an escalation is a tag on the card being deleted, so naming it costs
    # nothing remote.
    my @cross = $self->_cross_board_warnings($task);
    # The channel App::karr::Role::DependencyCheck argues for one module over,
    # rather than a third convention: the human copy on STDERR so STDOUT stays
    # parseable, --quiet silencing that copy, and --json carrying the identical
    # sentence in the result object below because a JSON consumer never reads
    # STDERR.
    print STDERR map { "$_\n" } @dependents, @cross
      unless $self->json || $self->quiet;
    my @warning_report = (
      ( @dependents ? ( dependent_warnings   => \@dependents ) : () ),
      ( @cross      ? ( cross_board_warnings => \@cross )      : () ),
    );

    unless ($self->yes) {
      # STDERR, and not only under --json (#248). The question used to go to
      # STDOUT, which put a bare `Delete task 1: A? [y/N] ` in front of the
      # result object: the object was there, but the stream as a whole would
      # not decode, and this is the command whose output a caller is most
      # likely to read before doing something irreversible.
      #
      # The channel is unconditional rather than a branch on --json, for three
      # reasons. A prompt is not a result -- `deleted` below is the result, and
      # the question is dialogue, which is what STDERR is for; the rule
      # App::karr::Role::DependencyCheck states one module over ("the human
      # copy goes to STDERR so STDOUT stays parseable") is likewise
      # unconditional, only its *suppression* depends on an option. Second, the
      # non-JSON path has the same defect in a quieter form: `karr delete 1 >
      # kept.txt` wrote the question into the file, so the operator at the
      # terminal was asked nothing and waited at a blank cursor. And third,
      # making the channel depend on a flag means the fix only reaches the
      # caller who remembered the flag.
      #
      # Rejecting `--json` without `--yes` outright was the other candidate. It
      # would have deleted a live answer: `deleted => false` with the two
      # warning keys beside it is exactly the shape #236 and #242 built for a
      # card the operator declined to delete, and under --yes there is no
      # prompt to decline at all, so that shape would become unreachable. It
      # also refuses `printf 'y\nn\ny\n' | karr delete 1,2,3 --json`, a
      # per-card answer that --yes cannot express because --yes is
      # all-or-nothing. --json names an output format and --yes a confirmation
      # policy; they are orthogonal, not the contradicting pair #235 refuses.
      printf STDERR "Delete task %d: %s? [y/N] ", $task->id, $task->title;
      # The question has to be out before the read that waits for its answer,
      # and this printf alone does not put it there: it ends without a newline,
      # so nothing in the buffering flushes it (#241).
      #
      # Whether that showed depended on where stdin came from, which is why it
      # went unnoticed for so long. With stdin on a terminal PerlIO flushes the
      # line-buffered handles when it fills its read buffer, so the prompt got
      # out by somebody else's courtesy -- a detail of the implementation, not
      # a promise. With stdin anywhere else -- a pipe, a file, an agent harness
      # feeding answers -- nothing does it, and the question sits in the buffer
      # until the next newline or process exit pushes it out, which is after
      # karr has already acted on the answer. `karr delete 1 < answers` in a
      # terminal printed the question and the outcome together at the end.
      #
      # The flush moves with the question, and what it is worth changed under
      # it: #249 turned autoflush on for STDOUT and STDERR in
      # App::karr::Encoding::enable_std_utf8, so on the CLI path the question is
      # already on the wire when this line runs, and t/241 passes without it.
      # It stays anyway, for the same reason it was written. The promise belongs
      # to the question -- it must be readable before the read below blocks --
      # and not to whatever the process-wide handle setup happens to be today: a
      # caller that reaches this command without bin/karr, an in-process test
      # that reopened STDERR onto a capture handle and so dropped both the layer
      # and the autoflush with it, or a later revert of #249, all get a buffered
      # handle back. ->flush does not care how the handle is buffered, and on an
      # unbuffered one it costs a call, so the question arrives before the wait
      # whichever way stderr and stdin are connected.
      STDERR->flush;
      my $answer = <STDIN>;

      # <STDIN> returns undef at EOF, and karr used to run straight on into
      # `chomp $answer` -- two "Use of uninitialized value $answer" warnings on
      # stderr, then "Skipped task 2: d", for every agent or CI run that forgot
      # --yes (ticket #73). What the right answer to a non-answer is depends on
      # where stdin came from:
      #
      #   a terminal   the user pressed Ctrl-D. That is "no": skip the task and
      #                exit 0, the same as typing n, and now without warnings.
      #
      #   anything else  nobody is there and nobody will be, so there is no
      #                point pretending the prompt happened. Refuse and say what
      #                to do, the way karr's other destructive commands refuse
      #                without --yes and the way kanban-md refuses when
      #                term.IsTerminal is false.
      #
      # An answer that *is* there is honoured either way, so piping "y" or "n"
      # into `karr delete` keeps working.
      die "No answer on stdin and stdin is not a terminal. Re-run with --yes.\n"
        if !defined $answer && !-t STDIN;

      $answer = '' unless defined $answer;
      chomp $answer;
      unless ($answer =~ /^y/i) {
        # Answering "n" is an answer, not a failure: the batch carries on and
        # the command still exits 0 if nothing else went wrong.
        printf "Skipped task %d: %s\n", $task->id, $task->title unless $self->json;
        # The warnings ride along on a card that was kept, too. Under --json
        # the pair is their only channel, and this is the case they were for:
        # `deleted => false` sits beside them and says plainly that the delete
        # they named did not happen.
        return { id => $task->id, title => $task->title, deleted => \0,
                 @warning_report };
      }
    }

    $self->delete_task_guarded($task->id, $self->claim);
    printf "Deleted task %d: %s\n", $task->id, $task->title unless $self->json;
    # Reported here and not before the prompt, because a card the operator
    # answered "n" for had its claim examined but not overridden. The two
    # check_claim calls on this path -- the one above and the one inside
    # delete_task_guarded -- record into the same slot, so this is still one
    # line (#177). Deleting the card is also the one case where nothing survives
    # to be read afterwards, which is what makes the trace matter most here.
    return { id => $task->id, title => $task->title, deleted => \1,
             @warning_report,
             $self->expired_claim_report( $task->id ) };
  });

  $self->sync_after;

  $self->print_json_results(@$results);

  $self->report_batch_failure($failed, scalar @ids);
}

# The backward search kanban-md runs before a delete (board.FindDependents,
# internal/board/board.go:53-72), which karr had no counterpart for: the claim
# check was the only thing between `karr delete 2` and card 6 keeping a
# depends_on pointing at an id the board no longer has (#236). karr already
# *shows* that damage -- `karr show 6` renders "2 (unknown)" through
# Cmd::Show::_dependency_label -- so the information existed; it simply arrived
# after the last moment anybody could act on it.
#
# It warns and deletes, as the reference does. Refusing would make a hard delete
# depend on cards the operator may not care about, and karr answers the whole
# depends_on family by warning rather than blocking (App::karr::Role::
# DependencyCheck, #123). What the warning is *for* here is the door karr has
# and kanban-md does not: `karr archive` keeps the ref, so the dependency still
# resolves and `show` labels it `archived` instead of `unknown`. Naming that
# command is the difference between reporting damage and preventing it.
#
# `parent` is checked beside depends_on, as it is over there. No karr command
# sets it (App::karr::Task) so on a karr-native board the branch never fires --
# but `karr import` brings the field in from a kanban-md board and Task keeps
# it, and unlike a dependency nothing in karr ever renders it afterwards, so
# this is the only place an orphaned child would be named at all. The cost is a
# comparison over a list this method already holds.
#
# Deliberately board-local, and not only because it is cheap that way: a card on
# another board waiting on this one through a `needs:` link
# (App::karr::CrossBoard) is invisible from here, because reading the far board
# needs a path this command does not have and must not invent -- the same line
# App::karr::Role::DependencyCheck draws for the cross-board half of its own
# warning. What can still be said about that board without opening it is
# _cross_board_warnings below.
#
# Re-read per id rather than once for the batch: `karr delete 6,2` should not
# warn that 6 depends on 2 after 6 itself has been deleted, so each id is asked
# about the board as it stands when its turn comes.
sub _dependent_warnings {
  my ($self, $task) = @_;

  my $id = $task->id;
  # Frontmatter carries whatever the document said, so only values that are ids
  # at all are compared: `depends_on: [abc]` is a hand-edited card, not a
  # dependent, and `==` on it would add "Argument isn't numeric" to the output
  # of a delete -- the same care run_batch takes when echoing a non-numeric
  # batch id.
  my $names_id = sub {
    my ($value) = @_;
    return 0 unless defined $value && $value =~ /\A[0-9]+\z/;
    return $value + 0 == $id ? 1 : 0;
  };

  my @warnings;
  # load_tasks is already in ascending id order (App::karr::BoardStore).
  for my $other ($self->load_tasks) {
    next if $other->id == $id;
    push @warnings, sprintf
      'Warning: task %d (%s) depends on task %d, which is being deleted '
      . '(use "karr archive %d" to keep the card)',
      $other->id, $other->title, $id, $id
      if grep { $names_id->($_) } @{ $other->depends_on };
    push @warnings, sprintf
      'Warning: task %d (%s) has task %d as its parent, which is being deleted '
      . '(use "karr archive %d" to keep the card)',
      $other->id, $other->title, $id, $id
      if $names_id->( $other->parent );
  }
  return @warnings;
}

# The same arrival-too-late, one repository over (#242). `karr delete 1` on the
# board an escalation was raised on said nothing, and `karr needs` on the board
# that raised it then reported `task 1 does not exist on board boardA` -- the
# cross-board spelling of `2 (unknown)`, and a worse one: App::karr::CrossBoard/
# link_state calls that state `missing`, and `karr needs --resolve` refuses on
# purpose to settle a link whose card cannot be read, so a card blocked on it
# stays blocked with nothing over there able to lift it.
#
# The far board is still not opened. What makes a warning possible anyway is
# that the escalation protocol writes its far end onto *this* card:
# `escalated-from:<board>#<id>`, set by `karr create --escalated-from`, is a tag
# on the card being deleted. Naming the far card out of this board's own tag is
# the honest reach -- resolving it would need the fleet configuration `karr
# needs` reads and this command does not, and `karr needs` is the command that
# already answers that question.
#
# `finished or not` is the honest half of the `karr archive` door (#250).
# Archiving keeps the link resolvable, and CrossBoard/link_state settles it on
# the far board the moment this card is terminal -- whether the card was
# finished or given up. karr records progress, not outcome, and a card archived
# out of the backlog is frontmatter-identical to one archived after `done`
# (CONTEXT.md, Task lifecycle), so nothing here could tell the far board which
# it was. Saying it in the warning is all this side can do; reporting it on the
# reading side is ticket #258.
#
# `may be waiting on it` rather than `is`: the two halves of the protocol are a
# convention that nothing enforced before this module existed, which is why
# App::karr::CrossBoard/link_state has a `verified` field at all. The far card
# usually carries the matching `needs:`; this side cannot know that it does.
#
# The `needs:` direction is reported too and says something else, so it reads as
# a different sentence and carries no `karr archive` door: keeping the card
# would repair nothing over there, because nothing over there is broken -- the
# link is on the card being deleted and goes with it. What ends is anything on
# this board waiting for the far card, and once the card is gone no command
# mentions it again: `karr needs` reads links off the cards that carry them.
sub _cross_board_warnings {
  my ($self, $task) = @_;

  my $id = $task->id;
  my @warnings;
  # Tag order, as App::karr::CrossBoard returns it. A tag that carries the
  # prefix but not a well-formed reference is skipped there, and a delete must
  # not invent a third state for it either.
  for my $ref ( App::karr::CrossBoard->escalated_from_of($task) ) {
    push @warnings, sprintf
      'Warning: task %d (%s) was escalated from %s, which may be waiting on it '
      . 'from another board (use "karr archive %d" to keep that link resolvable '
      . '-- it reads as settled over there, finished or not)',
      $id, $task->title, App::karr::CrossBoard->format_ref($ref), $id;
  }
  for my $ref ( App::karr::CrossBoard->needs_of($task) ) {
    push @warnings, sprintf
      'Warning: task %d (%s) waits on %s on another board, and nothing here '
      . 'will be waiting for it once this card is gone',
      $id, $task->title, App::karr::CrossBoard->format_ref($ref);
  }
  return @warnings;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Delete - Delete a task

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr delete 9
    karr delete 9,10,11 --yes
    karr delete 9 --yes --claim agent-fox
    karr delete 9 --json

=head1 DESCRIPTION

Permanently removes one or more tasks' refs from the board. This is the
destructive alternative to L<App::karr::Cmd::Archive>, which only changes the
status to C<archived>.

=head1 OPTIONS

=over 4

=item * C<--yes>

Skips the interactive confirmation prompt for each task. Required whenever
nothing will answer that prompt: if stdin is not a terminal and carries no
answer, the command refuses rather than guessing.

=item * C<--claim>

Delete a task claimed by this agent. This is the key to the claim rule: a card
held by C<NAME> is deleted when C<--claim NAME> is passed, and a card held by
anybody else is still refused. The claim is not re-stamped -- the card is
being removed, so the name only unlocks the check.

=back

The prompt itself goes to STDERR, on every path and not only under C<--json>: a
question is dialogue, not a result, and STDOUT belongs to the result. That is
what keeps C<< karr delete ID --json >> decodable as a whole when the answer is
typed rather than passed as C<--yes>, and what keeps C<< karr delete ID >
kept.txt >> from writing the question into the file instead of showing it to the
operator waiting for it. The outcome stays on STDOUT: C<Deleted task ...> or
C<Skipped task ...> in plain mode, and the result object -- with C<deleted> true
or false -- under C<--json>.

=head1 CLAIMS

A task with a live claim is not deleted, whoever holds it -- unless C<--claim>
names the holder, which is how the holder (or an agent acting for it) deletes
its own card. Release the claim with C<< karr edit ID --release >> or wait for
C<claim_timeout> to expire it.

=head1 DEPENDENTS

Before an id is removed the board is searched for the cards that point at it --
a C<depends_on> entry naming it, or C<parent> set to it -- and each one is named
on STDERR as a C<Warning:>, offering C<karr archive> as the way to keep the card
instead. The delete then proceeds: karr warns about dependencies rather than
blocking on them (L<App::karr::Role::DependencyCheck>), and this warning exists
to send a caller from the destructive way to the soft one, not to refuse them
the destructive one.

It comes before the confirmation prompt, so it can still change the answer, and
it comes under C<--yes> as well, which is the mode agents delete in. C<--json>
carries the identical sentences as C<dependent_warnings> in the result object
instead, and C<--quiet> silences the STDERR copy.

The search is board-local: it reads the cards on this board. What the card
being deleted says about I<other> boards is a second warning, below.

=head1 CROSS-BOARD LINKS

A card on another board waiting on this one through a C<needs:> link
(L<App::karr::CrossBoard>) cannot be seen from here -- reading the far board
needs a path this command does not have. The card being deleted usually names
that far card itself, though: C<< escalated-from:<board>#<id> >>, the other half
of the escalation protocol, is a tag on this card and is read without touching
anything remote. Both directions are reported, in different words:

=over 4

=item * C<escalated-from:> -- the far card this one was raised for. Deleting
this card leaves that link unresolvable: C<karr needs> over there calls it
C<missing>, and C<< karr needs --resolve >> refuses on purpose to settle a link
whose card cannot be read, so a card blocked on it stays blocked. C<karr
archive> is the way out here too -- an archived card is still readable and
C<archived> is terminal on every board, so the link settles instead of breaking.
Settling says the far card is closed, not that it succeeded: karr records
progress and not outcome, so archiving a card that was given up reports the same
thing over there as archiving a finished one. The warning says so; if the card
is being abandoned, that is worth a word on the far board itself. That karr has
no "given up" to report at all is the decision in
F<docs/adr/0004-a-terminal-status-is-finished.md>, not an omission here.

=item * C<needs:> -- a far card this one waits on. Nothing over there breaks
when this card goes, because the link goes with it; what ends is anything on
this board waiting for that far card, and no other command says so once the
card is gone.

=back

The reference is named, never resolved. Placing a board name on this machine
needs the fleet configuration C<karr needs> reads and C<karr delete> does not,
and C<karr needs> is the command that already answers what state the far card
is in. C<--json> carries these sentences as C<cross_board_warnings> -- a key of
their own beside C<dependent_warnings>, because a consumer that can act on a
dangling dependency on this board cannot act on a card in another repository.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Archive>,
L<App::karr::Cmd::Backup>, L<App::karr::Cmd::Destroy>

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
