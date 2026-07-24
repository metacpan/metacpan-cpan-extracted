package Concierge::Desk::Component v0.11.0;
use v5.36;

our $VERSION = 'v0.11.0';

# ABSTRACT: Contract documentation for additional Concierge desk components

1;

__END__

=head1 NAME

Concierge::Desk::Component - Contract documentation for additional Concierge desk components

=head1 VERSION

v0.11.0

=head1 DESCRIPTION

C<Concierge::Desk::Component> documents the minimal contract a module must
follow to be usable as an additional component in a Concierge desk (wired
up via a C<components> block in L<Concierge::Desk::Setup/build_desk>).

This module is B<pure documentation>. It has no functional subs, and
nothing inherits from it. Concierge's component mechanism is duck-typed:
any class satisfying the contract below works, regardless of what (if
anything) it subclasses. There is no C<isa> check anywhere in the loading
path -- and just as importantly, neither C<Concierge> nor
C<Concierge::Desk::Setup> ever inherits from an added component. The
relationship is compositional, not hierarchical: the application's
concierge obtains component objects and hands them to the application,
which composes its own capabilities from them, rather than a
component's behavior becoming part of Concierge's own class hierarchy.

=head1 THE CONTRACT

=head2 new

    my $component = Some::Component->new($payload);

Ordinary Perl constructor convention -- the B<sole> exception to the
hashref-return convention followed everywhere else in Concierge. C<new>
either returns a blessed reference or dies/croaks on failure. It does
B<not> return C<< { success => 0, ... } >> on failure; Concierge's
C<open_desk()> wraps the call in C<eval> and inspects C<$@>, not a return
value.

C<$payload> is exactly whatever the component's own C<setup()> returned
at build time (see below) -- persisted verbatim into C<concierge.conf>
and handed back unchanged. C<new()> is never called at build time with
this payload; build time calls C<new()> with no arguments (or whatever
the component itself expects at that point in its own lifecycle) before
calling C<setup()>. The two calls to C<new()> -- one at build time, one
at C<open_desk()> time -- are not required to take the same arguments;
each component decides its own construction story for each phase.

=head2 setup

    my $result = $component->setup($config);

Called exactly once, at desk build time (from C<build_desk()>). Always
returns a hashref:

    { success => 1, message => '...', ...payload keys... }
    { success => 0, message => '...' }

Whatever C<setup()> returns is stored verbatim as the component's
C<payload> in C<concierge.conf>, and is exactly what gets passed to
C<new()> at C<open_desk()> time in every subsequent process that opens
the desk. C<setup()> is never re-run or re-consulted at runtime -- design
accordingly. A C<setup()> failure at build time always fails the entire
desk build, regardless of whether the component was marked C<optional> in
the C<components> config block; C<optional> only affects behavior at
C<open_desk()> time (see L<Concierge::Desk::UnavailableComponent>), not
at build time.

=head2 Every other method

Every other method exposed by a conforming component should return a
hashref following the same convention used throughout Concierge:

    { success => 1, message => '...', payload... }
    { success => 0, message => '...' }

Callers (including Concierge itself, for any core-affordance-adjacent
component) should check C<< $result->{success} >> rather than relying on
exceptions.

=head1 PROMOTION: EXPOSING COMPONENT METHODS ON $concierge

A component's full API is always reachable through the bare accessor
installed by C<open_desk()> -- C<< $concierge->{name}->method(...) >> or
C<< $concierge->name->method(...) >>. This is the standard access
Concierge provides the application for using the component and
requires no configuration; it works for every component, promoted or
not.

The bare accessor can also be used just once, to capture the component
object itself, after which the application can call its methods
directly, with Concierge no longer part of the call:

    my $componentObj = $c->{component_name}; # or $c->component_name();
    $componentObj->method();

It's the same object either way -- Concierge is not a god object that
mediates every operation; it is how the application obtains component
objects that it then composes into its own logic, independent of
Concierge from that point on.

C<promote> is an additional, optional, convenience layer on top of
that: a curated allowlist of a component's methods forwarded directly
onto C<$concierge> itself, so C<< $concierge->get_signal_report(...) >>
works as sugar for C<< $concierge->{reports}->get_signal_report(...) >>.
It is a convenience/clarity mechanism only, B<not> access control --
every component method stays reachable via direct access to the
component regardless of whether it is promoted.

=head2 Config shape

Declared in the same C<components> config block as C<class> and
C<optional>, passed to C<< Concierge::Desk::Setup::build_desk() >>:

    components => {
        reports => {
            class   => 'Concierge::Reports',
            promote => ['get_signal_report'],
            # or, to expose it under a different top-level name:
            promote => { fetch_signal_report => 'get_signal_report' },
        },
    },

An arrayref promotes each listed method under its own name. A hashref
promotes C<< top_name => component_method >> pairs, letting the
top-level name differ from the component's own method name. In other
words, the concierge may use its own alias to call the component's real
method -- e.g. C<< $concierge->fetch_signal_report(...) >> calls the
component's C<get_signal_report()>.

    my $c = Concierge->open_desk($desk_dir)->{concierge};
    $c->fetch_signal_report(...);                 # promoted sugar, using alias
    $c->{reports}->get_signal_report(...);        # direct component access

=head2 Validation happens entirely at build time

C<promote> is a build-time-only decision. C<< build_desk() >> validates
it exhaustively -- shape (arrayref/hashref of plain strings),
method-existence (C<< $comp->can($method_name) >>), and name-collision
detection (against core Concierge methods, every component's own
bare-accessor name, and every other component's promoted names) -- and
persists the already-validated C<promote> entries verbatim into
C<concierge.conf>. Any failure here uses C<build_desk()>'s standard
C<< { success => 0, message => '...' } >> return, exactly like a
C<setup()> failure -- never an exception.

C<open_desk()> performs B<none> of this validation. It trusts
C<concierge.conf> completely and simply replays each persisted
C<promote> entry as a forwarding sub. This is intentional: the
validation already happened once, at build time; re-validating on
every desk open would be redundant work for no added safety.

C<setup()> never sees C<promote> -- it is excluded from the config
hash passed to C<< $component->setup() >>, alongside C<class> and
C<optional>.

=head2 Interaction with UnavailableComponent

If a promoted component is C<optional> and its C<new()> fails at
C<open_desk()> time (see L</UNAVAILABLE COMPONENT SUBSTITUTION> below),
its promoted forwarding subs are still installed -- with zero special
casing. A forwarding sub's C<< ->$method_name(@_) >> call resolves
through L<Concierge::Desk::UnavailableComponent>'s C<AUTOLOAD> exactly
as it would through any other method call on the stand-in, returning
the standard C<< { success => 0, message => "Component '...'
unavailable: ..." } >> failure hashref -- no die, no missing sub.

=head2 Process-lifetime uniqueness caveat

Promoted forwarding subs are installed the same way bare accessors
are: as package-level globs on C<Concierge::>, guarded by
C<< unless ($concierge->can($top_name)) >> so a later C<open_desk()>
call in the same process does not reinstall (or fight over) a name
already claimed by an earlier desk that process opened. This is not
new behavior -- it is the existing bare-accessor idiom, applied
identically to promoted names.

=head2 Future direction (not implemented)

A component-advertised "suggested methods" discovery convention (e.g.
an C<api_methods()> method a component could implement to suggest its
own promotion candidates) is a plausible future extension, but for now
C<promote> is entirely author-specified in the C<components> config
block.

=head1 UNAVAILABLE COMPONENT SUBSTITUTION

If a component is registered as C<optional> in the desk's C<components>
config block and its C<new()> dies at C<open_desk()> time, Concierge
substitutes a L<Concierge::Desk::UnavailableComponent> object in its
place rather than failing the whole desk open. Every method call on that
stand-in -- via C<AUTOLOAD> -- returns
C<< { success => 0, message => "Component '$name' unavailable: $reason" } >>.

B<Caveat:> C<AUTOLOAD> does not make C<can()> or C<isa()> report true for
the methods it's standing in for. Application code that probes a
component with C<< $comp->can('some_method') >> before calling it will
find the probe returns false on an C<UnavailableComponent> stand-in, even
though calling C<some_method> directly works fine (via C<AUTOLOAD>) and
returns the expected failure hashref. The correct pattern is to call the
method directly and check C<< $result->{success} >> -- never probe with
C<can>/C<isa> first:

    my $result = $concierge->organizations->add_record($id, \%data);
    unless ($result->{success}) {
        # handle $result->{message} -- this branch also
        # correctly handles an UnavailableComponent substitution
    }

A required (non-optional) component's C<new()> failure is not caught
this way -- it propagates as an uncaught exception from C<open_desk()>,
since a desk must never open half-instantiated.

=head1 SEE ALSO

L<Concierge> -- see its C<open_desk()> and EXTENSIBILITY section for how
the C<components> config block is loaded.

L<Concierge::Desk::Setup> -- see C<build_desk()> for how a component's
C<setup()> result is resolved and persisted at build time.

L<Concierge::Desk::UnavailableComponent> -- the stand-in substituted for
a failed optional component.

L<Concierge::Users> -- the identity core records-store component; not
itself wired through the generic C<components> mechanism (Users remains
a hardcoded core affordance), but a production example of the C<new>/
C<setup> two-phase lifecycle this contract documents.

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
