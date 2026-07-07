package Concierge::Auth v0.5.0;
use v5.36;

# ABSTRACT: Factory/dispatcher for Concierge::Auth backends

use Carp qw/croak/;

sub new {
    my ($class, %args) = @_;
    my $backend_class = delete $args{backend}
        or croak "Concierge::Auth->new requires a 'backend' class name";

    eval "require $backend_class; 1"
        or croak "Cannot load Auth backend $backend_class: $@";

    my $backend;
    eval { $backend = $backend_class->new(%args); };
    croak "Failed to initialize backend $backend_class: $@" if $@;

    return $backend;
}

1;

__END__

=head1 NAME

Concierge::Auth - Factory/dispatcher for Concierge::Auth backends

=head1 VERSION

v0.5.0

=head1 SYNOPSIS

    use Concierge::Auth;

    my $auth = Concierge::Auth->new(
        backend => 'Concierge::Auth::Pwd',
        file    => '/path/to/auth.pwd',
    );

    # $auth is a Concierge::Auth::Pwd instance -- use it directly:

    my $result = $auth->enroll('alice', 'secret123');
    my $result = $auth->authenticate('alice', 'secret123');
    my $result = $auth->is_id_known('alice');
    my $result = $auth->change_credentials('alice', 'newsecret456');
    my $result = $auth->revoke('alice');

=head1 DESCRIPTION

C<Concierge::Auth> is a thin factory that resolves a backend class name
to a live backend instance. It performs I<no> guessing: C<backend> must
be a fully-qualified, already-resolved class name (e.g.
C<Concierge::Auth::Pwd>), not a friendly short name like C<'pwd'>.
There is no default backend and no C<lc()>/string-mapping performed
here.

Resolving a friendly name (such as a C<backend> value read from a
config file) to a fully-qualified class name, and validating that every
setting the chosen backend needs is present, is a desk-build-time
concern handled by L<Concierge::Desk::Setup> (see its backend catalog,
C<%AUTH_BACKENDS>), not by this module. By the time C<Concierge::Auth-E<gt>new>
is called, that resolution has already happened once, not on every call.

The named backend module is C<require>d dynamically inside C<new> --
this module does not C<use> any concrete backend at compile time. A
desk configured for C<Concierge::Auth::LDAP>, for example, never loads
C<Concierge::Auth::Pwd> at all.

Unlike L<Concierge::Sessions>, which wraps its backend inside a
C<{ storage => $backend }> container, this factory returns the backend
instance directly. A conforming backend (e.g. C<Concierge::Auth::Pwd>)
already fully implements the L<Concierge::Auth::Base> contract, so no
wrapper object or delegation layer is needed -- C<$concierge-E<gt>{auth}>
responds directly to C<authenticate>/C<is_id_known>/C<enroll>/
C<change_credentials>/C<revoke>, and to the
L<Concierge::Auth::Generators> methods, with no extra indirection.

All remaining arguments passed to C<new> (e.g. C<file> for C<::Pwd>;
C<host>/C<bind_dn>/C<password> for a hypothetical C<::LDAP>) are passed
straight through to the backend's own C<new> unexamined --
C<Concierge::Auth> has no opinion about what any given backend needs.

=head1 CONSTRUCTOR

=head2 new

    my $auth = Concierge::Auth->new( backend => $class_name, %backend_args );

Loads C<$class_name> (via C<require>) and calls C<< $class_name->new(%backend_args) >>,
returning the resulting backend instance.

Croaks if:

=over 4

=item * C<backend> is missing.

=item * The named class cannot be loaded (nonexistent module, syntax
error, missing dependency, etc).

=item * The backend's own C<new> dies.

=back

=head1 SEE ALSO

L<Concierge::Auth::Base> -- the contract every backend must implement

L<Concierge::Auth::Pwd> -- the built-in password-file backend

L<Concierge::Desk::Setup> -- resolves friendly backend names (e.g.
C<'pwd'>) to fully-qualified classes and validates backend-specific
required settings at desk-build time

L<Concierge::Sessions>, L<Concierge::Users> -- companion Concierge
components

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut
