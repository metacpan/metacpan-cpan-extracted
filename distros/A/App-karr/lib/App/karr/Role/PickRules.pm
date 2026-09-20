# ABSTRACT: The one definition of which card karr pick may hand out, and in what order

package App::karr::Role::PickRules;
our $VERSION = '0.601';
use Moo::Role;
use App::karr::Config;


# Composed, not required: claim expiry is half the eligibility rule, and its
# RFC3339 parser exists once (App::karr::Role::ClaimTimeout, ticket #57). A
# consumer that also composes ClaimTimeout itself -- App::karr::Cmd::Pick does,
# for the separate lock_timeout parse -- is applying the same role twice, which
# Role::Tiny resolves to one application rather than a method conflict.
with 'App::karr::Role::ClaimTimeout';

sub pickable {
    my ( $self, $task, %filter ) = @_;
    return 0 unless $task;

    my $timeout = defined $filter{timeout} ? $filter{timeout} : $self->claim_timeout_secs;

    if ( $filter{statuses} ) {
        my %allowed = map { $_ => 1 } @{ $filter{statuses} };
        return 0 unless $allowed{ $task->status };
    }
    else {
        # The board's own terminal status, not a hardcoded 'done': a board
        # imported from kanban-md can end in `shipped`, and pick used to hand
        # those finished cards straight back out (ticket #67).
        return 0 if $self->store->is_terminal_status( $task->status );
    }

    # One claim test in karr, and this is a call to it rather than a copy of it
    # (ticket #252). These were three lines spelled out here -- has_claimed_by,
    # length, and the expiry parse -- which was fine while `karr pick` was the
    # only caller and became the #59/#198 failure the moment `karr list
    # --unclaimed` needed the same answer: two spellings of "free" drift, and
    # then a list says a card is available that pick will not hand out.
    #
    # It could not be borrowed by calling pickable itself, because the whole of
    # what used to stand here is the claim, and the next line is not: blocked is
    # pick's rule, not part of being claimed, and kanban-md's IsUnclaimed
    # (internal/board/filter.go) does not ask it either. That is why the claim
    # test moved out and this line stayed behind it.
    #
    # What moved is exactly what was here, `claimed_by: ""` included -- see
    # App::karr::Role::ClaimTimeout/claim_held for the reasoning that came with
    # it.
    return 0 if $self->claim_held( $task, $timeout );
    return 0 if $task->has_blocked;

    if ( $filter{tags} ) {
        my %wanted = map { $_ => 1 } @{ $filter{tags} };
        return 0 unless grep { $wanted{$_} } @{ $task->tags };
    }

    return 1;
}


sub pick_rank {
    my ( $self, @tasks ) = @_;

    # Both axes are driven by the board's configured lists -- not by a
    # hardcoded table that only knew the four default priorities and classes.
    # A board imported from kanban-md can name anything (ticket #149: a
    # `blocker` priority beat a `critical` one on a non-default board); ranking
    # against the hardcoded table gave the wrong card out while
    # `karr list --sort priority` showed the right one right next to it.
    #
    # Convention, matching kanban-md's pick.go: lower class index = more urgent
    # class; higher priority index = more urgent priority. So the sort key for
    # priority is `(max - priority_index)` -- most-urgent-last in the config
    # list comes out first. A priority the board does not list at all sorts
    # below every listed one; a class the board does not list sorts where
    # `standard` does -- and `$std_cls_idx` below decides what that means on a
    # board that does not list `standard` either.
    #
    # Between class and priority sits kanban-md's one exception, and it is not
    # a general due-date rule: only where both cards carry `fixed-date` does
    # the date come first (ticket #233).
    my $cfg        = App::karr::Config->from_merged( $self->store->effective_config );
    my @priorities = $cfg->priorities;
    my @classes    = $cfg->classes;
    my %pri_idx; $pri_idx{ $priorities[$_] } = $_ for 0 .. $#priorities;
    my %cls_idx; $cls_idx{ $classes[$_] }    = $_ for 0 .. $#classes;
    my $max_pri     = $#priorities;

    # `// 0`, not kanban-md's -1, and that is a decision rather than an
    # oversight (ticket #240): kanban-md's classOrder returns
    # cfg.ClassIndex("standard") as it stands, so on a board whose `classes`
    # never names `standard` the unknown class comes back -1 and outranks
    # every configured class. Here it lands level with the board's first class
    # instead. See this method's POD for the reasoning; a change to -1 is
    # visible in t/198-pick-rules-shared.t, subtest 'an unknown class on a
    # board without `standard`'.
    my $std_cls_idx = $cls_idx{standard} // 0;

    return sort {
        ( ( $cls_idx{ $a->class } // $std_cls_idx ) <=> ( $cls_idx{ $b->class } // $std_cls_idx ) )
          || $self->_fixed_date_due_cmp( $a, $b )
          || ( ( $max_pri - ( $pri_idx{ $a->priority } // -1 ) )
            <=> ( $max_pri - ( $pri_idx{ $b->priority } // -1 ) ) )
          || $a->id <=> $b->id
    } @tasks;
}


# kanban-md's sortPickCandidates asks the due date only when both candidates
# are `fixed-date` -- the class of service whose whole point is that a date,
# not an urgency rating, decides. Against any other class (and between two
# cards of any other class) the class index and then priority decide exactly as
# before, so this returns 0 and the chain above carries on.
#
# The ordering within the exception is kanban-md's compareDue
# (internal/board/sort.go): earlier date first, a card with no due date last --
# not first and not level -- and two cards it cannot separate (neither dated,
# or both dated the same day) fall through to priority.
#
# `has_due` is the whole emptiness test: L<App::karr::Task/BUILD> normalizes a
# `due:` that is present but empty back to unset on the parse path, so nothing
# reaches here has_due-true-but-blank (ticket #98). Dates are the bare
# `YYYY-MM-DD` kanban-md's date.Date accepts and karr validates
# (L<App::karr::Config/validate_due>), so a string compare is chronological.
sub _fixed_date_due_cmp {
    my ( $self, $left, $right ) = @_;

    # A card with no class at all is not fixed-date, the same way kanban-md's
    # empty-string class is not.
    my $fixed = App::karr::Config->FIXED_DATE_CLASS;
    return 0
      unless ( $left->class // '' ) eq $fixed
      && ( $right->class // '' ) eq $fixed;

    my $l = $left->has_due  ? $left->due  : undef;
    my $r = $right->has_due ? $right->due : undef;
    return 0 unless defined $l || defined $r;
    return 1 unless defined $l;
    return -1 unless defined $r;
    return $l cmp $r;
}

sub pick_candidates {
    my ( $self, $tasks, %filter ) = @_;
    return $self->pick_rank( grep { $self->pickable( $_, %filter ) } @$tasks );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::PickRules - The one definition of which card karr pick may hand out, and in what order

=head1 VERSION

version 0.601

=head1 DESCRIPTION

Two things decide what C<karr pick> hands an agent: whether a card is available
at all, and which of the available ones comes first. Both were written twice --
once in L<App::karr::Cmd::Pick> and once in L<App::karr::Foundation::Picker>,
which has to name the card the agent's own C<karr pick> would have handed it or
the coordinator is arguing with its own board. They agreed because they were
copied; nothing kept them agreeing (ticket #198).

This role is the definition both call. It lives in a role rather than in
L<App::karr::Task> or L<App::karr::BoardStore> because the eligibility test
needs three things at once: the task, the board (C<< $self->store >> for the
board's terminal statuses and its C<priorities>/C<classes> lists), and the
claim-expiry parser in L<App::karr::Role::ClaimTimeout> -- which this role
composes, so a consumer gets the whole rule by asking for one name. A function
in C<Task> would have had to be handed all three; a method on C<BoardStore>
would have put command-selection policy in the storage layer, which belongs to
a different owner.

What is deliberately B<not> here: claiming, locking and the compare-and-swap
that binds a pick (L<App::karr::Cmd::Pick/EXCLUSIVITY>), because foundation
must not do any of them (L<App::karr::Foundation::Picker>), and the C<--status>
and C<--tags> option parsing, which stays with the command that has options.
This role takes the filters already split, applies them, and stops.

Unmet dependencies are not filtered anywhere in here, matching C<karr pick>:
nothing about C<depends_on> blocks anything in karr, the command hands the card
over and warns (ticket #123).

=head2 pickable

    $self->pickable( $task );
    $self->pickable( $task, timeout => $secs, statuses => \@s, tags => \@t );

True when C<$task> is available to be picked right now. In order: it exists;
its status is in C<statuses> if that filter was given, and is not one of the
board's terminal statuses if it was not (the board's own final column and
C<archived>, never a hardcoded C<done>); it is not held by a claim that is
still live under C<timeout>, where C<claimed_by> set to the empty string is
kanban-md for "unclaimed"; it is not blocked; and it carries at least one of
C<tags> if that filter was given.

C<timeout> is the claim window in seconds and defaults to
L<App::karr::Role::ClaimTimeout/claim_timeout_secs>. Pass it explicitly when
asking about many cards in one command run, so one answer covers the whole
run. C<0> is not the shortest window but no window at all: a board with
C<claim_timeout: 0s> never expires a claim, so every claimed card stays
unpickable until the claim is released. C<statuses> and C<tags> are
already-split lists, not the comma-separated option strings -- splitting
belongs to the command that owns the option. An absent (or empty) filter is
not the same as an empty list: no C<statuses> means "anything but terminal",
C<< statuses => [] >> means nothing qualifies.

The claim half of the test is L<App::karr::Role::ClaimTimeout/claim_held>,
called rather than restated: C<karr list --unclaimed> asks that same method
about every card on the board, so what the list shows as free is what this
method lets C<karr pick> take (ticket #252). The blocked test deliberately
stayed here and is not part of it -- a blocked card is unpickable, not
claimed.

=head2 pick_rank

    my @ranked = $self->pick_rank( @tasks );

C<karr pick>'s order: class of service first, then priority, then task id. Both
lists come from the board's own C<priorities> and C<classes> config, so a board
imported from kanban-md ranks by its own names (ticket #149). Lower class index
is more urgent, higher priority index is more urgent -- kanban-md's convention,
from its F<pick.go>. The id tie-break makes the order total, so the first
element is well defined however the sort was reached.

A name neither list carries still has to rank somewhere. An unlisted priority
sorts below every listed one. An unlisted class -- a typo, or a card imported
from a board with other classes -- takes C<standard>'s index, and index C<0>
where the board's C<classes> does not name C<standard> either, which puts it
level with the first class the board does list.

That last C<0> is a deliberate divergence from kanban-md. Its C<classOrder> in
F<internal/board/pick.go> returns C<< cfg.ClassIndex("standard") >>
unchanged, which is C<-1> on a board without C<standard>, so there an unlisted
class outranks every configured one and is handed out first. karr keeps such a
card ordinary instead: a class the board never heard of is far more likely a
mistake than a claim to urgency, and a card with a typo in it jumping the
queue is the worse of the two failures. The two can only differ on a board
that replaced the default C<classes> list -- which does name C<standard> --
with one that does not, so nothing reaches the difference by accident (ticket
#240).

One class breaks that order, and only against itself: where B<both> cards are
C<fixed-date>, the due date decides before priority is asked (ticket #233).
Earlier due first; a C<fixed-date> card with no due date sorts behind every
dated one; where neither card is dated, or both are due on the same day,
priority decides as usual. Against any other class -- and between two cards of
any other class -- C<due> is not read at all: a C<fixed-date> card meeting an
C<expedite> or a C<standard> one is ranked by class index alone, however soon
either of them is due. This is kanban-md's exception in
C<sortPickCandidates>/C<compareDue>, and it is the class of service that exists
because a date, not an urgency rating, decides.

=head2 pick_candidates

    my @ranked = $self->pick_candidates( [ $self->load_tasks ], %filter );

L</pickable> and L</pick_rank> in one call: every eligible task, most urgent
first. C<karr pick> walks the whole list, because a candidate can still be lost
to another agent's lock or compare-and-swap; L<App::karr::Foundation::Picker>
takes the first and stops.

The list is a ranking, not a decision -- nothing here reads a card under a lock
and nothing writes. See L<App::karr::Cmd::Pick/EXCLUSIVITY> for what has to
happen on top before a pick is binding.

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
