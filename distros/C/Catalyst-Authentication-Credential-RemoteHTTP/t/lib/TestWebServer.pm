#!/usr/bin/perl
#
# This is a test web server used to check http authentication
# It always requires basic authentication, with a fixed user/pass
# All successful request return a short piece of text with details
# of the request embedded....
#
package TestWebServer;
use base qw(HTTP::Server::Simple::CGI);

use strict;
use warnings;

use Carp;
use MIME::Base64;

# hash of usernames (keys) and passwords (values)
my $user_set = {
    insecure => '123456',
    paranoid => 'very_secure_password!',
};

# This next set of methods re-implements most of HTTP::Server::Simple::Authen
# because that and its dependancies are not typically installed in
# a normal catalyst installation
sub do_authenticate {
    my $self = shift;

    if ( ( $ENV{HTTP_AUTHORIZATION} || '' ) =~ /^Basic (.*?)$/ ) {
        my ( $user, $pass ) = split /:/, ( MIME::Base64::decode($1) || ':' );
        ## warn "user = $user, pass = $pass\n";
        if ( exists( $user_set->{$user} ) && ( $user_set->{$user} eq $pass ) ) {
            return $user;
        }
    }

    return;
}

sub authen_realm { "Authorized area" }

sub authenticate {
    my $self = shift;

    my $user = $self->do_authenticate();
    unless ( defined $user ) {
        my $realm = $self->authen_realm();
        print "HTTP/1.0 401\r\n";
        print qq(WWW-Authenticate: Basic realm="$realm"\r\n\r\n);
        print "Authentication required.";
        return;
    }
    return $user;
}

sub handle_request {
    my ( $self, $cgi ) = @_;

    my $user = $self->authenticate or return;

    print(
        "HTTP/1.0 200 OK\r\n",
        $cgi->header,
        $cgi->start_html("Response"),
        $cgi->h1("Response"),
        $cgi->p( sprintf( 'Path is %s',          $cgi->path_info() ) ),
        $cgi->p( sprintf( 'Authenticated as %s', $user ) ),
        $cgi->end_html
    );
}

1;
