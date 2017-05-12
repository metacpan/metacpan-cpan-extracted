package Catalyst::Plugin::Authentication::Credential::HTTP::Proxy;
use base qw/Catalyst::Plugin::Authentication::Credential::Password/;

use strict;
use warnings;

use String::Escape ();
use URI::Escape    ();
use Catalyst       ();
use Catalyst::Plugin::Authentication::Credential::HTTP::User;
use Carp qw/croak/;

our $VERSION = "0.02";


sub authenticate_http_proxy {
    my $c = shift;

    my $headers = $c->req->headers;

    croak "url setting required for authentication" 
        unless $c->config->{authentication}{http_proxy}{url};
    if ( my ( $user, $password ) = $headers->authorization_basic ) {

        my $ua=Catalyst::Plugin::Authentication::Credential::HTTP::User->new;
        $ua->credentials($user,$password);
        my $resp= $ua->get($c->config->{authentication}{http_proxy}{url});
        if ( $resp->is_success ) {
            if ( my $store = $c->config->{authentication}{http_proxy}{store} ) {
                $user = $store->get_user($user);
            } elsif ( my $user_obj = $c->get_user($user) ) {
                $user = $user_obj;
            }
            unless ($user) {
                $c->log->debug("User '$user' doesn't exist in the default store")
                    if $c->debug;
                return;
            }
            $c->set_authenticated($user);
            return 1;
        } elsif ( $c->debug ) {
            $c->log->info('Remote authentication failed:'.$resp->message);
            return 0;
        }
    } elsif ( $c->debug ) {
        $c->log->info('No credentials provided for basic auth');
        return 0;
    }
}

sub authorization_required {
    my ( $c, %opts ) = @_;

    return 1 if $c->authenticate_http_proxy;

    $c->authorization_required_response( %opts );

    die $Catalyst::DETACH;
}

sub authorization_required_response {
    my ( $c, %opts ) = @_;
    
    $c->res->status(401);

    my @opts;

    if ( my $realm = $opts{realm} ) {
        push @opts, sprintf 'realm=%s', String::Escape::qprintable($realm);
    }

    if ( my $domain = $opts{domain} ) {
        Catalyst::Excpetion->throw("domain must be an array reference")
          unless ref($domain) && ref($domain) eq "ARRAY";

        my @uris =
          $c->config->{authentication}{http}{use_uri_for}
          ? ( map { $c->uri_for($_) } @$domain )
          : ( map { URI::Escape::uri_escape($_) } @$domain );

        push @opts, qq{domain="@uris"};
    }

    $c->res->headers->www_authenticate(join " ", "Basic", @opts);
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Credential::HTTP - DEPRECATED HTTP Basic authentication
for Catlayst.

=head1 SYNOPSIS

    use Catalyst qw/
        Authentication
        Authentication::Store::Moose
        Authentication::Store::Elk
        Authentication::Credential::HTTP::Proxy
    /;

    $c->config->{authentication}{http_proxy}= {
        url  =>'http://elkland.no/auth',
        store => 'Authentication::Store::Moose'
    };
    
    sub foo : Local { 
        my ( $self, $c ) = @_;

        $c->authorization_required( realm => "foo" ); # named after the status code ;-)

        # either user gets authenticated or 401 is sent

        do_stuff();
    }

    # with ACL plugin
    __PACKAGE__->deny_access_unless("/path", sub { $_[0]->authenticate_http });

    sub end : Private {
        my ( $self, $c ) = @_;

        $c->authorization_required_response( realm => "foo" );
        $c->error(0);
    }

=head1 DEPRECATED

This module is deprecated by L<Catalyst::Authentication::HTTP::proxy>, please do not use this code in new applications.

=head1 DESCRIPTION

This moduule lets you use HTTP Proxy authentication with
L<Catalyst::Plugin::Authentication>.

Currently this module only supports the Basic scheme, but upon request Digest
will also be added. Patches welcome!


=head1 CONFIG

This module reads config from $c->config->{authentication}{http_proxy}. The following settings
are supported:

=over 4

=item url

Required. A url protected with basic authentication to authenticate against.

=item store

To specify what store to use. will use the default store if not set.

=back

=head1 METHODS

=over 4

=item authorization_required

Tries to C<authenticate_http_proxy>, and if that fails calls
C<authorization_required_response> and detaches the current action call stack.

=item authenticate_http_proxy

Looks inside C<< $c->request->headers >> and processes the basic (badly named)
authorization header. Then authenticates this against the provided url.

=item authorization_required_response

Sets C<< $c->response >> to the correct status code, and adds the correct
header to demand authentication data from the user agent.

=back

=head1 AUTHORS

Marcus Ramberg C<mramberg@cpan.org>

=head1 COPYRIGHT & LICENSE

        Copyright (c) 2005 the aforementioned authors. All rights
        reserved. This program is free software; you can redistribute
        it and/or modify it under the same terms as Perl itself.

=cut

