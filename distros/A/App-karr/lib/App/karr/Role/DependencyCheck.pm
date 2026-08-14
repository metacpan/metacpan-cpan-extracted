# ABSTRACT: Warn when a card is taken up while its dependencies are unfinished

package App::karr::Role::DependencyCheck;
our $VERSION = '0.500';
use Moo::Role;

# What this role calls on its consumer, said out loud (ticket #128). It used to
# declare nothing, and got away with it only because every consumer happened to
# compose the roles that supply these: store from
# App::karr::Role::BoardDiscovery, find_task from App::karr::Role::BoardAccess,
# json from App::karr::Role::Output, quiet from
# App::karr::Role::SyncLifecycle. App::karr::Role::TaskMutation composes this
# role, so the next command to reach for the mutation path would have inherited
# methods whose collaborators nobody had checked for -- and found out at the
# moment a warning was due, as a "Can't locate object method", rather than at
# compile time.
#
# json is on the list since ticket #137 split the set-time helpers off into
# App::karr::Role::DependencyArgs. It could not be until then: this role also
# carried parse_dependency_ids and assert_dependencies_exist, and the command
# that composed it for those two alone -- create -- has no --json, so requiring
# json refused a consumer that never reaches the reporting half. Leaving it out
# was the narrower hole rather than none: `$self->json || $self->quiet`
# evaluates json first and unconditionally, so a consumer missing it broke on
# every warning, not only the ones without --json.
requires qw( store find_task json quiet );


# Keyed by task id rather than a flat list, because check_dependencies runs
# inside a compare-and-swap callback that re-runs when another agent gets in
# first (App::karr::Role::TaskMutation/update_task_guarded,
# App::karr::Cmd::Pick/_claim_under_lock). A list would grow one copy of every
# warning per attempt; a keyed slot is replaced by the attempt that wins.
has _dependency_warnings => (
    is      => 'ro',
    default => sub { {} },
);

sub check_dependencies {
    my ( $self, $task, $new_status ) = @_;

    my $id = $task->id;
    delete $self->_dependency_warnings->{$id};

    # A move into a terminal status is not taking work up, it is finishing it,
    # and what a finished card was once waiting for is no longer anybody's
    # decision to make. The board's own statuses answer this, not done/archived
    # (tickets #67, #98).
    return () if $self->store->is_terminal_status($new_status);

    my @deps = @{ $task->depends_on };
    return () unless @deps;

    my @warnings;
    for my $dep_id (@deps) {
        my $dep = $self->find_task($dep_id);

        # A deliberate divergence from the reference. kanban-md treats an id
        # that is not on the board as *satisfied*
        # (internal/board/filter.go:151-154): "Missing dependency IDs can occur
        # after legacy hard-deletes. Treat as satisfied so dependents are
        # recoverable via edit/cleanup." That reasoning is about not stranding a
        # card, and it is sound there, where an unsatisfied dependency makes the
        # card unpickable. Here nothing is blocked, so there is no card to
        # strand -- and a dependency pointing at an id that does not exist is
        # exactly the kind of thing whoever is about to start work wants told.
        if ( !$dep ) {
            push @warnings, sprintf
              'Warning: task %s depends on task %s, which does not exist on this board',
              $id, $dep_id;
            next;
        }

        next if $self->store->is_terminal_status( $dep->status );
        push @warnings, sprintf
          'Warning: task %s depends on task %s, which is still %s',
          $id, $dep_id, $dep->status;
    }

    $self->_dependency_warnings->{$id} = \@warnings if @warnings;
    return @warnings;
}


sub dependency_report {
    my ( $self, $id ) = @_;

    my $warnings = $self->_dependency_warnings->{$id};
    return () unless $warnings && @$warnings;

    print STDERR map { "$_\n" } @$warnings
      unless $self->json || $self->quiet;

    return ( dependency_warnings => $warnings );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::DependencyCheck - Warn when a card is taken up while its dependencies are unfinished

=head1 VERSION

version 0.500

=head1 DESCRIPTION

C<depends_on> was stored, round-tripped and written into the frontmatter by
L<App::karr::Task> long before anything read it. That is worse than a missing
feature: a card recording C<< depends_on: [5] >> looked as though karr would
hold it back until 5 was finished -- the field was accepted, kept and
materialized -- while C<move>, C<edit --status> and C<pick> handed it out with
no word said (ticket #123).

This role is what reads it. Taking a card up with unsatisfied dependencies
B<proceeds and exits 0>, but says so. "Taking up" is a status change into a
non-terminal status, and on C<pick> it is also the claim itself -- an agent
that runs C<< karr pick --claim X >> holds the card and starts on it whether
or not a C<--move> came with it.

Consumed by L<App::karr::Role::TaskMutation>, so every command that changes a
status through C<apply_status_change> is covered by the one call there, and
directly by L<App::karr::Cmd::Pick>, which has its own compare-and-swap loop
and does not go through that path.

Setting the field is the other half, and a separate role:
L<App::karr::Role::DependencyArgs> is what C<create> and C<edit> parse and
validate their dependency options with. The two were one role until ticket
#137; they are split because their contracts differ -- this half needs the
command's output options to choose a channel for the warning, that half needs
none of them and is composed by a command (C<create>) that has no C<--json>.

=head2 What counts as satisfied

A dependency in one of the board's own terminal statuses
(L<App::karr::Config/is_terminal_status>), never the literal C<done>: a board
whose final column is C<shipped> would otherwise have every finished
dependency reported as outstanding. Same rule as kanban-md's C<allDepsSatisfied>
(F<internal/board/filter.go>:148).

=head2 Which channel it comes out of

The rules L<App::karr::Role::TaskMutation/run_batch> already set for its per-id
errors, rather than a second convention: the human copy goes to STDERR so
STDOUT stays parseable, C<--json> carries the identical sentence in the result
object instead -- a JSON consumer never reads STDERR, so a warning left there
is a warning nobody sees -- and C<--quiet> silences the STDERR copy. The JSON
field is data, not chatter, so C<--quiet> does not remove it; the key is simply
absent when there is nothing to report.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Role::DependencyArgs>,
L<App::karr::Role::TaskMutation>, L<App::karr::Cmd::Pick>,
L<App::karr::Cmd::Move>, L<App::karr::Cmd::Show>, L<App::karr::Config>

=head2 check_dependencies

    $self->check_dependencies( $task, $new_status );

Records, for C<< $task->id >>, one warning per dependency that is not finished
and one per dependency naming an id the board does not have. Returns the
warnings and stashes them for L</dependency_report> to emit; it prints nothing
and changes nothing itself, which is what makes it safe to call from inside a
compare-and-swap callback that may run more than once.

A C<$new_status> that is terminal for this board, or a task with no
C<depends_on>, records nothing. Call it with the status the task is moving
B<to>, not the one it is moving from -- or, where nothing is moving and the
card is merely being taken up (C<< karr pick --claim >> with no C<--move>),
with the status it stays in.

=head2 dependency_report

    return { id => $task->id, ..., $self->dependency_report( $task->id ) };

Emits whatever L</check_dependencies> recorded for C<$id> and returns it as the
C<< dependency_warnings => \@warnings >> pair for the command's C<--json>
payload, or the empty list when there is nothing to report -- so the key is
absent rather than an empty array a consumer would have to test the length of.

Emitting and reporting are one call on purpose: they are the same warning on
two channels, and splitting them is how the two drift apart. STDERR is skipped
under C<--json> (where the pair carries it) and under C<--quiet>.

Call it after the write has landed, never from inside the guarded callback: a
warning about a move that then lost its compare-and-swap is a warning about
something that did not happen.

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
