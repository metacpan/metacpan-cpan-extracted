# ABSTRACT: karr-foundation ticket selection -- the one card a ticket-mode run is about

package App::karr::Foundation::Picker;
our $VERSION = '0.601';
use Moo;
use App::karr::Role::PickRules;



has store => (
  is       => 'ro',
  required => 1,
);

# The two names App::karr::Role::ClaimTimeout requires beyond store, wanted for
# check_claim's reporting half (its expired_claim_report), which nothing here
# calls -- selection only ever asks _claim_expired. foundation has no --json and
# no --quiet, and it says what it did through .karr.log, so these answer for the
# shape of that: never JSON, never printing.
sub json  { 0 }
sub quiet { 1 }


# Composed here, not at the top of the file: Moo applies a role at the point the
# "with" stands, and the role chain requires the three names above it.
with 'App::karr::Role::PickRules';

sub next_ticket {
  my ( $self ) = @_;

  # No filters: `karr pick` narrows this same test with --status and --tags,
  # foundation asks it unnarrowed. And only the first card -- the rest of the
  # ranking is for pick, which walks it when a candidate is lost to a lock.
  my ( $first ) = $self->pick_candidates( [ $self->store->load_tasks ] );
  return undef unless $first;
  return $first->id;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation::Picker - karr-foundation ticket selection -- the one card a ticket-mode run is about

=head1 VERSION

version 0.601

=head1 DESCRIPTION

L<App::karr::Foundation::Picker> answers one question for
L<App::karr::Foundation>'s C<< mode: ticket >>: which card is this agent run
about? It applies C<karr pick>'s eligibility rules and C<karr pick>'s ranking
to one board and returns a task id -- and stops there. It claims nothing, locks
nothing and writes nothing.

Applies, not mirrors: the rules are L<App::karr::Role::PickRules>, composed
here and composed by L<App::karr::Cmd::Pick>, so both ask one definition. They
were written out twice until ticket #198, and only their having been copied
from one another kept them agreeing -- while foundation naming a card the
agent's own C<karr pick> would not have handed it is a coordinator arguing with
its own board.

Not claiming and not locking is the whole difference to
L<App::karr::Cmd::Pick>, and it is deliberate. Foundation already holds the
board's F<.karr.lock> for the length of the run and the fleet rule is one
agent per repository, so nothing else can take the
card while the run lasts; a second owner would only add a claim with a lifetime
nobody watches. The claim belongs to the agent, which mints its own name with
C<karr agentname> and has to keep using that same name for C<move> and
C<handoff> (#176) -- a name foundation invented could not be handed over
without inventing a protocol for it. So an agent that dies mid-run leaves at
most its own claim, cleared by the board's C<claim_timeout> or by
C<karr unlock>, exactly as it does today.

Claim expiry rides along with those rules, from
L<App::karr::Role::ClaimTimeout>, which L<App::karr::Role::PickRules> composes:
reading an expired claim correctly means parsing an RFC3339 stamp that may
carry a fraction and an offset (#57), and that parser exists once. Foundation
has to see expiry, or a crashed agent's claim would take its card out of the
assignable set for good and a board whose only open card carries such a claim
would go quiet for ever -- nothing would run, so nothing would reap the claim.

=head2 store

The L<App::karr::BoardStore> for the board L</next_ticket> picks from.
Required.

=head2 json

Always false. Exists only to satisfy L<App::karr::Role::ClaimTimeout>'s
contract; karr-foundation's ticket-mode selection has no C<--json> and never
emits any.

=head2 quiet

Always true, for the same reason as L</json>: nothing here prints, ever --
karr-foundation says what it did through F<.karr.log> instead.

=head2 next_ticket

    my $id = App::karr::Foundation::Picker->new( store => $store )->next_ticket;

The id of the card a C<< mode: ticket >> run should be about, or C<undef> when
the board has none to give. Eligibility is
L<App::karr::Role::PickRules/pickable> with C<--status> and C<--tags> absent --
the same call C<karr pick> makes, not a mirror of it: not in a terminal status
(the board's own final column and C<archived>, not a hardcoded C<done>), not
blocked, and not held by a live claim, where a claim past the board's
C<claim_timeout> no longer blocks anybody here either. Ranking is
L<App::karr::Role::PickRules/pick_rank>: class of service, then priority, then
id -- with kanban-md's one exception, where two C<fixed-date> cards are
ranked by the sooner due date before priority is asked (#233).

Unmet dependencies are not filtered out, which is C<karr pick>'s behaviour and
comes from applying its rules: nothing about C<depends_on> blocks anything in
karr, the command hands the card over and warns (#123). Filtering here would
make foundation stricter than the board it coordinates.

Nothing is written and nothing is locked, so the answer is a hint that ages:
by the time the agent reads it the card may have moved. That is the same
staleness every C<karr> client lives with, and foundation's per-repo lock plus
the one-agent-per-repository rule is what keeps it from mattering within a run.

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
