package Catalyst::Authentication::Credential::RemoteHTTP;

# ABSTRACT: Authenticate against remote HTTP server

use strict;
use warnings;
use Moose;
use MooseX::Types::Moose qw/Object/;
use 5.008005;
use Catalyst::Exception ();
use Catalyst::Authentication::Credential::RemoteHTTP::UserAgent;
use namespace::autoclean;

our $VERSION = '0.05'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

has realm => ( isa => Object, is => 'ro', required => 1 );

has [qw/http_keep_alive defer_find_user/] => ( is => 'ro', default => 0 );
has username_field => ( is => 'ro', default => 'username' );
has password_field => ( is => 'ro', default => 'password' );

has url => ( is => 'ro', required => 1 );

has [qw/ user_prefix user_suffix /] => ( is => 'ro', default => '' );

sub BUILDARGS {
    my ( $class, $config, $app, $realm ) = @_;

    $config->{realm} = $realm;
    $config->{app}   = $app;
    $config->{class} = $class;
    return $config;
}

sub authenticate {
    my ( $self, $c, $realm, $authinfo ) = @_;

    my $username = $authinfo->{ $self->username_field };
    unless ( defined($username) ) {
        $c->log->debug("No username supplied")
            if $c->debug;
        return;
    }
    ## we remove the password_field before we pass it to the user
    ## routine, as some store modules use all data passed to them
    ## to find a matching user...
    my $userfindauthinfo = { %{$authinfo} };
    delete( $userfindauthinfo->{ $self->password_field } );

    my $user_obj;
    $user_obj = $realm->find_user( $userfindauthinfo, $c )
        unless ( $self->defer_find_user );

    if ( ref($user_obj) || $self->defer_find_user ) {
        my $ua =
            Catalyst::Authentication::Credential::RemoteHTTP::UserAgent->new(
            keep_alive => $self->http_keep_alive ? 1 : 0 );

        # add prefix/suffix to user data to make auth_user, get password
        my $auth_user = sprintf( '%s%s%s', $self->user_prefix, $username, $self->user_suffix );
        my $password = $authinfo->{ $self->password_field };
        $ua->set_credentials( $auth_user, $password );

        # do the request
        my $res = $ua->head( $self->url );

        # did it succeed
        if ( $res->is_success ) {

            # TODO: should we check here that it was actually authenticated?
            # this could be done by ensuring there is a request chain...
            $c->log->debug( "remote http auth succeeded for user " . $auth_user )
                if $c->debug;
        }
        else {
            $c->log->debug( "remote http auth FAILED for user " . $auth_user )
                if $c->debug;
            return;
        }
    }

    # get the user object now, if deferred before
    $user_obj = $realm->find_user( $userfindauthinfo, $c )
        if ( $self->defer_find_user );

    # deal with no-such-user in store
    unless ( ref($user_obj) ) {
        $c->log->debug("Unable to locate user matching user info provided")
            if $c->debug;
        return;
    }
    return $user_obj;
}


1;    # End of Catalyst::Authentication::Credential::RemoteHTTP

__END__
=pod

=for stopwords ACKNOWLEDGEMENTS Daisuke Fixups LDAP Murase NTLM classname http ie linux url validator

=head1 NAME

Catalyst::Authentication::Credential::RemoteHTTP - Authenticate against remote HTTP server

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    package MyApp::Controller::Auth;

    use Catalyst qw/
      Authentication
      /;

    sub login : Local {
        my ( $self, $c ) = @_;

        $c->authenticate( { username => $c->req->param('username'),
                            password => $c->req->param('password') });
    }

=head1 DESCRIPTION

This authentication credential checker takes authentication
information (most often a username) and a password, and attempts to
validate the username and password provided against a remote http
server - ie against another web server.

This is useful for environments where you want to have a single
source of authentication information, but are not able to
conveniently use a networked authentication mechanism such as LDAP.

=head1 CONFIGURATION

    # example
    __PACKAGE__->config(
        'Plugin::Authentication' => {
                    default_realm => 'members',
                    realms => {
                        members => {
                            credential => {
                                class => 'RemoteHTTP',
                                url => 'http://intranet.company.com/authenticated.html',
                                password_field => 'password',
                                username_prefix => 'MYDOMAIN\\',
                                http_keep_alive => 1,
                                defer_find_user => 1,
                            },
                            ...
                    },
        },
    );

=over 4

=item class

The classname used for Credential. This is part of
L<Catalyst::Plugin::Authentication> and is the method by which
Catalyst::Authentication::Credential::RemoteHTTP is loaded as the
credential validator. For this module to be used, this must be set to
'RemoteHTTP'.

=item url

The URL that is used to authenticate the user. The module attempts
to fetch this URL using a HEAD request (to prevent dragging a large
page across the network) with the credentials given. If this fails
then the authentication fails. If no URL is supplied in the config,
then an exception is thrown on startup.

=item username_field

The field in the authentication hash that contains the username.
This may vary, but is most likely 'username'. In fact, this is so
common that if this is left out of the config, it defaults to
'username'.

=item password_field

The field in the authentication hash that contains the password.
This may vary, but is most likely 'password'. In fact, this is so
common that if this is left out of the config, it defaults to
'password'.

=item username_prefix

This is an optional prefix to the username, which is added to the
username before it is used for authenticating to the remote http
server. It may be used (for example) to apply a domain to the
authenticated username.

=item username_suffix

This is an optional suffix to the username, which is added to the
username before it is used for authenticating to the remote http
server. It may be used (for example) to apply a domain to the
authenticated username.

=item http_keep_alive

If C<http_keep_alive> is set then keep_alive is set on the
connections to the remote http server. This is required if you are
using NTLM authentication (since an additional encryption nonce is
passed in the http negotiation). It is optional, but normally
harmless, for other forms of authentication.

=item defer_find_user

Normally the associated user store is queried for user information
before the remote http authentication takes place.

However if, for example, you are using a
L<Catalyst::Authentication::Store::DBIx::Class> store with the
C<auto_create_user> option, then you can end up with invalid users
added to the store. If C<defer_find_user> is set true then the
remote http authentication occurs before the user is queried
against the store, ensuring that any users passed to the store are
known to be valid to the remote http server.

=back

=head1 METHODS

There are no publicly exported routines in the RemoteHTTP module
(or indeed in most credential modules.) However, below is a
description of the routines required by
L<Catalyst::Plugin::Authentication> for all credential modules.

=head2 new( $config, $app, $realm )

Instantiate a new RemoteHTTP object using the configuration hash
provided in $config. A reference to the application is provided as
the second argument.

=head2 authenticate( $authinfo, $c )

Try to log a user in, receives a hashref containing authentication information
as the first argument, and the current context as the second.

=head1 JUSTIFICATION

Why would you use this module rather than one of the similar ones?

This module gives a combination of authentication against a remote
http server, but maintains a local user store. This allows your
authentication to be delegated, but the authorization (for example
allocation and use of roles) to be determined by the local user
store.

Nearly all the other alternatives require you to combine your
authentication and authorization databases.

L<Catalyst::Authentication::Credential::HTTP::Proxy> has a similar
basis, but requires you to use HTTP basic authentication for the
application, which may not be appropriate.

=head1 NTLM NOTES

There are a number of issues relating to NTLM authentication.  In
particular the supporting modules can be rather picky.  To make NTLM
authentication work you must have an installed copy of libwww-perl
that includes L<LWP::Authen::Ntlm> (some linux distributions may drop
this component as it gives you additional dependency requirements over
the basic L<LWP> package).

Additionally you require L<Authen::NTLM> of version 1.02 or later.
There are 2 different CPAN module distributions that provide this
module - but only one of them has the appropriate version number.

Finally, if you are using L<NTLM-1.02> then you need to apply the
patch described in RT entry 9521
L<http://rt.cpan.org/Ticket/Display.html?id=9521>.

When using NTLM authentication the configuration option
C<http_keep_alive> must be set true - otherwise the session to the
remote server is not maintained and the authentication nonce will
be lost between sessions.

You may also need to set C<username_prefix> or C<username_suffix>
to set the correct domain for the authentication, unless the
username as given to your application includes the domain
information.

=head1 ACKNOWLEDGEMENTS

Daisuke Murase <typester@cpan.org> - original
L<Catalyst::Plugin::Authentication::Store::HTTP> used as the base
for a previous version of this module.

The code framework was taken from
L<Catalyst::Authentication::Credential::Password>

Tomas Doran (t0m) <t0m@state51.co.uk> - Fixups to best practice guidelines

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Authentication-Credential-RemoteHTTP>.

=head1 AVAILABILITY

The project homepage is L<https://metacpan.org/release/Catalyst-Authentication-Credential-RemoteHTTP>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Catalyst::Authentication::Credential::RemoteHTTP/>.

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nigel Metheringham <nigelm@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

