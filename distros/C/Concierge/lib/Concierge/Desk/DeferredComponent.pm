package Concierge::Desk::DeferredComponent v0.13.0;
use v5.36;

our $VERSION = 'v0.13.0';

# ABSTRACT: Stand-in that defers a 'defer' component's real construction until first use

our $AUTOLOAD;

sub new ($class, %args) {
    return bless {
        name    => $args{name},
        class   => $args{class},
        payload => $args{payload},
        _real   => undef,   # built on first use, cached here once successful
    }, $class;
}

sub AUTOLOAD {
    my $self = shift;

    my $called = $AUTOLOAD;
    $called =~ s/.*:://;
    return if $called eq 'DESTROY';   # never fall through to build-on-teardown

    unless ($self->{_real}) {
        my $comp;
        my $ok = eval {
            (my $file = $self->{class}) =~ s{::}{/}g;
            require "$file.pm";
            $comp = $self->{class}->new($self->{payload});
            1;
        };
        if ($ok) {
            $self->{_real} = $comp;
        } else {
            # Permanent-for-this-instance failure -- matches
            # UnavailableComponent precedent exactly; no retry, ever.
            require Concierge::Desk::UnavailableComponent;
            $self->{_real} = Concierge::Desk::UnavailableComponent->new(
                name => $self->{name}, reason => $@,
            );
        }
    }

    return $self->{_real}->$called(@_);
}

# Explicit no-op DESTROY. Without this, object teardown would invoke
# AUTOLOAD for 'DESTROY' (Perl calls AUTOLOAD for a missing DESTROY just
# like any other missing method); the 'return if DESTROY' guard above
# only prevents AUTOLOAD from returning early in that case, it does not
# avoid the AUTOLOAD call itself -- and critically, without this, object
# teardown at the end of every test/request would itself trigger the
# deferred build.
sub DESTROY { }

1;

__END__

=head1 NAME

Concierge::Desk::DeferredComponent - Stand-in that defers a 'defer' component's real construction until first use

=head1 VERSION

v0.13.0

=head1 SYNOPSIS

    my $comp = Concierge::Desk::DeferredComponent->new(
        name    => 'reports',
        class   => 'Concierge::Reports',
        payload => $payload,
    );

    # Nothing has been built yet. The first real method call triggers
    # Concierge::Reports->new($payload) and caches the result:
    my $result = $comp->get_signal_report('x');

    # Subsequent calls delegate directly to the cached real object --
    # no second construction attempt:
    my $result2 = $comp->get_signal_report('y');

=head1 DESCRIPTION

C<Concierge::Desk::DeferredComponent> is installed by L<Concierge/open_desk>
in place of a component marked C<< defer => 1 >> in the desk's
C<components> config block, once that component has passed its open-time
C<probe()> check (see L<Concierge::Desk::Component/probe_component>). It
defers the component's real, potentially expensive C<new($payload)> call
until the first actual method call, then caches the resulting object (or,
on failure, an L<Concierge::Desk::UnavailableComponent> stand-in) and
delegates every call -- including that first one -- to it from then on.

Modeled directly on C<Concierge::Desk::UnavailableComponent>: same
C<AUTOLOAD>-based shape, opposite direction. C<UnavailableComponent>
permanently fails every call from the start; C<DeferredComponent> builds
the real thing on first use and then behaves exactly as if that real
object had been installed at C<open_desk()> time all along.

There is no self-replacement of C<< $concierge->{$name} >> -- the proxy
stays in place permanently and caches+delegates internally. This keeps
the mechanism simple; the overhead of one extra method-forwarding call is
negligible next to what a real component's methods typically do.

If the deferred build fails on first use, that failure is B<permanent>
for the life of this instance -- no retry is ever attempted, matching
C<UnavailableComponent>'s existing precedent exactly. A fresh process
(a new C<open_desk()> call) re-attempts probing and deferred construction
from scratch.

=head1 METHODS

=head2 new

    my $comp = Concierge::Desk::DeferredComponent->new(
        name    => $component_name,
        class   => $component_class,
        payload => $payload,
    );

Constructor. Stores C<name> (the component's key in the desk's
C<components> config), C<class> (the component's real class name), and
C<payload> (exactly what will be passed to the real class's C<new()> on
first use) on the blessed object. Does not build or C<require> the real
class -- that happens lazily, in C<AUTOLOAD>, on first method call.

=head2 AUTOLOAD

Any method call other than C<DESTROY> is caught by C<AUTOLOAD>. On the
first such call, it C<require>s C<class> and calls
C<< $class->new($payload) >>:

=over 4

=item * On success, the resulting object is cached and the original call
is delegated to it.

=item * On failure, a L<Concierge::Desk::UnavailableComponent> stand-in
is built and cached instead (never a live crash), and the original call
is delegated to I<that> -- returning the standard
C<< { success => 0, message => "Component '$name' unavailable: ..." } >>
failure hashref.

=back

Every subsequent call, regardless of outcome, delegates directly to the
cached object -- the real component is never constructed more than once,
and a failed first attempt is never retried.

=head2 DESTROY

Explicit no-op, so object teardown does not fall through to C<AUTOLOAD>
and inadvertently trigger the deferred build.

=head1 THE can()/isa() CAVEAT

Exactly as documented for L<Concierge::Desk::UnavailableComponent>:
C<AUTOLOAD> intercepts calls to methods that don't otherwise exist, but
it does B<not> make C<can()> or C<isa()> report true for those methods,
whether or not the real component has been built yet. Code that probes a
component with C<can()>/C<isa()> before calling it will find the probe
false on a C<DeferredComponent> stand-in, even before any deferred build
has occurred. The correct pattern, per
L<Concierge::Desk::Component/UNAVAILABLE COMPONENT SUBSTITUTION>, is to
call the method directly and check C<< $result->{success} >>, never to
probe with C<can>/C<isa> first.

=head1 SEE ALSO

L<Concierge::Desk::Component> -- the contract this class defers, and
C<probe_component()>, the shared helper used to revalidate a C<defer>
component before installing this stand-in.

L<Concierge::Desk::UnavailableComponent> -- the stand-in this class
delegates to internally if the deferred build itself fails.

L<Concierge> -- see C<open_desk()> for where this substitution happens.

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
