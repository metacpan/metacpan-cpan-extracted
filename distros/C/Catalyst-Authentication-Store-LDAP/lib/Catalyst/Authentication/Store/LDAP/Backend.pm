
=pod

=head1 NAME

Catalyst::Authentication::Store::LDAP::Backend
  - LDAP authentication storage backend.

=head1 SYNOPSIS

    # you probably just want Store::LDAP under most cases,
    # but if you insist you can instantiate your own store:

    use Catalyst::Authentication::Store::LDAP::Backend;

    use Catalyst qw/
        Authentication
        Authentication::Credential::Password
    /;

    my %config = (
            'ldap_server' => 'ldap1.yourcompany.com',
            'ldap_server_options' => {
                'timeout' => 30,
            },
            'binddn' => 'anonymous',
            'bindpw' => 'dontcarehow',
            'start_tls' => 1,
            'start_tls_options' => {
                'verify' => 'none',
            },
            'user_basedn' => 'ou=people,dc=yourcompany,dc=com',
            'user_filter' => '(&(objectClass=posixAccount)(uid=%s))',
            'user_scope' => 'one',  # or 'sub' for Active Directory
            'user_field' => 'uid',
            'user_search_options' => {
                'deref' => 'always',
                'attrs' => [qw( distinguishedname name mail )],
            },
            'user_results_filter' => sub { return shift->pop_entry },
            'entry_class' => 'MyApp::LDAP::Entry',
            'user_class' => 'MyUser',
            'use_roles' => 1,
            'role_basedn' => 'ou=groups,dc=yourcompany,dc=com',
            'role_filter' => '(&(objectClass=posixGroup)(member=%s))',
            'role_scope' => 'one',
            'role_field' => 'cn',
            'role_value' => 'dn',
            'role_search_options' => {
                'deref' => 'always',
            },
            'role_search_as_user' => 0,
            'persist_in_session'  => 'all',
    );

    our $users = Catalyst::Authentication::Store::LDAP::Backend->new(\%config);

=head1 DESCRIPTION

You probably want L<Catalyst::Authentication::Store::LDAP>.

Otherwise, this lets you create a store manually.

See the L<Catalyst::Authentication::Store::LDAP> documentation for
an explanation of the configuration options.

=head1 METHODS

=cut

package Catalyst::Authentication::Store::LDAP::Backend;
use base qw( Class::Accessor::Fast );

use strict;
use warnings;

our $VERSION = '1.016';

use Catalyst::Authentication::Store::LDAP::User;
use Net::LDAP;
use Catalyst::Utils ();
use Catalyst::Exception;

BEGIN {
    __PACKAGE__->mk_accessors(
        qw( ldap_server ldap_server_options binddn
            bindpw entry_class user_search_options
            user_filter user_basedn user_scope
            user_attrs user_field use_roles role_basedn
            role_filter role_scope role_field role_value
            role_search_options start_tls start_tls_options
            user_results_filter user_class role_search_as_user
            persist_in_session
            )
    );
}

=head2 new($config)

Creates a new L<Catalyst::Authentication::Store::LDAP::Backend> object.
$config should be a hashref, which should contain the configuration options
listed in L<Catalyst::Authentication::Store::LDAP>'s documentation.

Also sets a few sensible defaults.

=cut

sub new {
    my ( $class, $config ) = @_;

    unless ( defined($config) && ref($config) eq "HASH" ) {
        Catalyst::Exception->throw(
            "Catalyst::Authentication::Store::LDAP::Backend needs to be configured with a hashref."
        );
    }
    my %config_hash = %{$config};
    $config_hash{'binddn'}      ||= 'anonymous';
    $config_hash{'user_filter'} ||= '(uid=%s)';
    $config_hash{'user_scope'}  ||= 'sub';
    $config_hash{'user_field'}  ||= 'uid';
    $config_hash{'role_filter'} ||= '(memberUid=%s)';
    $config_hash{'role_scope'}  ||= 'sub';
    $config_hash{'role_field'}  ||= 'cn';
    $config_hash{'use_roles'}   = '1'
        unless exists $config_hash{use_roles};
    $config_hash{'start_tls'}   ||= '0';
    $config_hash{'entry_class'} ||= 'Catalyst::Model::LDAP::Entry';
    $config_hash{'user_class'}
        ||= 'Catalyst::Authentication::Store::LDAP::User';
    $config_hash{'role_search_as_user'} ||= 0;
    $config_hash{'persist_in_session'}  ||= 'username';
    Catalyst::Exception->throw('persist_in_session must be either username or all')
        unless $config_hash{'persist_in_session'} =~ /\A(?:username|all)\z/;

    Catalyst::Utils::ensure_class_loaded( $config_hash{'user_class'} );
    my $self = \%config_hash;
    bless( $self, $class );
    return $self;
}

=head2 find_user( I<authinfo>, $c )

Creates a L<Catalyst::Authentication::Store::LDAP::User> object
for the given User ID.  This is the preferred mechanism for getting a
given User out of the Store.

I<authinfo> should be a hashref with a key of either C<id> or
C<username>. The value will be compared against the LDAP C<user_field> field.

=cut

sub find_user {
    my ( $self, $authinfo, $c ) = @_;
    return $self->get_user( $authinfo->{id} || $authinfo->{username}, $c );
}

=head2 get_user( I<id>, $c)

Creates a L<Catalyst::Authentication::Store::LDAP::User> object
for the given User ID, or calls C<new> on the class specified in
C<user_class>.  This instance of the store object, the results of
C<lookup_user> and $c are passed as arguments (in that order) to C<new>.
This is the preferred mechanism for getting a given User out of the Store.

=cut

sub get_user {
    my ( $self, $id, $c ) = @_;
    my $user = $self->user_class->new( $self, $self->lookup_user($id), $c );
    return $user;
}

=head2 ldap_connect

Returns a L<Net::LDAP> object, connected to your LDAP server. (According
to how you configured the Backend, of course)

=cut

sub ldap_connect {
    my ($self) = shift;
    my $ldap;
    if ( defined( $self->ldap_server_options() ) ) {
        $ldap
            = Net::LDAP->new( $self->ldap_server,
            %{ $self->ldap_server_options } )
            or Catalyst::Exception->throw($@);
    }
    else {
        $ldap = Net::LDAP->new( $self->ldap_server )
            or Catalyst::Exception->throw($@);
    }
    if ( defined( $self->start_tls ) && $self->start_tls =~ /(1|true)/i ) {
        my $mesg;
        if ( defined( $self->start_tls_options ) ) {
            $mesg = $ldap->start_tls( %{ $self->start_tls_options } );
        }
        else {
            $mesg = $ldap->start_tls;
        }
        if ( $mesg->is_error ) {
            Catalyst::Exception->throw( "TLS Error: " . $mesg->error );
        }
    }
    return $ldap;
}

=head2 ldap_bind($ldap, $binddn, $bindpw)

Bind's to the directory.  If $ldap is undef, it will connect to the
LDAP server first.  $binddn should be the DN of the object you wish
to bind as, and $bindpw the password.

If $binddn is "anonymous", an anonymous bind will be performed.

=cut

sub ldap_bind {
    my ( $self, $ldap, $binddn, $bindpw ) = @_;
    $ldap ||= $self->ldap_connect;
    if ( !defined($ldap) ) {
        Catalyst::Exception->throw("LDAP Server undefined!");
    }

    # if username is present, make sure password is present too.
    # see https://rt.cpan.org/Ticket/Display.html?id=81908
    if ( !defined $binddn ) {
        $binddn = $self->binddn;
        $bindpw = $self->bindpw;
    }

    if ( $binddn eq "anonymous" ) {
        $self->_ldap_bind_anon($ldap);
    }
    else {
        if ($bindpw) {
            my $mesg = $ldap->bind( $binddn, 'password' => $bindpw );
            if ( $mesg->is_error ) {
                Catalyst::Exception->throw(
                    "Error on Initial Bind: " . $mesg->error );
            }
        }
        else {
            $self->_ldap_bind_anon( $ldap, $binddn );
        }
    }
    return $ldap;
}

sub _ldap_bind_anon {
    my ( $self, $ldap, $dn ) = @_;
    my $mesg = $ldap->bind($dn);
    if ( $mesg->is_error ) {
        Catalyst::Exception->throw( "Error on Bind: " . $mesg->error );
    }
}

=head2 ldap_auth( $binddn, $bindpw )

Connect to the LDAP server and do an authenticated bind against the
directory. Throws an exception if connecting to the LDAP server fails.
Returns 1 if binding succeeds, 0 if it fails.

=cut

sub ldap_auth {
    my ( $self, $binddn, $bindpw ) = @_;
    my $ldap = $self->ldap_connect;
    if ( !defined $ldap ) {
        Catalyst::Exception->throw("LDAP server undefined!");
    }
    my $mesg = $ldap->bind( $binddn, password => $bindpw );
    return $mesg->is_error ? 0 : 1;
}

=head2 lookup_user($id)

Given a User ID, this method will:

  A) Bind to the directory using the configured binddn and bindpw
  B) Perform a search for the User Object in the directory, using
     user_basedn, user_filter, and user_scope.
  C) Assuming we found the object, we will walk it's attributes
     using L<Net::LDAP::Entry>'s get_value method.  We store the
     results in a hashref. If we do not find the object, then
     undef is returned.
  D) Return a hashref that looks like:

     $results = {
        'ldap_entry' => $entry, # The Net::LDAP::Entry object
        'attributes' => $attributes,
     }

This method is usually only called by find_user().

=cut

sub lookup_user {
    my ( $self, $id ) = @_;

    # Trim trailing space or we confuse ourselves
    $id =~ s/\s+$//;
    my $ldap = $self->ldap_bind;
    my @searchopts;
    if ( defined( $self->user_basedn ) ) {
        push( @searchopts, 'base' => $self->user_basedn );
    }
    else {
        Catalyst::Exception->throw(
            "You must set user_basedn before looking up users!");
    }
    my $filter = $self->_replace_filter( $self->user_filter, $id );
    push( @searchopts, 'filter' => $filter );
    push( @searchopts, 'scope'  => $self->user_scope );
    if ( defined( $self->user_search_options ) ) {
        push( @searchopts, %{ $self->user_search_options } );
    }
    my $usersearch = $ldap->search(@searchopts);

    return undef if ( $usersearch->is_error );

    my $userentry;
    my $user_field     = $self->user_field;
    my $results_filter = $self->user_results_filter;
    my $entry;
    if ( defined($results_filter) ) {
        $entry = &$results_filter($usersearch);
    }
    else {
        $entry = $usersearch->pop_entry;
    }
    if ( $usersearch->pop_entry ) {
        Catalyst::Exception->throw(
                  "More than one entry matches user search.\n"
                . "Consider defining a user_results_filter sub." );
    }

    # a little extra sanity check with the 'eq' since LDAP already
    # says it matches.
    # NOTE that Net::LDAP returns exactly what you asked for, but
    # because LDAP is often case insensitive, FoO can match foo
    # and so we normalize with lc().
    if ( defined($entry) ) {
        unless ( lc( $entry->get_value($user_field) ) eq lc($id) ) {
            Catalyst::Exception->throw(
                "LDAP claims '$user_field' equals '$id' but results entry does not match."
            );
        }
        $userentry = $entry;
    }

    $ldap->unbind;
    $ldap->disconnect;
    unless ($userentry) {
        return undef;
    }
    my $attrhash;
    foreach my $attr ( $userentry->attributes ) {
        my @attrvalues = $userentry->get_value($attr);
        if ( scalar(@attrvalues) == 1 ) {
            $attrhash->{ lc($attr) } = $attrvalues[0];
        }
        else {
            $attrhash->{ lc($attr) } = \@attrvalues;
        }
    }

    eval { Catalyst::Utils::ensure_class_loaded( $self->entry_class ) };
    if ( !$@ ) {
        bless( $userentry, $self->entry_class );
        $userentry->{_use_unicode}++;
    }
    my $rv = {
        'ldap_entry' => $userentry,
        'attributes' => $attrhash,
    };
    return $rv;
}

=head2 lookup_roles($userobj, [$ldap])

This method looks up the roles for a given user.  It takes a
L<Catalyst::Authentication::Store::LDAP::User> object
as it's first argument, and can optionally take a I<Net::LDAP> object which
is used rather than the default binding if supplied.

It returns an array containing the role_field attribute from all the
objects that match it's criteria.

=cut

sub lookup_roles {
    my ( $self, $userobj, $ldap ) = @_;
    if ( $self->use_roles == 0 || $self->use_roles =~ /^false$/i ) {
        return ();
    }
    $ldap ||= $self->role_search_as_user
        ? $userobj->ldap_connection : $self->ldap_bind;
    my @searchopts;
    if ( defined( $self->role_basedn ) ) {
        push( @searchopts, 'base' => $self->role_basedn );
    }
    else {
        Catalyst::Exception->throw(
            "You must set up role_basedn before looking up roles!");
    }
    my $filter_value = $userobj->has_attribute( $self->role_value );
    if ( !defined($filter_value) ) {
        Catalyst::Exception->throw( "User object "
                . $userobj->username
                . " has no "
                . $self->role_value
                . " attribute, so I can't look up it's roles!" );
    }
    my $filter = $self->_replace_filter( $self->role_filter, $filter_value );
    push( @searchopts, 'filter' => $filter );
    push( @searchopts, 'scope'  => $self->role_scope );
    push( @searchopts, 'attrs'  => [ $self->role_field ] );
    if ( defined( $self->role_search_options ) ) {
        push( @searchopts, %{ $self->role_search_options } );
    }
    my $rolesearch = $ldap->search(@searchopts);
    my @roles;
RESULT: foreach my $entry ( $rolesearch->entries ) {
        push( @roles, $entry->get_value( $self->role_field ) );
    }
    return @roles;
}

sub _replace_filter {
    my $self    = shift;
    my $filter  = shift;
    my $replace = shift;
    $replace =~ s/([*()\\\x{0}])/sprintf '\\%02x', ord($1)/ge;
    $filter =~ s/\%s/$replace/g;
    return $filter;
}

=head2 user_supports

Returns the value of
Catalyst::Authentication::Store::LDAP::User->supports(@_).

=cut

sub user_supports {
    my $self = shift;

    # this can work as a class method
    Catalyst::Authentication::Store::LDAP::User->supports(@_);
}

=head2 from_session( I<id>, I<$c>, $frozenuser )

Revives a serialized user from storage in the session.

Supports users stored with a different persist_in_session setting.

=cut

sub from_session {
    my ( $self, $c, $frozenuser ) = @_;

    # we need to restore the user depending on the current storage of the
    # user in the session store which might differ from what
    # persist_in_session is set to now
    if ( ref $frozenuser eq 'HASH' ) {
        # we can rely on the existance of this key if the user is a hashref
        if ( $frozenuser->{persist_in_session} eq 'all' ) {
            return $self->user_class->new( $self, $frozenuser->{user}, $c, $frozenuser->{_roles} );
        }
    }

    return $self->get_user( $frozenuser, $c );
}

1;

__END__

=head1 AUTHORS

Adam Jacob <holoway@cpan.org>

Some parts stolen shamelessly and entirely from
L<Catalyst::Plugin::Authentication::Store::Htpasswd>.

Currently maintained by Peter Karman <karman@cpan.org>.

=head1 THANKS

To nothingmuch, ghenry, castaway and the rest of #catalyst for the help. :)

=head1 SEE ALSO

L<Catalyst::Authentication::Store::LDAP>, L<Catalyst::Authentication::Store::LDAP::User>, L<Catalyst::Plugin::Authentication>, L<Net::LDAP>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005 the aforementioned authors. All rights
reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

