# ABSTRACT: The one guarded path for changing an existing task

package App::karr::Role::TaskMutation;
our $VERSION = '0.601';
use Moo::Role;
# No Time::Piece here on purpose: this role never asks for the time itself --
# the lifecycle stamps are set by App::karr::Task::update_timestamps, which
# loads its own -- and `use Time::Piece;` composed its localtime/gmtime
# replacements into move, edit, delete, archive and handoff for nothing (#105).
use App::karr::Task;
use App::karr::Config;
# Loaded without importing, for the reason spelled out in
# App::karr::Role::Output: a Moo::Role composes every sub in its package into
# its consumers, imported ones included, so `use ... qw( user_error )` here
# would quietly make user_error a method on move, edit, delete, archive and
# handoff.
use App::karr::Error ();
# Same reason, one module over: `use Scalar::Util qw( refaddr );` here would put
# a refaddr method on every command that composes this role.
use Scalar::Util ();
use App::karr::Role::ClaimTimeout;
use App::karr::Role::DependencyCheck;

with 'App::karr::Role::ClaimTimeout', 'App::karr::Role::DependencyCheck';

# What this role calls on its consumer, said out loud (ticket #141; the rule is
# ticket #128's). It declared nothing at all until then, and got away with it
# only because every command on the mutation path composes the roles that supply
# these: git and store from App::karr::Role::BoardDiscovery, save_task and
# log_task_write from App::karr::Role::BoardAccess, json from
# App::karr::Role::Output. Same accident App::karr::Role::DependencyCheck lived
# on before #128, one module over -- and a worse one to leave standing, because
# this role is how a command reaches update_task_guarded without ever naming the
# collaborators that path needs.
#
# Two of the calls below are deliberately not on the list: check_claim and
# check_dependencies come from the two roles composed above, so they are this
# role's own methods and not the consumer's. Requiring one of them would be
# worse than redundant -- it could never fail. Role::Tiny installs a role's
# methods into the consumer *before* it checks the requires
# (role_application_steps), so the check would find the name the composition had
# just put there, in every consumer, always, and read as a guarantee that is not
# one.
#
# json is declared here and on App::karr::Role::DependencyCheck both. The
# duplication is intended: run_batch reads $self->json for its own per-id
# warnings, and a role that lets a role it happens to compose declare a
# collaborator on its behalf is the arrangement this ticket is about.
requires qw( git store save_task log_task_write json );


# One batch loop for every command that takes ID[,ID,...].
#
# `move`, `edit` and `delete` used to die on the first missing id from inside
# the loop, which skipped every id after it: `move 1,999,2` moved 1 and never
# looked at 2, while `move 999,1,2` moved nothing. Which ids survived depended
# on where the bad one sat in the list. `archive` was the only one that already
# warned and carried on, and it is the shape ADR 0002 settled on: "partial
# success is committed, the exit code reports the failure (1)" -- the same
# contract as kanban-md's runBatch (cmd/root.go), which attempts every id,
# prints the per-id failures, and still returns 1 if any of them failed
# (ticket #61).
#
# A usage error is deliberately NOT a per-id failure. `move 1,2,3 bogus-status`
# is wrong for every id at once, so it aborts the batch untouched and keeps its
# exit code of 2 (ticket #54's rule): collecting it would report the same
# message once per id and demote the exit code to 1, which is precisely the
# distinction the exit-code contract exists to make. The markers come from
# App::karr::Error rather than a second copy of bin/karr's list, so a new marker
# on either side cannot silently reclassify a batch.
sub run_batch {
    my ($self, $ids, $per_id) = @_;

    my @results;
    my $failed = 0;

    for my $id (@$ids) {
        my @out;
        my $err = do {
            local $@;
            eval { @out = $per_id->($id); 1 } ? undef : ( $@ || 'unknown error' );
        };

        if ( defined $err ) {
            die $err if App::karr::Error::is_usage_error($err);
            $failed++;
            my $line = App::karr::Error::clean_error($err);
            # A suggestion block (App::karr::Error/command_hint) belongs to the
            # STDERR text a person or an agent reads off the terminal, not to
            # the --json payload: `error` has been exactly one line for as long
            # as it has existed, and a reader of it is scripting this CLI
            # already and has no use for a shell line to copy (ticket k263).
            my ($json_line) = split /\n/, $line, 2;
            # The colon on the prose line is there to introduce the suggestion.
            # With the suggestion gone it introduces nothing, so it goes too.
            $json_line =~ s/:\z// unless $json_line eq $line;
            # The id is echoed as a number when it is one, so an agent reading
            # --json gets the same type it passed in -- and a non-numeric id
            # does not add "Argument isn't numeric" to the diagnosis of what is
            # already an error.
            push @results,
              { id => ( $id =~ /\A[0-9]+\z/ ? $id + 0 : $id ), error => $json_line };
            warn "$line\n" unless $self->json;
            next;
        }

        push @results, @out;
    }

    return ( \@results, $failed );
}


sub report_batch_failure {
    my ($self, $failed, $total) = @_;
    return 0 unless $failed;
    # After the successful ids are committed and pushed, never instead of them.
    # A die rather than an exit: bin/karr's handler turns it into the 1 the
    # contract calls for, and an in-process caller gets an exception instead of
    # having its interpreter shot out from under it.
    App::karr::Error::user_error( sprintf '%d of %d ids failed', $failed, $total );
}


# The canonical location of a task. BoardStore and App::karr::Git build the
# same string; this role needs it directly because it reads the OID and the
# content together (App::karr::Git::read_ref_with_oid), which is the pair a
# compare-and-swap has to guard against, and no BoardStore method hands both
# back.
sub _task_data_ref {
    my ($self, $id) = @_;
    return "refs/karr/tasks/$id/data";
}

# The one way a callback can say "there is nothing here to write". A
# package-lexical scalar ref, compared by address, because the callbacks on
# this path return whatever their last statement happened to evaluate to -- a
# title, a status, the result of a clearer -- and no value a caller can
# construct by accident is this one.
#
# The address is read with Scalar::Util::refaddr, which is how identity is
# asked in this distribution (App::karr::SyncGuard keys its registry of armed
# guards the same way). It also settles the overloading question instead of
# stepping around it: refaddr returns the address itself and never consults an
# overloaded `==`, so a blessed return value cannot be asked a comparison it
# would answer with an exception.
my $NO_CHANGE = \do { my $sentinel = 'no change' };

sub no_change { return $NO_CHANGE }


# One spelling of "this id names no card" for every command on the mutation
# path (ticket k264). update_task_guarded and delete_task_guarded raise it when
# the ref is gone; archive and delete raise the same off the unguarded pre-read
# they take before the guard (Cmd::Archive, Cmd::Delete), so move, edit, delete,
# archive and handoff can never disagree on the wording -- the drift k263 warned
# about when it unified "No karr board found" across five commands. The id is
# real and only `karr list --compact` follows it, carrying no placeholder, so
# the suggestion is always printed (the shape `karr needs` got in k263). The
# trailing newline is here so a `die` honours it and Carp appends no call site.
sub task_not_found {
    my ($self, $id) = @_;
    return "Task $id not found on this board:\n"
        . App::karr::Error::command_hint('list', '--compact') . "\n";
}


sub update_task_guarded {
    my ($self, $id, $mutate) = @_;
    my $git = $self->git;
    my $ref = $self->_task_data_ref($id);

    return $git->retry_contended( "task $id", sub {
        my ( $oid, $content ) = $git->read_ref_with_oid($ref);
        die $self->task_not_found($id) unless defined $oid && length $content;

        my $task = App::karr::Task->from_string( $content,
            repair_frontmatter => $git->board_is_legacy_encoded );

        my $verdict = $mutate->($task);

        # A callback that found nothing to change gets no write: `updated` is
        # stamped by the write (App::karr::BoardStore/save_task_cas) and the
        # activity log hangs off it, so a command that changed nothing and
        # wrote anyway moved the one field the foundation drain reads to tell a
        # stuck card from a worked one, and put an entry in the log for an
        # event that did not happen (#231). Returning the task rather than ()
        # ends the retry loop: () means "another agent got in first, read again",
        # and nothing here lost a race.
        return $task
          if ref $verdict
          && Scalar::Util::refaddr($verdict) == Scalar::Util::refaddr($NO_CHANGE);

        # Through the role's own door rather than straight at write_ref_cas:
        # BoardAccess::save_task is where the `updated` bump and the activity
        # log entry live for every command write, guarded or not, and reaching
        # past it is what dropped move and edit out of `karr log` (#64).
        return () unless $self->save_task( $task, $oid );
        return $task;
    } );
}


# The same shape as update_task_guarded, and for the same reason: the claim rule
# is applied to the revision the delete is guarded against, so the two can never
# be about different bytes.
#
# This used to re-read the task and delete by name, because karr had no guarded
# delete to reach for -- App::karr::Git::delete_ref goes through libgit2's
# git_reference_remove(repo, name), which takes no expected-old OID. Re-reading
# closed the window that can stay open for minutes behind a confirmation prompt
# and left the microseconds between the read and the remove, in which a claim
# landing on the card was deleted along with it. App::karr::Git::delete_ref_cas
# closes that one too (#94).
sub delete_task_guarded {
    my ($self, $id, $claimant) = @_;
    my $git = $self->git;
    my $ref = $self->_task_data_ref($id);

    my $task = $git->retry_contended( "task $id", sub {
        my ( $oid, $content ) = $git->read_ref_with_oid($ref);
        die $self->task_not_found($id) unless defined $oid && length $content;

        my $found = App::karr::Task->from_string( $content,
            repair_frontmatter => $git->board_is_legacy_encoded );
        $self->check_claim( $found, $claimant );

        return () unless $git->delete_ref_cas( $ref, $oid );
        return $found;
    } );

    # L<App::karr::Role::BoardAccess/delete_task> is the activity-log funnel for
    # the unguarded path; this one writes the ref itself, so it records the same
    # entry rather than going without one (#64).
    $self->log_task_write($id);
    return $task;
}


# One status-change path, because there used to be two: `karr move` enforced
# require_claim and stamped the lifecycle dates, while `karr edit --status` just
# assigned the field. So `edit --status in-progress` quietly bought what `move
# 1 in-progress` refused to sell, and require_claim -- the guarantee karr's
# whole multi-agent coordination rests on -- was one flag away from being
# optional (ticket #55).
#
# The require_claim condition is move's, unchanged: a claim passed on the
# command line satisfies it, and so does a claim the task already carries.
#
# Being the one status-change path, this is also where the status *name* is
# checked (ticket #54) and where the lifecycle stamps are maintained (ticket
# #68) -- both for `move` and for `edit --status`.
sub apply_status_change {
    my ($self, $task, $new_status, $claimant) = @_;

    # First, so a batch dies on its first id having written nothing: the check
    # runs inside update_task_guarded's callback, and a die there means the
    # compare-and-swap write is never reached. `move 1 ZZZ` and `edit 1
    # --status ZZZ` used to exit 0 and park the task in a column that does not
    # exist -- invisible on `karr board`, still in the total, and fatal to the
    # next `karr move --next`.
    my $config = App::karr::Config->from_merged( $self->store->effective_config );
    $config->validate_status($new_status);

    my $old_status = $task->status;

    # A status change to the status the card already has changes nothing, so
    # nothing below it runs and nothing is written. kanban-md answers the same
    # way (internal/board/mutate.go:101-104), `karr archive` already answers it
    # one command over for an archived card, and ADR 0002 files that shape --
    # "no-ops like re-archiving an archived task" -- under exit 0. What made it
    # worth fixing is what the write cost: `updated` is stamped by every write
    # (App::karr::BoardStore/save_task_cas) and the activity log hangs off the
    # same door, so `karr move 5 backlog` on a card already in backlog moved
    # the field karr-foundation's drain reads to tell a stuck card from a
    # worked one, and logged a move that never happened (#231).
    #
    # In front of the #224 release rather than behind it, and that is free
    # rather than a compromise: the release fires on terminal -> non-terminal,
    # and $old_status eq $new_status makes both sides of that pair the same
    # status, so the condition is unsatisfiable here whatever the card carries.
    # `move ID done` on a done card holding a claim released nothing before
    # this line existed either -- done -> done is terminal to terminal, where
    # #223 keeps the name as provenance.
    #
    # What it does skip is require_claim and the dependency check. Deliberately,
    # and the same order kanban-md uses: a card that is already in a
    # require_claim column with no owner was not put there by a command that
    # declines to move it, and what a card waits for is worth saying to whoever
    # takes it up, not to a command that leaves it exactly where it was. A
    # caller that brings a claim of its own is not this case at all -- writing
    # claimed_by/claimed_at is a change -- and App::karr::Cmd::Move decides that
    # before it ever gets here.
    return $old_status if $new_status eq $old_status;

    # Reopening releases the claim. A claim is the lease an agent holds *while
    # working* a card (CONTEXT.md, Language); reaching a terminal status
    # releases it and leaves claimed_by behind as provenance, which is why
    # `karr board` prints no claimant on a finished card and check_claim lets
    # every command through one (ticket #223). Nothing ever took the field off
    # again, so the moment the card left that status the same bytes were a live
    # lease once more, held by whoever had finished the work rather than by
    # anyone doing it: the card sat in todo, `karr list` called it open work,
    # `karr board` counted it as claimed, and `karr pick` skipped it without a
    # word -- on a board whose only card that was, a drain run was told "no
    # available tasks" while the board showed work waiting (ticket #224).
    #
    # Three conditions, none of them decoration:
    #
    #   * out of a terminal status, into a non-terminal one. `done` ->
    #     `archived` is terminal to terminal and keeps the name, because
    #     archiving does not resume the work -- the provenance #223 kept is
    #     exactly what would be thrown away here.
    #
    #   * no claimant from the caller. `move ID todo --claim beta-two` and
    #     every `handoff` (where --claim is required) hand the card to a named
    #     agent, and that name wins; only a reopen that names nobody leaves the
    #     card unheld.
    #
    #   * terminal is this board's word, from App::karr::Config, never the
    #     literal `done` -- the same config object update_timestamps is handed
    #     below, so a board that ends in `shipped` releases there and nowhere
    #     else (tickets #67, #223).
    #
    # Before the require_claim check below rather than after it, for the reason
    # ticket #150 spelled out for `edit --release`: a released claim that still
    # satisfies require_claim on its way out would land the card in a column
    # the board says needs an owner with no owner on it. So `move ID
    # in-progress` off a finished card now asks for --claim instead of quietly
    # handing the column to the agent that had finished the work.
    #
    # claimed_at goes with claimed_by: on its own it is the age of a lease
    # nobody holds, and it is the timestamp `karr pick` and check_claim measure
    # expiry against.
    if ( $config->is_terminal_status($old_status)
        && !$config->is_terminal_status($new_status)
        && !( defined $claimant && length $claimant ) )
    {
        $task->clear_claimed_by;
        $task->clear_claimed_at;
    }

    # "requires a claim", not "requires --claim": naming the option said nothing
    # about a value following it, and the agent in ticket k263 read it, typed
    # `--claim` bare, and collected a second error for its trouble. The line
    # under it is the whole invocation that would have worked, built from the id
    # and the status this call already has -- see claim_hint_tokens for why the
    # command name comes from the consumer.
    App::karr::Error::user_error(
        App::karr::Error::require_claim_message(
            $new_status, $self->claim_hint_tokens( $task, $new_status ) ) )
        if $self->store->status_requires_claim($new_status)
        && !( defined $claimant && length $claimant )
        && !$task->has_claimed_by;

    # Being the one status-change path is also what makes this the one place
    # `depends_on` has to be consulted: move, edit --status, handoff and archive
    # all arrive here, so none of them can be the door that forgets to ask
    # (ticket #123). Recorded, not printed -- this runs inside
    # update_task_guarded's callback, which re-runs on contention, so the
    # emitting is left to dependency_report after the write has landed.
    $self->check_dependencies( $task, $new_status );

    $task->status($new_status);
    # The lifecycle rules themselves live on the task, mirroring kanban-md's
    # internal/task/lifecycle.go: `started` on the first move out of the first
    # configured status, `completed` on any terminal status, and `completed`
    # cleared again when a task is reopened.
    #
    # The board's own config goes with it, so "terminal" means this board's
    # last column and not the literal `done`: on a board that ends in
    # `shipped`, move/edit/archive/handoff recorded no completion at all
    # (left over from ticket #67).
    $task->update_timestamps( $old_status, $new_status, ( $config->statuses )[0],
        $config );

    return $old_status;
}


sub claim_hint_tokens {
    my ( $self, $task, $status ) = @_;
    return ( 'edit', $task->id, '--status', $status, '--claim', 'NAME' );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::TaskMutation - The one guarded path for changing an existing task

=head1 VERSION

version 0.601

=head1 DESCRIPTION

Commands that change a task that already exists -- C<move>, C<edit>, C<delete>,
C<archive>, C<handoff> -- share three things through this role: the
compare-and-swap loop that persists the change, the single implementation of
"this task's status becomes that", and the batch loop the id-list commands run
that pair over.

Claim ownership is checked by the caller, inside the callback it hands to
C<update_task_guarded>, rather than by C<update_task_guarded> itself, because
C<edit --release> deliberately acts on somebody else's claim. Putting the check
in the callback is what keeps it under the same guard as the write: a check
made before the loop is a check made against a revision that may no longer be
there (tickets #44, #46, #56).

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Role::ClaimTimeout>,
L<App::karr::Cmd::Move>, L<App::karr::Cmd::Edit>, L<App::karr::Cmd::Delete>,
L<App::karr::Cmd::Archive>, L<App::karr::Cmd::Handoff>

=head2 run_batch

Runs one callback per id and keeps going when an id fails, so that a bad id in
the middle of the list cannot skip the ids after it. Returns the collected
per-id results and the number of failures.

    my ( $results, $failed ) = $self->run_batch( \@ids, sub {
        my ($id) = @_;
        ...
        return { id => $id, title => $title };
    } );

Whatever the callback returns is appended to the results; a callback that dies
contributes C<< { id => $id, error => $message } >> instead and the message is
also warned to STDERR unless C<--json> is in force. The STDERR text carries any
suggestion line the failure came with (L<App::karr::Error/command_hint>); the
C<error> field stays the single line it has always been. Usage errors are
re-thrown rather than collected: they condemn the whole invocation, not one id.

=head2 report_batch_failure

    $self->report_batch_failure( $failed, scalar @ids );

Ends a batch that had failures with exit code 1 and a one-line summary, after
the ids that did succeed have been committed. A no-op when nothing failed.

=head2 no_change

    return $self->no_change if $task->status eq $wanted;

The value a L</update_task_guarded> callback returns to say that this revision
of the task needs no write: the compare-and-swap write, the C<updated> bump
that comes with it and the activity-log entry are all skipped, and the task is
returned unwritten. Any other return value -- including none -- writes as
before, so a callback that does not know about this method is unaffected.

Deciding it inside the callback rather than on a read taken beforehand is the
point (tickets #44, #46, #56): "nothing to change" is a statement about a
revision, and the revision it is made about is the one that would have been
written.

=head2 task_not_found

    die $self->task_not_found($id);

The one message every command on the mutation path raises when an id names no
card: the id as the caller gave it, and C<karr list --compact> on its own last
line as the way to see the ids that do exist. Shared so that C<move>, C<edit>,
C<delete>, C<archive> and C<handoff> -- which reach it through
L</update_task_guarded>, L</delete_task_guarded> and the unguarded pre-reads in
L<App::karr::Cmd::Archive> and L<App::karr::Cmd::Delete> -- spell it one way
(ticket k264, the shape L<App::karr::Cmd::Needs> got in k263).

=head2 update_task_guarded

Reads the task, runs the callback against it, and writes it back only if the
task ref is still exactly where it was when it was read. If another agent got
in first the callback's work is discarded and the callback is re-run against
the fresh task, so the decision it makes and the bytes that land are always the
same revision. Returns the written task.

    my $task = $self->update_task_guarded( $id, sub {
        my ($task) = @_;
        $self->check_claim( $task, $self->claim );
        $task->title('New title');
    } );

The callback runs once per attempt, so it must be a function of the task it is
handed -- read C<< $task->status >>, never a status captured beforehand -- and
anything it does besides changing that task has to be safe to do twice. A side
effect outside the task object is allowed where a repeat B<replaces> it instead
of adding to it: L</apply_status_change> calls
L<App::karr::Role::DependencyCheck/check_dependencies>, which records into a slot
keyed by task id and clears that slot on entry, so what a losing attempt wrote is
overwritten by the attempt that wins rather than added to. Appending to a list,
incrementing a counter or printing would each have come out once per attempt --
printing is why the dependency warnings are emitted by
L<App::karr::Role::DependencyCheck/dependency_report> once the write has landed,
and never from inside the callback.

=head2 delete_task_guarded

Deletes a task, but only if the task ref is still exactly where it was when the
claim rule was applied to it. If another agent got in first the check is re-run
against the fresh task -- so a claim that lands in the window blocks the delete
instead of being deleted with the card -- and a task another agent deleted
meanwhile is reported as not found. Returns the deleted task.

    $self->delete_task_guarded( $id, undef );

=head2 apply_status_change

The only place a task's status is assigned. Rejects a status the board does not
configure, releases the claim on a reopen, applies C<require_claim> and the
lifecycle stamps, records any unsatisfied dependencies
(L<App::karr::Role::DependencyCheck/check_dependencies> -- recorded here,
emitted by the caller once the write has landed), and returns the status the
task had before the change.

    my $old_status = $self->apply_status_change( $task, 'in-progress', $claimant );

A change to the status the card already carries changes nothing: the status
name is still checked, and then this returns that same status having touched
neither the card nor its claim -- so C<require_claim>, the dependency check and
the lifecycle stamps are all skipped along with it (ticket #231, the shape
kanban-md's C<Move> uses). Callers that write only because of the status change
-- L<App::karr::Cmd::Move> -- recognise it and skip the write, so C<updated> is
not bumped and no activity-log entry is appended for an event that did not
happen. A caller that changes something else in the same breath, C<edit
--title> or C<move --claim>, still writes what it changed.

Reopening releases the claim. A card leaving one of the board's terminal
statuses (L<App::karr::Config/is_terminal_status>) for a non-terminal one, with
no C<$claimant> passed in, has C<claimed_by> and C<claimed_at> cleared: a claim
is the lease an agent holds while working a card, and the name kept on a
finished one is provenance, not a lease to carry back into a working column.
Left there, it blocked every other agent and made C<karr pick> skip the card in
silence (ticket #224).

Three things it deliberately does not do. C<done> -> C<archived> is terminal to
terminal and keeps the name. A caller that brings a claimant -- C<move ID todo
--claim NAME>, and every C<handoff>, where C<--claim> is required -- hands the
card to that agent instead. And "terminal" is whatever this board's config
calls terminal, never the literal C<done>.

The release happens B<before> the C<require_claim> check, so a claim on its way
off the card cannot satisfy it: reopening straight into a column the board says
needs an owner asks for C<--claim> rather than handing that column to whoever
had finished the work (the shape of ticket #150).

=head2 claim_hint_tokens

    my @tokens = $self->claim_hint_tokens( $task, 'in-progress' );

The words after C<karr> in the suggestion C<apply_status_change> prints when a
status needs a claim and none is on the card. A hook, because the message is
raised here and only the consumer knows which command the caller actually typed.

The default is C<< karr edit ID --status STATUS --claim NAME >>, which is right
for every consumer that reaches a require_claim column through an option rather
than a positional -- L<App::karr::Cmd::Edit>, and L<App::karr::Cmd::Archive>,
which has no C<--claim> of its own to offer. L<App::karr::Cmd::Move> overrides
it with its own spelling. L<App::karr::Cmd::Handoff> never gets here: C<--claim>
is required on that command, so the check above is always satisfied.

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
