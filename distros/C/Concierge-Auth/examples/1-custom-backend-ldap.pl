#!/usr/bin/env perl

=head1 NAME

1-custom-backend-ldap.pl - Sketch of a minimal Concierge::Auth::LDAP backend

=head1 DESCRIPTION

Concierge::Auth::Base defines a small, domain-level contract (five methods:
C<new>, C<authenticate>, C<is_id_known>, C<enroll>, C<change_credentials>,
C<revoke>) that any backend must satisfy. The built-in C<Concierge::Auth::Pwd>
backend satisfies it using a flat password file; this example sketches what
a I<directory-backed> implementation looks like instead, given the
connection details a developer would normally supply (host, bind DN, bind
password, base DN, and the attribute holding each user's identifier).

This is a sketch for documentation purposes, not a shipped backend: it
requires L<Net::LDAP> (not a dependency of this distribution) and a real
directory server to actually run against. The point is to show how little
code is needed to satisfy the contract once you have the required
connection info -- the shape of each method, not a production-hardened
LDAP client.

=cut

use v5.36;

package Concierge::Auth::LDAP {
    use Carp   qw/croak/;
    use parent qw/Concierge::Auth::Base/;

    # Swap this for `use Net::LDAP;` to run against a real directory.
    # Kept as a soft require so this example loads/documents cleanly even
    # without Net::LDAP installed.
    my $HAVE_NET_LDAP = eval { require Net::LDAP; 1 };

    ## new: connect and bind with the *service* account used to search the
    ## directory (as opposed to the end user's own credentials, which are
    ## only used transiently inside authenticate()).
    ## Required args: host, bind_dn, bind_password, base_dn
    ## Optional args:  id_attr (default 'uid')
    sub new {
        my ($class, %args) = @_;

        for my $required (qw/host bind_dn bind_password base_dn/) {
            croak "Concierge::Auth::LDAP: missing required arg '$required'"
                unless defined $args{$required} && length $args{$required};
        }

        croak "Concierge::Auth::LDAP: Net::LDAP is not installed"
            unless $HAVE_NET_LDAP;

        my $ldap = Net::LDAP->new($args{host})
            or croak "Concierge::Auth::LDAP: could not connect to $args{host}: $@";

        my $bind = $ldap->bind($args{bind_dn}, password => $args{bind_password});
        croak "Concierge::Auth::LDAP: service bind failed: " . $bind->error
            if $bind->code;

        return bless {
            ldap    => $ldap,
            base_dn => $args{base_dn},
            id_attr => $args{id_attr} // 'uid',
        }, $class;
    }

    ## _dn_for: internal helper, not part of the contract. Looks up the
    ## distinguished name for a given user_id via search, since a real
    ## directory's DN usually isn't just "<id_attr>=<id>,<base_dn>".
    sub _dn_for ($self, $user_id) {
        my $result = $self->{ldap}->search(
            base   => $self->{base_dn},
            filter => "($self->{id_attr}=$user_id)",
            attrs  => ['dn'],
        );
        return undef unless $result->count == 1;
        return ($result->entries)[0]->dn;
    }

    ## authenticate: verify a submitted credential. Implemented as a bind
    ## attempt using the user's own DN and submitted password -- no
    ## passwords are ever read or stored locally.
    sub authenticate ($self, $user_id, $credential) {
        my $dn = $self->_dn_for($user_id);
        return { success => 0, message => "Unknown user_id" }
            unless $dn;

        my $bind = $self->{ldap}->bind($dn, password => $credential);
        return { success => 0, message => "Invalid credentials" }
            if $bind->code;

        return { success => 1 };
    }

    ## is_id_known: existence check only -- no credential involved.
    sub is_id_known ($self, $user_id) {
        my $dn = $self->_dn_for($user_id);
        return { success => 1, known => $dn ? 1 : 0 };
    }

    ## enroll: directory identities are provisioned by directory admins,
    ## not by this backend, so enroll() confirms rather than creates.
    ## Concierge::Auth::Pwd's enroll() *creates* a record; an
    ## externally-provisioned backend like this one instead reports
    ## whether the ID is already known to the authority.
    sub enroll ($self, $user_id, $credential, $opts = undef) {
        my $dn = $self->_dn_for($user_id);
        return { success => 0, message => "ID not found in directory" }
            unless $dn;

        return { success => 1, user_id => $user_id, status => 'already_known' };
    }

    ## change_credentials: modify the userPassword attribute via the
    ## service bind. Real directories often require the *user's own* bind
    ## (or directory-specific password-change extended ops) rather than a
    ## simple attribute replace under a service account; that decision is
    ## directory-policy-specific and intentionally simplified here.
    sub change_credentials ($self, $user_id, $new_credential) {
        my $dn = $self->_dn_for($user_id);
        return { success => 0, message => "ID not found in directory" }
            unless $dn;

        my $result = $self->{ldap}->modify(
            $dn, replace => { userPassword => $new_credential },
        );
        return { success => 0, message => $result->error }
            if $result->code;

        return { success => 1, user_id => $user_id };
    }

    ## revoke: sever the local association. This deliberately does NOT
    ## delete the directory entry -- that's outside this backend's
    ## authority, matching the Base.pm contract note that externally
    ## provisioned backends revoke local standing, not the external record.
    sub revoke ($self, $user_id) {
        my $dn = $self->_dn_for($user_id);
        return { success => 0, message => "ID not found in directory" }
            unless $dn;

        return { success => 1, user_id => $user_id };
    }

    # gen_uuid / gen_random_token / gen_word_phrase / etc. are inherited
    # from Concierge::Auth::Base for free -- no need to reimplement them.
}

# --- Usage, exactly like any other backend -------------------------------

say "=== Concierge::Auth::LDAP sketch ===";
say "";
say "  my \$auth = Concierge::Auth->new(";
say "      backend_class => 'Concierge::Auth::LDAP',";
say "      host          => 'ldaps://directory.example.com',";
say "      bind_dn       => 'cn=service,dc=example,dc=com',";
say "      bind_password => \$service_password,";
say "      base_dn       => 'ou=people,dc=example,dc=com',";
say "      id_attr       => 'uid',   # optional, defaults to 'uid'";
say "  );";
say "";
say "  my \$result = \$auth->authenticate('alice', \$submitted_password);";
say "  say \$result->{success} ? 'ok' : \"failed: \$result->{message}\";";
say "";
say "No caller-visible difference from Concierge::Auth::Pwd -- same";
say "5-method contract, same hashref return shapes, same Concierge::Auth";
say "facade. The only thing that changed is what happens *inside* those";
say "five methods.";

__END__

=head1 WHY NOT OAUTH HERE

OAuth doesn't map onto this same C<authenticate($user_id, $credential)>
shape as directly as LDAP does, because Concierge::Auth's contract assumes
the application itself receives a submitted credential to check. In a
typical OAuth flow the application never sees the user's password at all --
it receives a token from the provider after a redirect-based exchange the
application mediates but doesn't perform inline.

A Concierge::Auth::OAuth backend would still satisfy the same five methods,
but with different inputs:

  authenticate($user_id, $token)   # verify an access/ID token instead of a password
  is_id_known($user_id)            # check a local cache of provider subjects
  enroll($user_id, $token, \%opts) # record a new provider subject locally
  change_credentials(...)          # often a no-op or "revoke + re-link"; OAuth
                                    #   providers manage credentials themselves
  revoke($user_id)                 # sever the local association only

The token exchange itself (redirect, authorization code, provider callback)
happens *before* any Concierge::Auth method is called at all -- it's
outside this contract's scope, the same way this LDAP sketch's directory
bind happens outside of any web framework's routing layer. Concierge::Auth
only needs to know how to verify what the application hands it.

=head1 SEE ALSO

=over 4

=item * L<Concierge::Auth::Base> - the five-method backend contract

=item * L<Concierge::Auth::Pwd> - the built-in reference implementation

=back

=cut
