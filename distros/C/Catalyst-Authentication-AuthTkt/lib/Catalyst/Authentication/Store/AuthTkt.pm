package Catalyst::Authentication::Store::AuthTkt;
use Moose;
use namespace::autoclean;
use Apache::AuthTkt 0.08;
use Carp;
use Data::Dump qw( dump );
use Catalyst::Authentication::User::AuthTkt;

has 'cookie_name' => ( is => 'rw', isa => 'Str' );
has 'aat'         => ( is => 'rw', isa => 'Apache::AuthTkt', required => 1, );
has 'config'      => ( is => 'rw', isa => 'HashRef', required => 1, );
has 'debug'       => ( is => 'rw', isa => 'Int', );

our $VERSION = '0.16';

=head1 NAME

Catalyst::Authentication::Store::AuthTkt - shim for Apache::AuthTkt

=head1 DESCRIPTION

This module implements the Catalyst::Plugin::Authentication API for Apache::AuthTkt.
See Catalyst::Authentication::AuthTkt for complete user documentation.

=head1 METHODS

=cut

=head2 new( I<config>, I<app> )

Instantiate the store. I<config> is used to set the cookie name to check in find_user(),
and optionally, to set the C<timeout> and C<timeout_refresh> values.

=cut

sub new {
    my ( $class, $config, $app ) = @_;
    my $self = bless( { cookie_name => $config->{cookie_name} || 'auth_tkt' },
        $class );

    # init AuthTkt
    my @aat_args = ();
    for my $param (qw( ignore_ip cookie_name domain timeout timeout_refresh ))
    {
        if ( exists $config->{$param} ) {
            push( @aat_args, $param => $config->{$param} );
        }
    }
    if ( $config->{conf} ) {
        $self->aat(
            Apache::AuthTkt->new( conf => $config->{conf}, @aat_args ) );
    }
    elsif ( $config->{secret} ) {
        $self->aat(
            Apache::AuthTkt->new( secret => $config->{secret}, @aat_args ) );
    }
    else {
        croak "conf or secret configuration required";
    }
    unless ( defined $config->{timeout} ) {
        $config->{timeout}
            = defined $self->aat->timeout ? $self->aat->timeout : 7200;
    }
    unless ( defined $config->{timeout_refresh} ) {
        $config->{timeout_refresh}
            = defined $self->aat->timeout_refresh
            ? $self->aat->timeout_refresh
            : 0.5;
    }

    # make sure timeout is in seconds format
    if ( $config->{timeout} =~ m/\D/ ) {
        $config->{timeout}
            = $self->aat->convert_time_seconds( $config->{timeout} );
    }

    $self->config($config);    # cache for later
    $self->debug( $config->{debug}
            || $ENV{CATALYST_DEBUG}
            || $ENV{PERL_DEBUG}
            || 0 );

    return $self;
}

=head2 find_user( I<userinfo>, I<context> )

Returns a Catalyst::Authentication::User::AuthTkt object on success,
undef on failure.

find_user() checks the I<context> request object for a cookie named cookie_name()
or a param named cookie_name(), in that order. If neither are present, or if
present but invalid, find_user() returns undef.

See also the 'mock' feature as per the
example in Catalyst::Authentication::AuthTkt SYNOPSIS.

=cut

sub find_user {
    my ( $self, $userinfo, $c ) = @_;

    $c->log->debug('AuthTkt: authenticating request') if $self->debug;

    # mock feature for development when you just want to mimic cookie
    # (e.g., when running under localhost or different domain than
    # your auth server)
    if ( $self->config->{mock} ) {
        my %user = %{ $self->config->{mock} };

        $c->log->debug("AuthTkt: using mock user $user{id}") if $self->debug;

        return Catalyst::Authentication::User::AuthTkt->new(
            {   id     => $user{id},
                data   => '',
                ts     => '',
                tokens => $user{tokens},
                ticket => 'mock_auth_cookie',
            }
        );
    }

    # if no cookie or param, return undef
    my $cookie = $c->req->cookie( $self->cookie_name )
        || $c->req->params->{ $self->cookie_name };
    unless ($cookie) {
        $c->log->debug(
            "AuthTkt: No cookie or param for " . $self->cookie_name )
            if $self->debug;
        $c->logout;    # in case user was in session
        return;
    }

    # unpack cookie
    my $t = ref($cookie) ? $cookie->value : $cookie;
    if ( !defined $t or !length $t ) {
        $c->log->debug(
            "AuthTkt: no ticket value in cookie " . $self->cookie_name )
            if $self->debug;
        $c->logout;    # in case user was in session
        return;
    }
    $c->log->debug("AuthTkt: $t") if $self->debug;

# running under fcgi (others?) the REMOTE_ADDR env var is not set, which Apache::AuthTkt
# uses to check the validity of tickets if the ip_addr is not set explicitly in the AA object.
# So we set it explicitly here.
# if the 'ignore_ip' config option were used consistently (i.e. both setting and checking)
# then this hack would not be necessary, but we can't vouch for how the ticket was set.
    if (   !exists $ENV{REMOTE_ADDR}
        or $self->config->{use_req_address}
        or $ENV{REMOTE_ADDR} ne $c->req->address )
    {
        my $ipaddr = $self->config->{use_req_address} || $c->req->address;
        $c->log->debug("setting REMOTE_ADDR to $ipaddr")
            if $self->debug;
        $self->aat->{ip_addr} = $ipaddr;
    }

    my $ticket = $self->aat->validate_ticket($t);

    unless ( defined $ticket ) {
        $c->log->debug("AuthTkt: bad ticket detected") if $self->debug;
        $c->log->debug( "AuthTkt: parsed ticket looks like: "
                . dump( $self->aat->parse_ticket($t) ) )
            if $self->debug;
        $c->logout;    # in case user was in session
        return;
    }

    if ( $self->ticket_expired( $c, $ticket ) ) {
        $c->logout;    # in case user was in session
        return;
    }

    if ( $self->renew_ticket( $c, $ticket ) ) {
        $ticket = $self->aat->validate_ticket(
            $c->response->cookies->{ $self->cookie_name }->{value} );
    }

    $c->log->debug( 'AuthTkt: ' . dump($ticket) ) if $self->debug;

    # return user object
    return Catalyst::Authentication::User::AuthTkt->new(
        {   id     => $ticket->{uid},
            data   => $ticket->{data},
            ts     => $ticket->{ts},
            tokens => [ split( m/\s*,\s*/, $ticket->{tokens} || '' ) ],
            ticket => ref($cookie) ? $cookie->value : $cookie,
        }
    );

}

=head2 ticket_expired( I<context>, I<ticket> )

Returns true if the I<ticket> has expired. I<ticket> should be a hashref
as returned from the Apache::AuthTkt->valid_ticket() method.

=cut

sub ticket_expired {
    my ( $self, $c, $ticket ) = @_;
    my $config    = $self->config;
    my $time_left = $ticket->{ts} + $config->{timeout} - time();

    if ( $time_left < 0 ) {

        if ( $self->debug ) {
            $c->log->debug( "AuthTkt: ticket has expired at "
                    . localtime( $ticket->{ts} + $config->{timeout} ) );
            $c->log->debug( "AuthTkt: timestamp in ticket was $ticket->{ts} ("
                    . localtime( $ticket->{ts} )
                    . ')' );
            $c->log->debug( 'AuthTkt: ticket was ' . dump($ticket) );
            $c->log->debug( "AuthTkt: cookie was "
                    . dump( $c->req->cookies->{ $config->{cookie_name} } ) );
            $c->log->debug(
                "AuthTkt: timeout in config was $config->{timeout}");
            $c->log->debug("AuthTkt: time left was $time_left");
        }
        return 1;
    }
    return 0;
}

=head2 renew_ticket( I<context>, I<ticket> )

If the C<timeout_refresh> configuration option is set and the opportunity
window is appropriate, the cookie ticket value will be regenerated
and set in the I<context> response() object. The new ticket will also
be set in the I<context> user() object if one exists.

Returns true if the ticket was renewed, false otherwise.

=cut

sub renew_ticket {
    my ( $self, $c, $ticket ) = @_;
    my $config       = $self->config;
    my $time_left    = $ticket->{ts} + $config->{timeout} - time();
    my $more_seconds = $config->{timeout_refresh} * $config->{timeout};

    if (   $config->{timeout_refresh}
        && $time_left < $more_seconds )
    {
        $c->log->debug(
            "AuthTkt: ticket eligible for renewal: " . dump($ticket) )
            if $self->debug;

        # extend the expiration time of the cookie
        my $authtkt         = $self->aat;
        my $existing_cookie = $c->req->cookies->{ $self->cookie_name };
        if ( $self->debug ) {
            $c->log->debug( "existing_cookie: " . dump($existing_cookie) );
            $c->log->debug( "authtkt: " . dump($authtkt) );
        }
        my $new_ticket = $authtkt->ticket(
            uid     => $ticket->{uid},
            ip_addr => $self->config->{use_req_address} || $c->request->address,
            data    => $ticket->{data},
            tokens  => $ticket->{tokens},
        );
        my $domain = $authtkt->domain;
        my $path   = '/';
        if ($existing_cookie) {
            $domain = $existing_cookie->domain if $existing_cookie->domain;
            $path   = $existing_cookie->path   if $existing_cookie->path;
        }
        $c->response->cookies->{ $self->cookie_name } = {
            value  => $new_ticket,
            path   => $path,
            domain => $domain,
        };
        $c->log->debug( 'AuthTkt: new cookie: '
                . dump( $c->response->cookies->{ $self->cookie_name } ) )
            if $self->debug;
        if ( defined $c->user ) {
            $c->user->ticket($new_ticket);
        }
        return 1;
    }
    return 0;
}

=head2 expire_ticket

Sets AuthTkt cookie with expiration in the past and an empty value.

=cut

sub expire_ticket {
    my ( $self, $c ) = @_;
    my $cookie_name     = $self->cookie_name;
    my $existing_cookie = $c->req->cookie($cookie_name);
    if ( !$existing_cookie ) {
        $c->log->warn("no cookie with name $cookie_name found to expire");
        return;
    }
    $existing_cookie->value( [] );
    $existing_cookie->expires( time - 100 );
    $existing_cookie->domain( $self->aat->domain )
        if $self->aat->domain;
    $c->res->cookies->{$cookie_name} = $existing_cookie;
    $c->log->debug( "AuthTkt: cookie reset as " . dump($existing_cookie) )
        if $self->debug;
}

=head2 for_session( I<context>, I<user> )

Implements required method for stashing I<user> in a session.

=cut

sub for_session {
    my ( $self, $c, $user ) = @_;
    return $user;    # we serialize the whole user
}

=head2 from_session( I<context>, I<frozen_user> )

Implements required method for de-serializing I<frozen_user> 
from a session store.

=cut

sub from_session {
    my ( $self, $c, $frozen_user ) = @_;
    return $frozen_user;
}

=head1 AUTHOR

Peter Karman, C<< <karman at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-authentication-authtkt at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Authentication-AuthTkt>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Authentication::AuthTkt

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Authentication-AuthTkt>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Authentication-AuthTkt>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Authentication-AuthTkt>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Authentication-AuthTkt>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Catalyst::Authentication::AuthTkt
