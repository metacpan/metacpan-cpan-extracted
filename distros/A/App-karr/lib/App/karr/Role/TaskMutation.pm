# ABSTRACT: The one guarded path for changing an existing task

package App::karr::Role::TaskMutation;
our $VERSION = '0.500';
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
            # The id is echoed as a number when it is one, so an agent reading
            # --json gets the same type it passed in -- and a non-numeric id
            # does not add "Argument isn't numeric" to the diagnosis of what is
            # already an error.
            push @results,
              { id => ( $id =~ /\A[0-9]+\z/ ? $id + 0 : $id ), error => $line };
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

sub update_task_guarded {
    my ($self, $id, $mutate) = @_;
    my $git = $self->git;
    my $ref = $self->_task_data_ref($id);

    return $git->retry_contended( "task $id", sub {
        my ( $oid, $content ) = $git->read_ref_with_oid($ref);
        die "Task $id not found\n" unless defined $oid && length $content;

        my $task = App::karr::Task->from_string( $content,
            repair_frontmatter => $git->board_is_legacy_encoded );

        $mutate->($task);

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
        die "Task $id not found\n" unless defined $oid && length $content;

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

    die "Status '$new_status' requires --claim\n"
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

    my $old_status = $task->status;
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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::TaskMutation - The one guarded path for changing an existing task

=head1 VERSION

version 0.500

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
also warned to STDERR unless C<--json> is in force. Usage errors are re-thrown
rather than collected: they condemn the whole invocation, not one id.

=head2 report_batch_failure

    $self->report_batch_failure( $failed, scalar @ids );

Ends a batch that had failures with exit code 1 and a one-line summary, after
the ids that did succeed have been committed. A no-op when nothing failed.

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
configure, applies C<require_claim> and the lifecycle stamps, records any
unsatisfied dependencies (L<App::karr::Role::DependencyCheck/check_dependencies>
-- recorded here, emitted by the caller once the write has landed), and returns
the status the task had before the change.

    my $old_status = $self->apply_status_change( $task, 'in-progress', $claimant );

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
