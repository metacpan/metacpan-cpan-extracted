package Concierge::Desk::Component v0.13.0;
use v5.36;

our $VERSION = 'v0.13.0';

# ABSTRACT: Contract documentation for additional Concierge desk components

# probe_component($class, $payload) -- the one functional sub this module
# contains (see POD, "This module is B<pure documentation>" below for the
# single exception this carves out). Shared by Concierge::Desk::Setup's
# build_desk() (tier 1b) and Concierge's open_desk() (tier 2) for 'defer'
# components, so the two call sites can never drift out of sync. Plain
# package-qualified function, not a method -- Component.pm is never
# instantiated and nothing inherits from it.
sub probe_component ($class, $payload) {
    return $class->probe($payload) if $class->can('probe');
    my $ok = eval {
        (my $file = $class) =~ s{::}{/}g;
        require "$file.pm";
        1;
    };
    return $ok ? { success => 1 } : { success => 0, message => $@ };
}

1;

__END__

=head1 NAME

Concierge::Desk::Component - Contract documentation for additional Concierge desk components

=head1 VERSION

v0.13.0

=head1 DESCRIPTION

C<Concierge::Desk::Component> documents the minimal contract a module must
follow to be usable as an additional component in a Concierge desk (wired
up via a C<components> block in L<Concierge::Desk::Setup/build_desk>).

This module is almost entirely documentation. Its one exception is
C<probe_component()> (see L</PROBING: CHEAP REACHABILITY CHECKS FOR
'defer' COMPONENTS>), a small shared helper used by C<build_desk()> and
C<open_desk()> for C<defer>red components; nothing else here is
functional, and nothing inherits from this module. Concierge's component
mechanism is duck-typed: any class satisfying the contract below works,
regardless of what (if anything) it subclasses. There is no C<isa> check
anywhere in the loading path -- and just as importantly, neither
C<Concierge> nor C<Concierge::Desk::Setup> ever inherits from an added
component. The relationship is compositional, not hierarchical: the
application's concierge obtains component objects and hands them to the
application, which composes its own capabilities from them, rather than a
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

=head1 PROBING: CHEAP REACHABILITY CHECKS FOR 'defer' COMPONENTS

=head2 probe

    my $result = SomeComponent->probe($payload);
    # { success => 1 }  or  { success => 0, message => '...' }

An optional, duck-typed B<class> method (not an instance method --
deliberately decoupled from C<new()> so it can do a genuinely cheap check,
e.g. a raw socket connect, a file-exists check, a DNS resolution, without
paying for whatever C<new()> actually does: pool setup, ORM init, a full
auth handshake).

C<probe> is only ever consulted for a component marked C<< defer => 1 >>
in the desk's C<components> config block; it is never called for a
non-C<defer> component. A component author is never required to implement
C<probe> just because C<defer> is used elsewhere in the desk -- see
C<probe_component()> below for what happens when it's absent.

C<probe> must be fast and self-bounded. Concierge does not enforce a
timeout around it; see L<Concierge/Additional Components> for the
C<$max_wait_for_load> convention and the blocking-retry warning.

=head2 probe_component

    my $result = Concierge::Desk::Component::probe_component($class, $payload);
    # { success => 1 }  or  { success => 0, message => '...' }

A plain package-qualified function -- B<not> a method call, since this
module is never instantiated and nothing inherits from it. Shared
identically by C<< Concierge::Desk::Setup::build_desk() >> (build-time
probe, for every C<defer> entry, immediately after C<setup()> succeeds)
and C<< Concierge->open_desk() >> (open-time revalidation, for every
C<defer> entry), so the two call sites can never drift apart.

If C<$class> implements C<probe>, C<probe_component()> simply calls and
returns C<< $class->probe($payload) >>. If C<$class> does not implement
C<probe>, it falls back to a default check equivalent to what already
happens implicitly for every non-C<defer> component: can the class even
be C<require>d. This is the same default used at both the build-time and
open-time call sites -- nothing is ever silently skipped for a C<defer>
component merely because it lacks a C<probe> method.

Both C<Concierge.pm> and C<Concierge::Desk::Setup> declare their own
explicit C<use Concierge::Desk::Component;> to call this function, rather
than relying on one loading it as a side effect of the other.

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

=head1 FORWARD REFERENCE: A FUTURE compose()

B<This section is a flag for future editing, not documentation of
existing behavior.> No C<compose()> method exists anywhere in Concierge
today, nothing described below is implemented, and no API for it has
been finalized or even fully designed.

The idea under consideration is some future affordance -- tentatively
named C<compose()> -- for combining multiple added components into a
single, unified interface, rather than an application reaching each one
individually through its own accessor as described above. Earlier
drafts of this project assumed such a thing, if it were ever built,
would belong on C<Concierge> or C<Concierge::Desk::Setup>. On reflection,
B<this module> -- C<Concierge::Desk::Component> -- looks like the more
logical home for whatever contract documentation a real C<compose()>
would eventually need, since this is already the fixed point for the
single-added-component contract that C<compose()> would presumably have
to build on or generalize.

This note exists purely so that whoever eventually designs and
implements C<compose()> starts by looking here, not to commit to any
particular design, timeline, or even the certainty that it will be
built at all.

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
