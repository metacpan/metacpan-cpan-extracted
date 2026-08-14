# ABSTRACT: Shared claim timeout logic

package App::karr::Role::ClaimTimeout;
our $VERSION = '0.500';
use Moo::Role;
# Loaded without importing, and every call below is qualified. A Moo::Role
# composes every sub in its package into its consumers, imported ones included,
# so `use Time::Piece;` here put its localtime/gmtime replacements on every
# command that composes this role (#105). Worse than the #38 cases, because
# those two shadow builtins: a future `sub localtime` on a command class would
# fight an inherited export and look like a core function misbehaving.
# App::karr::Role::Output and App::karr::Role::BoardDiscovery state the rule.
#
# Time::Piece is not a drop-in for that treatment -- replacing the builtins is
# its whole point -- so the two sites below were decided one at a time:
# ->strptime was already a class method and needs no import, and the gmtime in
# _claim_expired wants the overloaded object (the builtin returns a string in
# that scalar context, and the subtraction would be nonsense), so it is spelled
# Time::Piece::gmtime().
use Time::Piece ();
use App::karr::Config;

# What this role calls on its consumer, said out loud (ticket #144; the rule is
# ticket #128's, and this is the last of the three mutation-path roles to get
# it). It declared nothing at all until then, and composed cleanly into
# anything, while claim_timeout_secs reads $self->store to find the board's
# configured claim_timeout -- store being App::karr::Role::BoardDiscovery's
# attribute, which every consumer happens to bring along via
# App::karr::Role::BoardAccess. That is the accident, not the guarantee: a
# consumer without it got check_claim regardless, and would have learned about
# the gap from inside a mutation as "Can't locate object method", on the one run
# where a task was actually claimed.
#
# One name, not more. The other four calls in this file -- _parse_timeout,
# _parse_claim_stamp, _claim_expired, claim_timeout_secs -- are subs defined
# right here, so the consumer never supplies them; requiring one would be worse
# than redundant, since Role::Tiny installs a role's methods into the consumer
# *before* it checks the requires (role_application_steps), so the check would
# find what the composition had just put there, in every consumer, always, and
# read as a promise that had been verified when nothing had. Unlike
# App::karr::Role::TaskMutation, which composes two roles and gets check_claim
# and check_dependencies from them, this role composes nothing -- so "the role's
# own" here means only "defined in this file".
#
# $self->claim appears once more below, in the =method check_claim synopsis. It
# is an example of what a command passes in, not a call this role makes, and no
# consumer is asked for it. t/147-claim-timeout-requires.t reads the calls out
# of this source with the POD stripped for exactly that reason.
requires qw( store );


# $fallback is what an absent or unparseable value means. It defaults to an
# hour, which is right for claim_timeout but far too long for lock_timeout --
# a lock covers one pick transaction, not a work session, so App::karr::Cmd::Pick
# passes its own (see LOCK_TIMEOUT_FALLBACK there).
#
# The whole Go duration grammar, not just ^\d+[hms]$: kanban-md writes
# claim_timeout with time.ParseDuration, so an imported `1h30m` has to mean
# ninety minutes here too instead of silently collapsing to the fallback
# (ticket #78). Anything unparseable -- including "7d", which Go rejects as
# well -- falls back. An explicit zero is not a failure and is honoured: `0s`
# is how a board says "locks never expire" (see App::karr::Cmd::Unlock), and
# swapping it for the default would silently turn that off. A bare `0` with no
# unit is caught by the falsy guard above and keeps its historical fallback.
sub _parse_timeout {
    my ($self, $timeout_str, $fallback) = @_;
    $fallback //= 3600;
    return $fallback unless $timeout_str;
    my $secs = App::karr::Config->parse_duration($timeout_str);
    return $fallback unless defined $secs && $secs >= 0;
    return $secs;
}

# The board's configured claim timeout in seconds, so callers do not each have
# to remember the '1h' fallback.
sub claim_timeout_secs {
    my ($self) = @_;
    return $self->_parse_timeout( $self->store->effective_config->{claim_timeout} // '1h' );
}


# karr and kanban-md both stamp claims with RFC3339, but not the same RFC3339.
# karr writes `gmtime->datetime . 'Z'` -- no fraction, always UTC. kanban-md
# writes Go's time.RFC3339Nano off the agent's local clock, verified against the
# real binary as 2026-08-09T17:28:46.449764553+02:00.
#
# The old parse stripped a trailing "Z" and handed the rest to a bare
# '%Y-%m-%dT%H:%M:%S', so the fraction and the offset were thrown away and the
# stamp was read as if it were UTC. A claim stamped +02:00 looked two hours
# younger than it was and never expired; one stamped -05:00 looked five hours
# older and was stolen while its owner was still working. Time::Piece also
# warned "Garbage at end of string in strptime" to STDERR on every single call,
# which meant every `karr pick` next to a kanban-md agent (ticket #57).
#
# So match the whole grammar instead: drop only the fractional seconds --
# sub-second precision cannot matter against a timeout measured in minutes --
# and hand the offset to strptime's %z, which is what actually normalises to
# UTC. Time::Piece's %z wants +hhmm rather than RFC3339's +hh:mm, and does not
# know "Z" at all, so both are normalised first. A stamp with no offset is read
# as UTC, which is what karr's own writer means by it.
#
# Because the format now matches the whole string, strptime has nothing left
# over to complain about and the STDERR noise goes away with it. A stamp that
# does not match at all returns undef and is treated as "not expired", the same
# conservative answer as before: never expiring is a stuck claim, wrongly
# expiring is a stolen one.
sub _parse_claim_stamp {
    my ($self, $stamp) = @_;
    return undef unless defined $stamp;
    my ($civil, $offset) = $stamp =~ m{
        \A (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})   # civil date and time
           (?: \. \d+ )?                           # fractional seconds, dropped
           ( Z | [+-]\d{2}:?\d{2} )?               # UTC offset, or none
        \z
    }x or return undef;
    $offset = '+0000' if !defined $offset || uc($offset) eq 'Z';
    $offset =~ s/://;
    my $parsed = eval { Time::Piece->strptime( "$civil$offset", '%Y-%m-%dT%H:%M:%S%z' ) };
    return $parsed;
}

sub _claim_expired {
    my ($self, $task, $timeout_secs) = @_;
    return 0 unless $task->has_claimed_at;
    my $claimed = $self->_parse_claim_stamp( $task->claimed_at );
    return 0 unless defined $claimed;
    return (Time::Piece::gmtime() - $claimed) > $timeout_secs;
}

# The one claim-ownership rule, mirroring kanban-md's task.CheckClaim
# (internal/task/validate.go): an unclaimed task is free, the current claimant
# may always proceed, and an expired claim no longer blocks anybody. Anything
# else belongs to an agent who is still working on it, and the mutation is
# refused rather than silently taking the claim over (ticket #56).
#
# Two deliberate differences from kanban-md:
#
#   * an expired claim is not cleared here. kanban-md's CheckClaim blanks
#     ClaimedBy as a side effect of asking the question; in karr that would
#     change what the require_claim check in
#     L<App::karr::Role::TaskMutation/apply_status_change> sees a few lines
#     later, turning an allowed move into a refused one. Expired claims are
#     reaped where they always were, by `karr pick`.
#
#   * the message stays "Task N is claimed by X", the wording `karr handoff`
#     has always used, rather than kanban-md's "add --claim X" hint: `karr
#     delete` has no --claim option, so that hint would be unfollowable for one
#     of the four callers.
sub check_claim {
    my ($self, $task, $claimant) = @_;
    return 1 unless $task->has_claimed_by && length $task->claimed_by;
    return 1 if defined $claimant && length $claimant && $task->claimed_by eq $claimant;
    return 1 if $self->_claim_expired( $task, $self->claim_timeout_secs );
    die sprintf "Task %d is claimed by %s\n", $task->id, $task->claimed_by;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::ClaimTimeout - Shared claim timeout logic

=head1 VERSION

version 0.500

=head1 DESCRIPTION

Shared helper role for commands that need to interpret C<claim_timeout> values
and determine whether an existing claim should still block other agents.

C<check_claim> is the one claim-ownership rule in karr. Every command that
mutates an existing task has to apply it, and has to apply it against the same
revision of the task it then writes -- see
L<App::karr::Role::TaskMutation/update_task_guarded>.

=head2 claim_timeout_secs

    my $secs = $self->claim_timeout_secs;

In a command class that composes this role, returns the board's configured
C<claim_timeout> in seconds, parsed with the full Go C<time.ParseDuration>
grammar kanban-md writes (e.g. C<1h30m>), not just C<< ^\d+[hms]$ >>. Falls
back to one hour (3600) when the board has no C<claim_timeout> set or the
value does not parse -- except an explicit C<0s>, which is honoured verbatim
and means "claims never expire" (see C<karr unlock>). This is the timeout
L</check_claim> applies; L<App::karr::Cmd::Pick>'s lock timeout is a separate,
shorter fallback and does not go through this method.

=head2 check_claim

    $self->check_claim( $task, $self->claim );   # $self->claim may be undef

In a command class that composes this role, decides whether C<$task>'s
existing claim blocks the caller and either returns true or dies with
C<"Task N is claimed by X\n">. Four cases, checked in order:

=over 4

=item * the task is not claimed at all -- always allowed;

=item * C<$claimant> is defined, non-empty, and matches C<< $task->claimed_by
>> exactly -- the current claimant may always proceed;

=item * the claim is older than L</claim_timeout_secs> -- an expired claim no
longer blocks anyone, but is not cleared as a side effect of asking (that
stays kanban-md's behaviour, not karr's -- see the comment above this method
for why);

=item * otherwise -- the task belongs to someone still working on it, and the
call dies rather than silently taking the claim over.

=back

Call it against the same task revision the caller then writes -- see
L<App::karr::Role::TaskMutation/update_task_guarded> -- since a check made
against a stale read can pass or fail against bytes that are no longer there.

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
