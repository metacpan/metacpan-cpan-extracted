package Catalyst::Plugin::Authentication::LDAP;

use strict;
use NEXT;
use Net::LDAP;

our $VERSION = '0.02';

=head1 NAME

Catalyst::Plugin::Authentication::LDAP - LDAP Authentication for Catalyst *DEPRECATED, use Store::LDAP instead*

=head1 DEPRECATED

WARNING: This module has been superseded by L<Catalyst::Plugin::Authentication::Store::LDAP>, and is therefore no longer
maintained.

=head1 SYNOPSIS

    use Catalyst 'Authentication::LDAP';
    __PACKAGE__->config->{authentication} = (
        ldap_server            => 'ldap://ldap.mycompany.com',
        default_naming_context => 'dc=mycompany,dc=com',
        user_context           => 'cn=users',
        user_append            => '@mycompany.com',
        user_filter            => '(&(objectclass=user)(objectcategory=user)(samaccountname=__USER__*))',
        group_attribute        => 'memberOf',
    );
    $c->login( $user, $password );
    $c->logout;
    $c->session_login( $user, $password );
    $c->session_logout;
    $c->roles(qw/customer admin/);

=head1 DESCRIPTION

This plugin allows you to authenticate your web users using an LDAP server.  See the L<Configuration>
section for more details on how to set it up.  This module was designed with Active Directory in mind
and has not yet been tested using other LDAP servers.  Patches are welcome that enable support for
other servers.

Note that this plugin requires a session plugin like C<Catalyst::Plugin::Session::FastMmap>.

=head1 CONFIGURATION

This plugin is configured by passing an "authentication" hash reference to your application's
config method.  The following keys are supported:

    ldap_server

Required.  Specify the full URI to your LDAP server.  Some examples are: ldap://ldap.mycompany.com,
ldap://pdc:1234, ldaps://secure.ldap.mycompany.com

    default_naming_context => 'dc=mycompany,dc=com'

Required.  This is the base context for your server.  In most cases, this is a string of two
or more "dc" values separated by commas.

    user_context => 'cn=users',

Optional.  The context to be used when querying a user's details.  This value is prefixed to the
default_naming_context.  The default value should be suitable for Active Directory servers.  If you
do not intend to use role-based authentication, you can ignore this option.

    user_append = '@mycompany.com'
    
Optional.  This string will be appended to a user's login name when authenticating to the server.
Active Directory servers require the user to be specified as "username@mycompany.com".

    user_filter => '(&(objectclass=user)(objectcategory=user)(samaccountname=__USER__*))'

Optional.  This filter is used to retrieve the user's account details, specifically the list of
groups the user is a member of.  For Active Directory servers, the default value should be suitable.
The string __USER__ is replaced by the current username.  If you do not intend to use role-based
authentication, you can ignore this option.

    group_attribute => 'memberOf'
    
Optional.  Specify which attribute contains the list of groups/roles the user is a member of.

=head2 METHODS

=over 4

=item login

Attempt to authenticate a user. Takes username/password as arguments,

    $c->login( $user, $password );

User remains authenticated until end of request.

=cut

sub login {
    my ( $c, $user, $password ) = @_;
    return 1 if $c->request->{user};
    
    my $ldap_server = $c->config->{authentication}->{ldap_server};
    my $dnc = $c->config->{authentication}->{default_naming_context};
    my $user_append = $c->config->{authentication}->{user_append} || '';
    my $user_context = $c->config->{authentication}->{user_context} || 'cn=users';
    my $user_filter = $c->config->{authentication}->{user_filter} ||
        '(&(objectclass=user)(objectcategory=user)(samaccountname=__USER__*))'; 
    my $group_attribute = $c->config->{authentication}->{group_attribute} || 'memberOf';
    
    eval {
        my $ldap = Net::LDAP->new( $ldap_server ) or die "Unable to connect to LDAP server $ldap_server: $@";
        
        my $rc = $ldap->bind( $user . $user_append, password => $password );
        die "User authentication failed for $user: " . $rc->error if $rc->code;
        
        # since most LDAP servers require a password on every connection, we have to query
        # the user's groups/roles here and store them in the session, since we won't have the
        # password available later
        $user_filter =~ s/__USER__/$user/;
        my $search = $ldap->search(
            base => $user_context . "," . $dnc,
            scope => "sub",
            filter => $user_filter,
        );
        die "Unable to retrieve user details for $user: " . $search->error if $search->code;

        foreach my $entry ($search->entries) {
            my @groups = $entry->get_value( $group_attribute );
            $c->log->debug( "LDAP: User is a member of: " . join ",", @groups ) if $c->debug && scalar @groups;
            $c->session->{roles} = \@groups if scalar @groups;
        }
        
        $ldap->unbind;
    };
    if ($@) {
        $c->log->warn("LDAP: $@");
    } else {
        $c->request->{user} = $user;
        return 1;
    }
    return 0;
}

=item logout

Log out the user. will not clear the session, so user will still remain
logged in at next request unless session_logout is called.

=cut

sub logout {
    my $c = shift;
    $c->request->{user} = undef;
}

=item process_permission

check for permissions. used by the 'roles' function.

=cut

sub process_permission {
    my ( $c, $roles ) = @_;
    if ($roles) {
        return 1 if $#$roles < 0;
        my $string = join ' ', @$roles;
        if ( $c->process_roles($roles) ) {
            $c->log->debug(qq/Permission granted "$string"/) if $c->debug;
        }
        else {
            $c->log->debug(qq/Permission denied "$string"/) if $c->debug;
            return 0;
        }
    }
    return 1;
}

=item roles

Check permissions for roles and return true or false.

    $c->roles(qw/foo bar/);

Returns an arrayref containing the verified roles.

    my @roles = @{ $c->roles };

=cut

sub roles {
    my $c = shift;
    $c->{roles} ||= [];
    my $roles = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
    if ( $_[0] ) {
        my @roles;
        foreach my $role (@$roles) {
            push @roles, $role unless grep $_ eq $role, @{ $c->{roles} };
        }
        return 1 unless @roles;
        if ( $c->process_permission( \@roles ) ) {
            $c->{roles} = [ @{ $c->{roles} }, @roles ];
            return 1;
        }
        else { return 0 }
    }
    return $c->{roles};
}

=item session_login

Persistently login the user. The user will remain logged in
until he clears the session himself, or session_logout is
called.

    $c->session_login( $user, $password );

=cut

sub session_login {
    my ( $c, $user, $password ) = @_;
    return 0 unless $c->login( $user, $password );
    $c->session->{user} = $user;
    return 1;
}

=item session_logout

Session logout. will delete the user object from the session.

=cut

sub session_logout {
    my $c = shift;
    $c->logout;
    $c->session->{user} = undef;
    $c->session->{roles} = undef;
}

=back

=head2 EXTENDED METHODS

=over 4

=item prepare_action

sets $c->request->{user} from session.

=cut

sub prepare_action {
    my $c = shift;
    $c->NEXT::prepare_action(@_);
    $c->request->{user} = $c->session->{user};
}

=item setup

sets up $c->config->{authentication}.

=cut

sub setup {
    my $c    = shift;
    my $conf = $c->config->{authentication};
    $conf = ref $conf eq 'ARRAY' ? {@$conf} : $conf;
    $c->config->{authentication} = $conf;
    return $c->NEXT::setup(@_);
}

=back

=head2 OVERLOADED METHODS

=over 4

=item process_roles 

Takes an arrayref of roles and checks if user has the supplied roles. 
Returns 1/0.

=cut

sub process_roles {
    my ( $c, $roles ) = @_;

	return 0 unless exists $c->{session}->{roles};
    
    for my $role (@$roles) {
        return 1 if grep $_ =~ /$role/i, @{ $c->{session}->{roles} };
    }
    return 0;
}

=back

=head1 LIMITATIONS

Because many LDAP servers require a password to query information, the user's group/role
data must be queried and stored at the time they login.  This means that group/role data
updated on the LDAP server after a user logs in will not be reflected in their session until
they logout and log back in.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Authentication::CDBI>.

=head1 AUTHOR

Andy Grundman, C<andy@hybridized.org>

Based on Catalyst::Plugin::Authentication::CDBI by:
Sebastian Riedel, C<sri@cpan.org>
Marcus Ramberg, C<mramberg@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
