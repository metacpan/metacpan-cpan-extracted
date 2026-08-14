# ABSTRACT: Role providing board discovery, sync lifecycle, and task access

package App::karr::Role::BoardAccess;
our $VERSION = '0.500';
use Moo::Role;
use App::karr::Role::CliArgs;
use App::karr::ActivityLog;

with 'App::karr::Role::BoardDiscovery';
with 'App::karr::Role::SyncLifecycle';
with 'App::karr::Role::CliArgs';


# Guards against logging one mutation twice within a single command run: pick
# saves the task (logged here) and then calls append_log itself.
has _logged_writes => (
    is      => 'ro',
    default => sub { {} },
);

sub load_tasks {
    my ($self) = @_;
    return $self->store->load_tasks;
}


sub find_task {
    my ($self, $id) = @_;
    return $self->store->find_task($id);
}


sub save_task {
    my ( $self, $task, $expected_oid ) = @_;
    # One door, guarded or not, so the activity log has exactly one place to
    # hang off. Handed the OID the card was read from (find_task_with_oid /
    # read_ref_with_oid) this is a compare-and-swap and returns false when
    # another agent got there first -- the caller re-reads and decides again,
    # and a write that never landed is never logged. Splitting the guarded path
    # off into its own method is what let move/edit/pick slip out of the log
    # once App::karr::Role::TaskMutation arrived (#64 again).
    my $wrote = @_ > 2
        ? $self->store->save_task_cas( $task, $expected_oid )
        : $self->store->save_task($task);
    return $wrote unless $wrote;
    $self->log_task_write( $task->id, $task->status, $task );
    return $wrote;
}


sub delete_task {
    my ($self, $id) = @_;
    # The same guard save_task has, for the same reason. The log answers what
    # happened to this board, and App::karr::BoardStore::delete_task returns
    # false when nothing was removed -- the id was never there, or the delete
    # itself failed. Logging that wrote an entry `karr log` and `karr show --me`
    # then reported as a delete that happened (#64 gave them this log, #120
    # found the two doors disagreeing). An entry cannot say "attempted": it
    # carries agent, action and task id, so an attempt is indistinguishable from
    # a real delete, and a false entry is worse than a missing one. The guarded
    # twin, App::karr::Role::TaskMutation::delete_task_guarded, already dies on
    # a missing id before it logs, so all three write paths agree now.
    my $result = $self->store->delete_task($id);
    return $result unless $result;
    $self->log_task_write($id);
    return $result;
}


sub allocate_next_id {
    my ($self) = @_;
    return $self->store->allocate_next_id;
}


sub parse_ids {
    my ($self, $id_str) = @_;
    return split /,/, $id_str;
}


sub activity_log {
    my ($self, $git) = @_;
    $git //= $self->git;
    return App::karr::ActivityLog->new(git => $git, role => $self->role);
}


sub append_log {
    my ($self, $git, %entry) = @_;
    my $key = ($entry{action} // '') . ':' . ($entry{task_id} // '');
    return 0 if $self->_logged_writes->{$key}++;
    return $self->activity_log($git)->log_entry(%entry);
}



sub log_action {
    my ($self) = @_;
    my $name = ref($self) || $self;
    $name =~ s/.*:://;
    $name =~ s/(?<=[a-z0-9])([A-Z])/-$1/g;
    return lc $name;
}


sub log_agent {
    my ($self, $task) = @_;
    if ($self->can('claim')) {
        my $claim = $self->claim;
        return $claim if defined $claim && length $claim;
    }
    return $task->claimed_by if $task && $task->has_claimed_by;
    my $git = $self->git;
    return $git->git_user_name || $git->git_user_email || 'unknown';
}


sub log_task_write {
    my ($self, $task_id, $detail, $task) = @_;
    my $action = $self->log_action;
    return 0 if $self->_logged_writes->{"$action:$task_id"}++;
    return $self->activity_log->log_entry(
        agent   => $self->log_agent($task),
        action  => $action,
        task_id => $task_id + 0,
        ( defined $detail ? ( detail => $detail ) : () ),
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::BoardAccess - Role providing board discovery, sync lifecycle, and task access

=head1 VERSION

version 0.500

=head1 DESCRIPTION

This role composes L<Role::BoardDiscovery> and L<Role::SyncLifecycle> and
adds task-access methods that delegate to the store. Commands compose this role
for full board functionality.

All task operations work directly against refs via C<< $self->store->load_tasks() >>
and similar. No temporary directory is created.

=head2 Activity logging

C<save_task> and C<delete_task> are the two doors a command changes a task
through, guarded writes included, so they are also where the activity log is
written. A command is recorded because it wrote, not because it remembered to
call C<append_log> -- before that, C<pick> was the only command that
remembered, and C<karr log> and C<karr show --me> ran on an almost empty log
(#64).

Every command write goes through one of the two, which is the point:
L<App::karr::Role::TaskMutation> and C<pick> hand their compare-and-swap
through C<save_task>'s optional expected-OID argument instead of reaching past
it to L<App::karr::BoardStore/save_task_cas>, so there is no second write path
to keep in step.

The action name comes from the command class (L</log_action>) and the actor
from its C<--claim>, the task's holder, or the Git identity (L</log_agent>).
Bulk paths that deliberately reinstate state verbatim -- C<import>, C<restore>,
C<repair> -- reach L<App::karr::BoardStore> directly and stay unlogged.

=head2 load_tasks

    my @tasks = $self->load_tasks;

In a command class that composes this role, returns every task on the board
as L<App::karr::Task> objects, in no particular order. A ref left behind by a
crashed C<pick> (e.g. an orphaned lock with no data ref) is silently excluded
rather than surfaced as C<undef> in the list -- see
L<App::karr::BoardStore/load_tasks>.

=head2 find_task

    my $task = $self->find_task($id);

In a command class that composes this role, looks up one task by id and
returns the L<App::karr::Task>, or C<undef> if no task with that id exists.
It does not die on a missing id -- callers that need a hard failure (most of
them) check the return value themselves, e.g. C<< $self->find_task($id) or
die "Task $id not found\n" >>.

=head2 save_task

    $self->save_task($task);                    # unguarded
    $self->save_task($task, $expected_oid);      # compare-and-swap

In a command class that composes this role, writes a task and records the
activity-log entry for it -- the only door a write goes through that also
logs. With two arguments the write is unconditional; with a third it is a
compare-and-swap against C<$expected_oid> (the OID L<App::karr::BoardStore
/find_task_with_oid> read the task from) and returns false, without writing
or logging, if another agent has moved the ref since. The guarded form is
what L<App::karr::Role::TaskMutation/update_task_guarded> and C<pick> use
instead of reaching past this method to C<save_task_cas> directly, so there
is exactly one write path to keep the log in step with.

=head2 delete_task

    my $ok = $self->delete_task($id);

In a command class that composes this role, deletes a task's ref and records
the activity-log entry for it, mirroring L</save_task> as the other of the
two doors a command writes through. Returns whatever
L<App::karr::BoardStore/delete_task> returns, and logs only when that is
true: a delete of an id that was never there removes nothing, so it leaves no
entry behind, exactly as C<save_task> leaves none for a write that lost its
compare-and-swap (#120).

=head2 allocate_next_id

    my $id = $self->allocate_next_id;

In a command class that composes this role, reserves and returns the next
free task id, delegating to L<App::karr::BoardStore/allocate_next_id>. The
allocation is a compare-and-swap on the board's counter ref, so two agents
running C<karr create> at the same time are always handed different ids.

=head2 parse_ids

    my @ids = $self->parse_ids('1,2,3');   # (1, 2, 3)
    my @ids = $self->parse_ids('7');       # (7)

In a command class that composes this role, splits the comma-separated id
argument every batch-capable command (C<move>, C<edit>, C<delete>,
C<archive>, C<unlock>) takes on its single positional and returns the ids in
order, unvalidated and as plain strings. There is no range syntax (C<1-3>)
and no whitespace handling; an empty string returns an empty list. Whether
each id actually names a task is left to the per-id callback each command
runs via L<App::karr::Role::TaskMutation/run_batch>.

=head2 activity_log

    my $log = $self->activity_log;              # this command's own git/role
    my $log = $self->activity_log($other_git);   # a different repo

In a command class that composes this role, builds an L<App::karr::ActivityLog>
for C<$git> (defaulting to C<< $self->git >>) and this command's C<role>. Most
callers use it to read (C<< $self->activity_log->entries >>); writing a mutation
normally happens through L</save_task> or L</delete_task> instead of this
method directly -- see L</Activity logging> above.

=head2 append_log

    $self->append_log($self->git,
        agent   => $self->claim,
        action  => 'pick',
        task_id => $picked->id,
        detail  => $picked->status,
    );

In a command class that composes this role, writes one activity-log entry.
Unlike L</save_task> and L</delete_task>, this is never called automatically
by a write -- a command is recorded because it wrote through one of those two
doors, or because it called C<append_log> itself, as C<pick> does here for
the claim it takes outside the guarded save. C<$git> is required (no default)
and C<%entry> is handed to L<App::karr::ActivityLog/log_entry> unchanged.
Guarded against double-logging the same C<action>/C<task_id> pair within one
command run, the same guard L</log_task_write> uses.

=head2 log_action

The action name recorded for this command's writes: the class's own name
segment, hyphenated (C<App::karr::Cmd::AgentName> gives C<agent-name>). Naming
the action after the command is what lets a new mutating command be logged
without opting in.

=head2 log_agent

Who a log entry is attributed to: this command's C<--claim> if it takes one,
else whoever holds the task, else the Git identity behind the board.

=head2 log_task_write

    $self->log_task_write( $task->id, $task->status, $task );

Records one task mutation in the activity log. Called by C<save_task> and
C<delete_task>; at most one entry per action and task id per command run.

=head2 Writing the config

There is deliberately no C<save_config> on this role. Config writes go to
C<< $self->store->save_config($effective_hash) >> directly, as C<Cmd::Config>
and C<Cmd::Init> do -- unlike L</save_task> and L</delete_task>, which earn
their door by writing the activity log, a role-level wrapper would add nothing
to the store's own method.

The one this role used to carry defaulted its argument to
C<< $self->config >>, which is an L<App::karr::Config> object, while
L<App::karr::BoardStore/save_config> takes the plain effective-config hash: it
reads C<< $effective->{version} >> and diffs the whole thing against the
defaults. Handed the object it saw the C<data> and C<file> keys of the
blessed hash instead, and because that merges over the defaults into something
schema-valid, nothing refused it -- C<< $self->save_config >> wrote a
C<refs/karr/config> whose entire real content sat nested under a C<data:> key
and whose C<board.name> was gone. Nothing in F<lib/> or F<t/> ever called it,
which is the only reason no board was ever corrupted this way (#120).

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
