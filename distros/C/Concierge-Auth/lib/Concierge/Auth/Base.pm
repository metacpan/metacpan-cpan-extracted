package Concierge::Auth::Base v0.5.2;
use v5.36;

# ABSTRACT: Base class / contract for Concierge::Auth backends

use Concierge::Auth::Generators ();

# Define interface methods that must be implemented by subclasses:
# Concierge::Auth::MyBackend->new(%args);
sub new { die "Subclass must implement new" }

# $backend->authenticate($user_id, $credential);
sub authenticate { die "Subclass must implement authenticate" }

# $backend->is_id_known($user_id);
sub is_id_known { die "Subclass must implement is_id_known" }

# $backend->enroll($user_id, $credential, \%opts);
sub enroll { die "Subclass must implement enroll" }

# $backend->change_credentials($user_id, $new_credential);
sub change_credentials { die "Subclass must implement change_credentials" }

# $backend->revoke($user_id);
sub revoke { die "Subclass must implement revoke" }

# Generator methods -- default implementations delegate to the plain
# functions in Concierge::Auth::Generators, preserving its wantarray
# (value)/(value, message) dual-return convention. Unlike the five
# methods above, these are NOT required overrides: a backend that has
# no reason to customize ID/token generation gets a working
# implementation for free. Any backend may still override one or more
# of these with its own logic (e.g. an LDAP backend deferring ID
# generation to the directory).
sub gen_uuid          { my $self = shift; return Concierge::Auth::Generators::gen_uuid(@_); }
sub gen_random_id     { my $self = shift; return Concierge::Auth::Generators::gen_random_id(@_); }
sub gen_random_token  { my $self = shift; return Concierge::Auth::Generators::gen_random_token(@_); }
sub gen_random_string { my $self = shift; return Concierge::Auth::Generators::gen_random_string(@_); }
sub gen_word_phrase   { my $self = shift; return Concierge::Auth::Generators::gen_word_phrase(@_); }
# Does NOT call the original deprecated methods; calls their replacements
# But these are still considered deprecated method names
sub gen_token         { my $self = shift; return Concierge::Auth::Generators::gen_random_token(@_); }
sub gen_crypt_token   { my $self = shift; return Concierge::Auth::Generators::gen_random_token(@_); }

1;

__END__

=head1 NAME

Concierge::Auth::Base - Base class / contract for Concierge::Auth backends

=head1 VERSION

v0.5.2

=head1 SYNOPSIS

    # This is a base class - do not use directly
    # Backend implementations inherit from this class:

    package Concierge::Auth::MyBackend;
    use parent 'Concierge::Auth::Base';

    sub authenticate {
        my ($self, $user_id, $credential) = @_;
        # Implementation...
    }

    # Implement other required methods...

=head1 DESCRIPTION

C<Concierge::Auth::Base> defines the interface that every C<Concierge::Auth>
backend must implement, regardless of how it stores or verifies identity.
Backend implementations (C<Concierge::Auth::Pwd> for the built-in
password-file backend, or alternatives such as an LDAP-backed backend)
inherit from this class and must implement the five methods below.

The contract is deliberately expressed at the level of the domain
operations Concierge itself needs to perform -- "add a user," "change
credentials," "is this ID known," "authenticate" -- rather than at the
level of any one backend's natural storage primitives. The built-in
password-file backend, for example, satisfies this contract internally
using its own file-locking, hashing, and response-formatting helpers, but
those are private implementation detail of that backend and are not part
of this contract. A backend with a fundamentally different
storage/verification model (e.g. an LDAP directory) satisfies the same
five methods however fits its model, without needing anything resembling
those primitives at all.

Concierge::Auth backends are intentionally independent of
L<Concierge::Users> and of the main L<Concierge> orchestrator. No method
in this contract receives a Concierge or Users handle, and no conforming
backend should reach into either. C<Concierge> is responsible for
composing calls to Auth and Users as separate steps; a backend that needs
data from outside its own store should receive it as an argument to the
relevant method, not via a persistent back-reference.

Users typically do not interact with this class directly - they use
Concierge::Auth (or a Concierge desk) which manages the configured backend
object internally.

=head2 The Generators Guarantee

Concierge also relies on its configured authentication class's object
to generate identifiers for other uses not connected to
authentication. For example, applications might not authenticate
visitors or guests (see C<admit_visitor>/C<checkin_guest> in
L<Concierge>) -- they are simply assigned a generated identifier for
cookie/session purposes, with no credential involved at all. That
capability (C<gen_uuid>, C<gen_random_id>, C<gen_random_token>,
C<gen_random_string>, C<gen_word_phrase>) is therefore independent of
the five-method contract above.

Unlike the five required methods, this guarantee is satisfied with a
working I<default> rather than a die-stub: C<Concierge::Auth::Base>
itself implements each of these methods by delegating to the plain
functions of the same name in L<Concierge::Auth::Generators>. Every
backend that inherits from this class -- including
C<Concierge::Auth::Pwd> -- gets them for free and does not need to
implement or compose anything to satisfy this guarantee. A backend is
still free to override any one (or all) of these methods with its own
logic (for example, an LDAP backend that wants directory-issued
identifiers instead of locally-generated ones); Perl's normal method
resolution means an override in the subclass simply takes precedence
over the default here.

=head1 REQUIRED METHODS

Backend implementations must implement the following methods.

=head2 new

    my $backend = Concierge::Auth::MyBackend->new(%args);

Constructor. C<%args> is backend-specific (e.g. a password-file path for
C<Concierge::Auth::Pwd>, or a directory URI/bind DN for an LDAP backend).

=head2 authenticate

    my $result = $backend->authenticate($user_id, $credential);

Verifies that C<$credential> is valid for C<$user_id>. This is a pure
credential check with no side effects -- session creation and any other
orchestration remain the responsibility of C<Concierge>.

Must return:

    { success => 1 }

Or on failure:

    { success => 0, message => "Error description" }

=head2 is_id_known

    my $result = $backend->is_id_known($user_id);

Checks whether C<$user_id> is a known identity to this backend's
authority (e.g. present in the password file, or resolvable in the LDAP
directory). This answers "known to the credential authority," not
"known to the application" -- Concierge composes this with
L<Concierge::Users> separately if it needs the broader answer.

Must return:

    { success => 1, known => 1|0 }

=head2 enroll

    my $result = $backend->enroll($user_id, $credential, \%opts);

Establishes C<$user_id> as a known identity with the given credential.
C<%opts> is backend-specific and optional. For a backend where identities
are provisioned externally (e.g. LDAP accounts managed by directory
admins), this may mean confirming the ID already exists in the external
authority rather than creating anything locally; the C<status> key
distinguishes the two cases so Concierge can decide whether any
additional orchestration (e.g. also creating a Users profile record) is
needed.

Must return:

    { success => 1, user_id => $user_id, status => 'created' }

    # or, for backends where enrollment is external:
    { success => 1, user_id => $user_id, status => 'already_known' }

Or on failure:

    { success => 0, message => "Error description" }

=head2 change_credentials

    my $result = $backend->change_credentials($user_id, $new_credential);

Replaces the credential on file for an existing C<$user_id>. Fails if the
ID is not known to this backend.

Must return:

    { success => 1, user_id => $user_id }

Or on failure:

    { success => 0, message => "Error description" }

=head2 revoke

    my $result = $backend->revoke($user_id);

Removes C<$user_id> as a known identity from this backend. Symmetric with
L</enroll>. For backends where identities are provisioned externally,
this may mean severing the local association rather than deleting
anything in the external authority; the same C<status> convention as
L</enroll> may be used to distinguish these cases if useful to callers.

Must return:

    { success => 1, user_id => $user_id }

Or on failure:

    { success => 0, message => "Error description" }

=head1 GENERATOR METHODS

Backend implementations inherit working defaults for the following
methods and are not required to override them -- see L</The Generators
Guarantee> above. Each delegates to the identically-named function in
L<Concierge::Auth::Generators> and preserves its C<wantarray>
C<(value)>/C<(value, message)> dual-return convention, which is
distinct from the C<{ success =E<gt> ... }> hashref convention used by
the five required methods above.

=head2 gen_uuid, gen_random_id, gen_random_token, gen_random_string, gen_word_phrase

See the identically-named functions in L<Concierge::Auth::Generators> for
each one's signature and behavior.

=head2 gen_token

Deprecated alias for L<gen_random_token|/"gen_uuid, gen_random_id, gen_random_token, gen_random_string, gen_word_phrase">.

=head2 gen_crypt_token

Deprecated alias for L<gen_random_token|/"gen_uuid, gen_random_id, gen_random_token, gen_random_string, gen_word_phrase">.

See L<Concierge::Auth::Generators> for the parameters and return value
of each.

=head1 SEE ALSO

L<Concierge::Auth::Pwd> - built-in password-file backend implementation

L<Concierge::Auth::Generators> - functional interface this class's
default generator methods delegate to

L<Concierge::Auth> - Auth manager / facade

L<Concierge::Sessions::Base> - the analogous contract for session storage
backends, which this module is modeled on

L<Concierge> - main orchestrator; see its EXTENSIBILITY section for the
component substitution pattern

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

Artistic License 2.0

=cut
