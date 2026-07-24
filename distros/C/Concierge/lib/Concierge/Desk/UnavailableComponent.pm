package Concierge::Desk::UnavailableComponent v0.11.0;
use v5.36;

our $VERSION = 'v0.11.0';

# ABSTRACT: Stand-in substituted for a failed optional Concierge desk component

our $AUTOLOAD;

sub new ($class, %args) {
    return bless {
        name   => $args{name},
        reason => $args{reason},
    }, $class;
}

sub AUTOLOAD {
    my $self = shift;

    my $called = $AUTOLOAD;
    $called =~ s/.*:://;
    return if $called eq 'DESTROY';

    my $name   = $self->{name}   // '(unknown)';
    my $reason = $self->{reason} // '(unknown reason)';

    return {
        success => 0,
        message => "Component '$name' unavailable: $reason",
    };
}

# Explicit no-op DESTROY. Without this, object teardown would invoke
# AUTOLOAD for 'DESTROY' (Perl calls AUTOLOAD for a missing DESTROY just
# like any other missing method); the 'return if DESTROY' guard above
# only prevents AUTOLOAD from returning a failure hashref in that case,
# it does not avoid the AUTOLOAD call itself. A real DESTROY here is
# cheaper and clearer than relying on that guard.
sub DESTROY { }

1;

__END__

=head1 NAME

Concierge::Desk::UnavailableComponent - Stand-in substituted for a failed optional Concierge desk component

=head1 VERSION

v0.11.0

=head1 SYNOPSIS

    my $comp = Concierge::Desk::UnavailableComponent->new(
        name   => 'organizations',
        reason => $@,
    );

    my $result = $comp->add_record('acme', {});
    # { success => 0, message => "Component 'organizations' unavailable: ..." }

=head1 DESCRIPTION

C<Concierge::Desk::UnavailableComponent> is substituted by
L<Concierge/open_desk> in place of an C<optional> component whose
C<new()> died at desk-open time. It accepts any method call and returns
a uniform failure hashref, so application code that always checks
C<< $result->{success} >> continues to work without special-casing a
missing component.

This substitution can only happen at C<open_desk()> time, and only for
a component that was configured C<< optional => 1 >> in the desk's
C<components> block at build time. It presupposes the component
already succeeded once: a C<setup()> failure always fails the entire
desk build, regardless of C<optional> (see
L<Concierge::Desk::Setup/build_desk>), so the desk could not have been
built -- and Concierge could not have been instantiated -- unless this
component's C<setup()> succeeded. C<UnavailableComponent> stands in
only for a later C<new()> failure, typically in some subsequent process
opening the same already-built desk, where something in that runtime
environment (a missing library, an unreachable resource) causes
construction to fail even though the persisted C<payload> itself is
fine.

There is no supported way to swap in a working component after this
substitution occurs. Desk configuration is fixed at C<open_desk()>
time, and patching C<< $concierge->{name} >> directly with a live
replacement, while technically possible today, is not a sanctioned
pattern.

=head1 METHODS

=head2 new

    my $comp = Concierge::Desk::UnavailableComponent->new(
        name   => $component_name,
        reason => $failure_reason,
    );

Constructor. Stores C<name> (the component's key in the desk's
C<components> config) and C<reason> (typically the C<$@> captured from
the failed C<new()> call) on the blessed object.

=head2 AUTOLOAD

Any method call other than C<DESTROY> is caught by C<AUTOLOAD> and
returns:

    { success => 0, message => "Component '$name' unavailable: $reason" }

regardless of arguments.

=head2 DESTROY

Explicit no-op, so object teardown does not fall through to C<AUTOLOAD>.

=head1 THE can()/isa() CAVEAT

C<AUTOLOAD> intercepts calls to methods that don't otherwise exist, but
it does B<not> make C<can()> or C<isa()> report true for those methods.
This class deliberately does B<not> override C<can()> or C<isa()> to
paper over that gap. Code that probes a component before calling it --

    if ($comp->can('add_record')) {
        $comp->add_record(...);
    }

-- will find C<can('add_record')> false on an C<UnavailableComponent>
stand-in, and so will silently skip the call instead of getting the
uniform failure hashref. The correct pattern, per
L<Concierge::Desk::Component/UNAVAILABLE COMPONENT SUBSTITUTION>, is to
call the method directly and check C<< $result->{success} >>, never to
probe with C<can>/C<isa> first.

=head1 SEE ALSO

L<Concierge::Desk::Component> -- the contract this class stands in for
when a component fails to load.

L<Concierge> -- see C<open_desk()> for where this substitution happens.

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
