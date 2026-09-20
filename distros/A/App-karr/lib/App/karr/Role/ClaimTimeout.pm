# ABSTRACT: Shared claim timeout logic

package App::karr::Role::ClaimTimeout;
our $VERSION = '0.601';
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
# Loaded without importing, for the reason spelled out in
# App::karr::Role::Output: a Moo::Role composes every sub in its package into
# its consumers, imported ones included, so `use App::karr::Error qw( ... )`
# here would quietly make those names methods on every command that composes
# this role. The refusal message is built with command_hint and original_argv,
# both called qualified below.
use App::karr::Error ();

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
# json and quiet joined store in ticket #177, when check_claim stopped being a
# pure decision and started reporting the one case it lets through silently (see
# expired_claim_report). They are the same two names
# App::karr::Role::DependencyCheck declares for the same reason, and every
# consumer of this role already has both -- App::karr::Cmd::Unlock and
# App::karr::Cmd::Pick compose App::karr::Role::Output for json and reach quiet
# through App::karr::Role::SyncLifecycle, and App::karr::Role::TaskMutation's
# five commands do too. That is what kept this a widening of the contract rather
# than the role split ticket #137 needed: there, `create` composed
# DependencyCheck for its set-time half alone and had no --json to declare.
#
# Three names, not more. The other five calls in this file -- _parse_timeout,
# _parse_claim_stamp, _claim_expired, claim_timeout_secs and the _expired_claims
# attribute -- are defined right here, so the consumer never supplies them;
# requiring one would be worse than redundant, since Role::Tiny installs a
# role's methods into the consumer *before* it checks the requires
# (role_application_steps), so the check would find what the composition had
# just put there, in every consumer, always, and read as a promise that had
# been verified when nothing had. Unlike
# App::karr::Role::TaskMutation, which composes two roles and gets check_claim
# and check_dependencies from them, this role composes nothing -- so "the role's
# own" here means only "defined in this file".
#
# $self->claim appears once more below, in the =method check_claim synopsis. It
# is an example of what a command passes in, not a call this role makes, and no
# consumer is asked for it. t/147-claim-timeout-requires.t reads the calls out
# of this source with the POD stripped for exactly that reason.
requires qw( store json quiet );


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

# Zero is not a very short window, it is the switch that turns expiry off --
# the one number here that is not read as a duration at all (ticket #232). That
# is the only reason this guard exists: every other value goes into the
# subtraction below and means what it says, so "simplifying" the line away
# looks harmless and restores the exact inversion it was written for. `0s` is
# how a board says claims are binding here, and the plain comparison made it
# say the opposite -- (now - claimed_at) > 0 is true of every claim older than
# a second, so the setting meant to protect a card was the setting that handed
# it to the next agent that asked, silently, seconds after the claim.
#
# kanban-md answers it the same way: internal/board/filter.go's IsUnclaimed
# asks `timeout > 0 && t.ClaimedAt != nil` and falls through to "still
# claimed" when the timeout is zero.
#
# Deliberately the same predicate, spelled the same way, as
# L<App::karr::Lock/expired>: the lock side has always read its own zero
# correctly (`lock_timeout: 0s`, see App::karr::Cmd::Unlock), and the two
# stayed out of step for as long as they did because they look alike without
# being the same code. They are not folded into one helper because a
# two-term boolean is the whole of the overlap while everything around it
# differs -- App::karr::Lock is a plain class in the storage layer, judges the
# age of a Git commit rather than a parsed RFC3339 stamp, brings its own TTL
# fallback, and puts the guard ahead of a ref read this role has no
# counterpart for. t/232-claim-timeout-zero-never-expires.t pins both answers
# in one file so a change to either side alone goes red.
#
# A negative timeout cannot arrive from a board -- _parse_timeout sends it to
# the fallback -- but is answered the same way as zero for the same reason
# App::karr::Lock/expired does: "not a positive window" is the whole question
# here, and no caller should have to know which side of zero it landed on.
sub _claim_expired {
    my ($self, $task, $timeout_secs) = @_;
    return 0 unless $timeout_secs && $timeout_secs > 0;
    return 0 unless $task->has_claimed_at;
    my $claimed = $self->_parse_claim_stamp( $task->claimed_at );
    return 0 unless defined $claimed;
    return (Time::Piece::gmtime() - $claimed) > $timeout_secs;
}

# The claim test as one question, because two callers now ask it and karr may
# only have one answer (ticket #252). It was three lines in the middle of
# App::karr::Role::PickRules/pickable, with `return 0 if $task->has_blocked` on
# the very next line, so `karr list --unclaimed` could not borrow it by calling
# pickable with neutralised filters: the blocked line came along, --unclaimed
# would have meant "free AND not blocked", and `list --blocked --unclaimed`
# would have been permanently empty. kanban-md's IsUnclaimed
# (internal/board/filter.go) asks about the claim and nothing else, and so does
# this.
#
# check_claim is not this question and cannot be made into it: it dies instead
# of answering, lets the caller through by name, excuses a card in a terminal
# status, and records what it let past into _expired_claims. This one takes no
# claimant, keeps no exception, writes nothing, and answers about the card
# alone -- which is why it can be asked once per card across a whole board.
#
# `claimed_by: ""` is unclaimed, the case that came here from pickable
# unchanged: kanban-md's omitempty writes the key only when it is non-empty,
# but a card it read and rewrote -- or any hand-written one -- can carry the
# empty string, and Moo's predicate calls that "set". Every imported kanban-md
# card looked held (ticket #59). check_claim's first line spells the same test
# for the same reason, and the two have to agree or a task `pick` refuses is a
# task `move` accepts.
#
# $timeout is optional so a single call reads as a question about one card;
# pass it explicitly when asking about many, so one window covers the run
# rather than re-reading the board config per card. `//` and not `||`: 0 is a
# window of no length, not an absent one -- see _claim_expired, and ticket
# #232 for what conflating the two did.
sub claim_held {
    my ( $self, $task, $timeout ) = @_;
    return 0 unless $task->has_claimed_by && length $task->claimed_by;
    return $self->_claim_expired( $task, $timeout // $self->claim_timeout_secs ) ? 0 : 1;
}


# Keyed by task id rather than a flat list, for the reason spelled out above
# check_claim: the check runs inside a compare-and-swap callback that re-runs on
# contention, and `karr delete` applies it twice for one card. A keyed slot is
# replaced by whichever call comes last; a list would grow a copy per attempt.
# Same shape, and the same reason, as
# App::karr::Role::DependencyCheck/_dependency_warnings.
has _expired_claims => (
    is      => 'ro',
    default => sub { {} },
);

# The one claim-ownership rule, mirroring kanban-md's task.CheckClaim
# (internal/task/validate.go): an unclaimed task is free, the current claimant
# may always proceed, and an expired claim no longer blocks anybody. Anything
# else belongs to an agent who is still working on it, and the mutation is
# refused rather than silently taking the claim over (ticket #56).
#
# Four deliberate differences from kanban-md:
#
#   * an expired claim is not cleared here. kanban-md's CheckClaim blanks
#     ClaimedBy as a side effect of asking the question; in karr that would
#     change what the require_claim check in
#     L<App::karr::Role::TaskMutation/apply_status_change> sees a few lines
#     later, turning an allowed move into a refused one. Expired claims are
#     reaped where they always were, by `karr pick`.
#
#   * the refusal names the way out, in the shape ticket k263 settled on: the
#     prose line, then `karr edit ID --release` -- the one door that needs no
#     claim knowledge -- then, where the caller's own argv was recorded, the
#     caller's own command line with `--claim HOLDER` added, so the last line
#     is the invocation that would have worked. kanban-md's hint is the same
#     idea ("If this is you, add: --claim X"); karr's is followable because
#     every command that applies this rule now takes --claim, delete and
#     archive included (ticket #269).
#
#   * the expired case is recorded, because it used to be the one answer this
#     method gave -- here and in kanban-md both -- with nothing said anywhere
#     (ticket #177). A live claim held by somebody else is refused loudly and
#     the refusal names the holder, which is how #176's confused agent gets its
#     own lost claim name back; then the claim expires and that signal
#     disappears, at the moment it is most useful. `move` and `handoff --claim`
#     re-stamp claimed_by on the way through, so the previous holder is gone
#     from the card too, and karr-foundation, which attributes stalls per claim
#     name, is left attributing to a name nobody ever held.
#
#   * a task in a terminal status is not guarded at all, whoever holds the
#     claim on it. kanban-md's CheckClaim never looks at the status, so this
#     one is karr's rule rather than parity, and it comes from karr's own
#     vocabulary: CONTEXT.md defines a Claim as the lease an agent holds
#     *while working* a task, calls it released once the task reaches a
#     terminal status, and keeps claimed_by there for provenance and interop
#     only. That is not a private reading either -- `karr board` already prints
#     no claimant on a finished card and leaves it out of its "N claimed"
#     footer, both keyed on the very
#     L<App::karr::Config/is_terminal_status> asked here, and `karr pick`
#     refuses to hand a terminal card out again
#     (L<App::karr::Role::PickRules>), so nothing can route a second agent onto
#     finished work through this door. The code was the one place still
#     treating the field as a live lease: the agent that finished a card went
#     on guarding it for the rest of claim_timeout -- an hour by default, and
#     precisely the hour in which the closing note gets appended, the card gets
#     archived, or someone reopens it. Worse, the refusal demanded a name the
#     board deliberately hides on exactly those cards, so the way through was
#     to read it off `karr show`. And it never was a lock: `karr edit ID
#     --release` takes any claim off without knowing whose it is, which made
#     the rule two commands instead of one for whoever knew the way round and a
#     dead end for everybody else (ticket #223). What still protects a finished
#     card is what protects every card here: update_task_guarded's
#     compare-and-swap, which is about concurrent writes and not about
#     ownership.
#
# The refusal is deliberately not the only door, and the message says both
# doors out loud. `karr edit ID --release` takes any claim off without knowing
# whose it is -- the release bypasses this check entirely -- while `karr edit
# ID --claim NAME` is refused against a live claim held by somebody else and
# succeeds only when the claim has expired (and then reports the takeover,
# #177). That asymmetry is deliberate and matches kanban-md: release is the
# escape hatch, and a live claim is not stealable by name. Naming the release
# is what keeps a caller who is not the holder from being left staring at a
# claim they cannot satisfy.
#
# That last case is checked last, after the expiry test rather than before it,
# although either order allows the same calls. The difference is the record: a
# terminal card whose claim had *also* expired keeps reporting the takeover it
# reported before (see expired_claim_report and #177), instead of losing that
# line to a case that answers earlier and says nothing.
#
# Recorded, not printed, and for the same reason as
# App::karr::Role::DependencyCheck: check_claim runs inside
# App::karr::Role::TaskMutation/update_task_guarded's callback, which re-runs
# when another agent gets in first, so a print here would come out once per
# attempt -- and once for an attempt that was then discarded. A slot keyed by
# task id and cleared on entry is replaced by the attempt that wins instead,
# which is also what collapses `karr delete`'s two checks (once outside the
# guard to decide about the prompt, once inside it) into one line.
#
# What is *not* done here: nothing is refused that was not refused before, and
# no new state goes on the card. Taking over an expired claim is the documented
# purpose of claim_timeout, so this makes it audible, not harder. And the
# takeover is not the same event as the holder outliving its own timeout: the
# claimant-matches case returns above without reaching this, so a long-running
# agent never gets warned about itself.
sub check_claim {
    my ($self, $task, $claimant) = @_;
    delete $self->_expired_claims->{ $task->id };
    return 1 unless $task->has_claimed_by && length $task->claimed_by;
    return 1 if defined $claimant && length $claimant && $task->claimed_by eq $claimant;
    if ( $self->_claim_expired( $task, $self->claim_timeout_secs ) ) {
        $self->_expired_claims->{ $task->id } = {
            held_by    => $task->claimed_by,
            claimed_at => $task->claimed_at,
        };
        return 1;
    }
    return 1 if $self->store->is_terminal_status( $task->status );
    my $holder = $task->claimed_by;
    my $msg = sprintf( "Task %d is claimed by %s:\n", $task->id, $holder )
        . App::karr::Error::command_hint( 'edit', $task->id, '--release' ) . "\n";
    my @hint = $self->_claim_refusal_hint($task);
    $msg .= App::karr::Error::command_hint(@hint) . "\n" if @hint;
    die $msg;
}

# The caller's own command line with --claim HOLDER added, or nothing. The
# words come from App::karr::Error/original_argv, which bin/karr records before
# either argv rewrite and the in-process test runner records through the shared
# App::karr::Dispatch path -- and which nothing else records, so a library
# caller or a direct check_claim gets no working-command line at all. That is
# the k263 rule: a suggestion built from placeholders would only spell the
# "Usage:" line a second time, and the release line above is always the honest
# answer for a caller whose words are unknown.
#
# An existing --claim VALUE is replaced rather than appended to, so `karr
# handoff 1 --claim carol` is answered with `karr handoff 1 --claim bob` and
# not with a second --claim that Getopt::Long would refuse. Both spellings the
# caller could have typed are handled: the space form and the `=` form.
sub _claim_refusal_hint {
    my ( $self, $task ) = @_;
    my $argv = App::karr::Error::original_argv();
    return () unless $argv && @$argv;
    my @tokens = @$argv;
    my $holder = $task->claimed_by;
    my $replaced = 0;
    for my $i ( 0 .. $#tokens ) {
        if ( $tokens[$i] eq '--claim' ) {
            $tokens[ $i + 1 ] = $holder if defined $tokens[ $i + 1 ];
            $replaced = 1;
            last;
        }
        if ( $tokens[$i] =~ /\A--claim=(.*)\z/ ) {
            $tokens[$i] = '--claim=' . $holder;
            $replaced = 1;
            last;
        }
    }
    push @tokens, '--claim', $holder unless $replaced;
    return @tokens;
}


# The channels are App::karr::Role::DependencyCheck/dependency_report's, not a
# second convention: STDERR keeps STDOUT parseable, --json carries the same fact
# as data because a JSON consumer never reads STDERR, and --quiet silences the
# human copy only -- the pair is data, not chatter, so a drain loop that does not
# want the line can still read who held the card.
#
# The pair is a structure rather than the sentence DependencyCheck ships,
# because the caller this exists for is karr-foundation, which attributes stalls
# per claim name and must not have to parse that name out of English.
sub expired_claim_report {
    my ( $self, $id ) = @_;

    my $expired = $self->_expired_claims->{$id};
    return () unless $expired;

    printf STDERR
      "Warning: task %s: overriding the expired claim held by %s (claimed %s)\n",
      $id, $expired->{held_by}, $expired->{claimed_at}
      unless $self->json || $self->quiet;

    return ( expired_claim => $expired );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::ClaimTimeout - Shared claim timeout logic

=head1 VERSION

version 0.601

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

=head2 claim_held

    $self->claim_held( $task );
    $self->claim_held( $task, $secs );

True when somebody holds C<$task> right now: C<claimed_by> is set and not the
empty string, and the claim is not older than the timeout. False when the card
carries no claim, carries C<claimed_by: ""> -- which is kanban-md's way of
writing "unclaimed" and has to be read as one (ticket #59) -- or carries a
claim that has expired and so no longer blocks anybody.

C<$secs> is the claim window in seconds and defaults to
L</claim_timeout_secs>. Pass it explicitly when asking about many cards in one
command run, so one window covers the whole run. C<0> is not the shortest
window but no window at all: on a board with C<claim_timeout: 0s> a claim
never expires, so every claimed card stays held until the claim is released.

This is the only definition of "free" in karr, and both callers of it are
meant to stay callers: L<App::karr::Role::PickRules/pickable> asks it about
the card C<karr pick> is about to hand out, and C<karr list --unclaimed> asks
it about every card on the board. A second spelling of the test is how C<list>
and C<pick> come to disagree about which work is available (tickets #59,
#198).

It is B<not> L</check_claim> with the dying left out. That method answers a
different question -- may I<this caller> write this card -- and its extra
cases say so: the current claimant is let through by name, a card in a
terminal status is not guarded at all, and an expired claim stepped over is
recorded for L</expired_claim_report>. This one asks only whether the card is
held, by anybody, and records nothing.

=head2 check_claim

    $self->check_claim( $task, $self->claim );   # $self->claim may be undef

In a command class that composes this role, decides whether C<$task>'s
existing claim blocks the caller and either returns true or dies with a
message naming the holder and both ways out: C<< karr edit ID --release >>,
and -- where the caller's own argv was recorded
(L<App::karr::Error/original_argv>) -- the caller's own command line with
C<--claim HOLDER> added, so the last line is the invocation that would have
worked (the shape ticket k263 settled on). Five cases, checked in order:

=over 4

=item * the task is not claimed at all -- always allowed;

=item * C<$claimant> is defined, non-empty, and matches C<< $task->claimed_by
>> exactly -- the current claimant may always proceed;

=item * the claim is older than L</claim_timeout_secs> -- an expired claim no
longer blocks anyone, but it is B<recorded> for L</expired_claim_report> so the
override does not go unsaid, and it is not cleared as a side effect of asking
(that stays kanban-md's behaviour, not karr's -- see the comment above this
method for why). A C<claim_timeout> of C<0s> means claims never expire, so on
such a board this case never fires at all and nothing is ever recorded;

=item * the task sits in a status this board calls terminal
(L<App::karr::Config/is_terminal_status>) -- a finished card is not being
worked on, so the claim on it guards nothing: C<claimed_by> is kept there as
provenance, which is the same reading C<karr board> applies when it prints no
claimant on a finished card. Checked after the expiry case above so that a
terminal card whose claim had also expired still reports the takeover;

=item * otherwise -- the task belongs to someone still working on it, and the
call dies rather than silently taking the claim over.

=back

The two doors are deliberately asymmetric, and the message says so because
the asymmetry is easy to file as a bug. C<< karr edit ID --release >> takes
any claim off without knowing whose it is: the release bypasses this check
entirely. C<< karr edit ID --claim NAME >> is refused against a I<live> claim
held by somebody else, and succeeds only when the claim has expired -- and
then reports the takeover (L</expired_claim_report>). Both are deliberate and
match kanban-md: release is the escape hatch, and a live claim is not
stealable by name.

Call it against the same task revision the caller then writes -- see
L<App::karr::Role::TaskMutation/update_task_guarded> -- since a check made
against a stale read can pass or fail against bytes that are no longer there.

=head2 expired_claim_report

    return { id => $task->id, ..., $self->expired_claim_report( $task->id ) };

Emits whatever L</check_claim> recorded about an expired claim it let the caller
step over, and returns it as the C<< expired_claim => { held_by => ...,
claimed_at => ... } >> pair for the command's C<--json> payload -- or the empty
list when no claim was overridden, so the key is absent rather than null.

The takeover itself is allowed and stays allowed: an expired claim not blocking
anybody is what C<claim_timeout> is for. What this adds is the trace it left
nowhere. C<claimed_by> is re-stamped by C<move> and C<handoff> on the way
through, so without this the previous holder is gone from the card, from STDOUT
and from STDERR alike -- while the very same mismatch against a I<live> claim is
refused with the holder's name in the message (ticket #177, the behavioural half
of #176).

Call it after the write has landed, never from inside the guarded callback, for
the reason given at L<App::karr::Role::DependencyCheck/dependency_report>: a
warning about a mutation that then lost its compare-and-swap is a warning about
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

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
