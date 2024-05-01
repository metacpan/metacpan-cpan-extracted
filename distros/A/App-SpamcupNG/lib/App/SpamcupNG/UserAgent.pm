package App::SpamcupNG::UserAgent;
use warnings;
use strict;
use Carp qw(confess);
use LWP::UserAgent 6.72;
use HTTP::Request 6.44;
use Log::Log4perl 1.57 qw(get_logger :levels);
use HTTP::CookieJar::LWP 0.014;
use Mozilla::PublicSuffix v1.0.6;
use HTTP::Request::Common 6.44 qw(POST);

our $VERSION = '0.018'; # VERSION

=head1 NAME

App::SpamcupNG::UserAgent - the SpamcupNG HTTP user agent

=head1 SYNOPSIS

=head1 DESCRIPTION

This class is responsible to interact with the Spamcop website, providing
requests and returning the HTML responses.

=head1 METHODS

=head2 new

Creates a new instance.

Expects as parameter:

- version: a string of the version of SpamcupNG.

Returns a new instance.

=cut

sub new {
    my ( $class, $version ) = @_;
    confess 'The parameter version is required' unless ($version);

    my $self = {
        name             => 'SpamcupNG user agent',
        version          => $version,
        members_url      => 'https://members.spamcop.net/',
        code_login_url   => 'https://www.spamcop.net/?code=',
        report_url       => 'https://www.spamcop.net/sc?id=',
        form_login_url   => 'https://www.spamcop.net/mcgi',
        domain           => 'https://www.spamcop.net/',
        password_field   => 'password',
        current_base_url => undef
    };

    bless $self, $class;

    my $ua = LWP::UserAgent->new(
        agent             => ( $self->{name} . '/' . $version ),
        protocols_allowed => ['https'],
        cookie_jar        => HTTP::CookieJar::LWP->new
    );

    # for form based authentication
    push @{ $ua->requests_redirectable }, 'POST';
    $self->{user_agent} = $ua;
    return $self;
}

=head2 user_agent

Returns a string with the HTTP header user-agent that will be used by the inner
HTTP user agent.

=cut

sub user_agent {
    my $self = shift;
    return $self->{user_agent}->agent;
}

=head2 login

Execute the login to Spamcop website.

If form based authentication is in use, it will login just once and return the
response of HTTP GET to Spamcop root URL.

Expect as parameters:

=over

=item *

id: the ID of a Spamcop account.

=item *

password: the password of a Spamcop account.

=back

Returns the HTTP response (HTML content) as a scalar reference.

=cut

# copied from HTTP::Request::as_string
sub _request_line {
    my $request  = shift;
    my $req_line = $request->method || "-";
    my $uri      = $request->uri;
    $uri = ( defined $uri ) ? $uri->as_string : "-";
    $req_line .= " $uri";
    my $proto = $request->protocol;
    $req_line .= " $proto" if $proto;
    return $req_line;
}

sub _redact_auth_req {
    my ( $self, $request ) = @_;
    my @lines;

    return $request->as_string if ( $self->_is_authenticated );

    if ( $request->method eq 'POST' ) {
        push( @lines, _request_line($request) );
        push( @lines, $request->headers_as_string );
        my @params = split( '&', $request->content );
        my %params =
          map { my @tmp = split( '=', $_ ); $tmp[0] => $tmp[1] } @params;
        croak(  'Unexpected request content, missing '
              . $self->{password_field}
              . ' field' )
          unless exists( $params{ $self->{password_field} } );
        my $redacted = '*' x length( $params{ $self->{password_field} } );
        $params{ $self->{password_field} } = $redacted;

        while ( my ( $key, $value ) = each %params ) {
            push( @lines, "$key=$value" );
        }
    }
    else {
        @lines = split( "\n", $request->as_string );
        my $secret   = ( split( /\s/, $lines[1] ) )[2];
        my $redacted = '*' x length($secret);
        $lines[1] =~ s/$secret/$redacted/;
    }

    return join( "\n", @lines );
}

sub _dump_cookies {
    my $self = shift;
    my @cookies =
      $self->{user_agent}->cookie_jar->dump_cookies( { persistent => 1 } );
    my $counter = 0;
    my @dump;

    foreach my $cookie (@cookies) {
        push( @dump, ( $counter . ' => ' . $cookie ) );
    }

    return join( "\n", @dump );
}

sub _is_authenticated {
    my $self = shift;
    return $self->{user_agent}->cookie_jar->cookies_for( $self->{domain} );
}

sub login {
    my ( $self, $id, $password, $is_basic ) = @_;
    $is_basic = 0 unless ( defined($is_basic) );
    my $logger = get_logger('SpamcupNG');
    my $request;

    if ( $logger->is_debug ) {
        $logger->debug( "Initial cookies:\n" . $self->_dump_cookies );
    }

    if ( $self->_is_authenticated ) {
        $logger->debug('Already authenticated');
        $request = HTTP::Request->new( GET => $self->{domain} );
    }
    else {
        if ($password) {

            if ($is_basic) {
                $request = HTTP::Request->new( GET => $self->{members_url} );
                $request->authorization_basic( $id, $password );
            }
            else {
                $request = POST $self->{form_login_url},
                  [
                    username                => $id,
                    $self->{password_field} => $password,
                    duration                => '+12h',
                    action                  => 'cookielogin',
                    returnurl               => '/'
                  ];
            }
        }
        else {
            $request =
              HTTP::Request->new( GET => $self->{code_login_url} . $id );
        }
    }

    $request->protocol('HTTP/1.1');

    if ( $logger->is_debug() ) {
        $logger->debug(
            "Request details:\n" . ( $self->_redact_auth_req($request) ) );
    }

    my $response = $self->{user_agent}->request($request);

    if ( $logger->is_debug() ) {
        $logger->debug( "Got response:\n" . $response->as_string );
        $logger->debug(
            "After authentication cookies:\n" . $self->_dump_cookies );
    }

    return \( $response->content ) if ( $response->is_success );

    my $status = $response->status_line();

    if ( $response->code() == 500 ) {
        $logger->fatal("Can\'t connect to server: $status");
    }
    else {
        $logger->warn($status);

        if ( ($password) and ( $is_basic == 0 ) ) {
            $logger->warn('Retrying with basic authentication');
            return $self->login( $id, $password, 1 );
        }

        $logger->fatal(
'Cannot connect to server or invalid credentials. Please verify your username and password and try again.'
        );
    }

    return undef;
}

=head2 spam_report

Fetches a SPAM report.

Expects as parameter a report ID.

Returns the HTML content as a scalar reference.

=cut

sub spam_report {
    my ( $self, $report_id ) = @_;
    my $logger  = get_logger('SpamcupNG');
    my $request = HTTP::Request->new( GET => $self->{report_url} . $report_id );

    if ( $logger->is_debug ) {
        $logger->debug( "Request to be sent:\n" . $request->as_string );
    }

    my $response = $self->{user_agent}->request($request);
    $self->{current_base_url} = $response->base;

    if ( $logger->is_debug ) {
        $logger->debug( "Got HTTP response:\n" . $response->as_string );
    }

    unless ( $response->is_success ) {
        $logger->fatal("Can't connect to server. Try again later.");
        return undef;
    }

    return \( $response->content );
}

=head2 base

Returns the current base URL provided by the last response of getting a SPAM
report.

=cut

sub base {
    my $self = shift;
    return $self->{current_base_url};
}

=head2 complete_report

Complete the SPAM report, by confirming it's information is OK.

Returns the HTML content as a scalar reference.

=cut

sub complete_report {
    my ( $self, $http_request ) = @_;
    my $logger   = get_logger('SpamcupNG');
    my $response = $self->{user_agent}->request($http_request);

    if ( $logger->is_debug ) {
        $logger->debug( "Got HTTP response:\n" . $response->as_string );
    }

    unless ( $response->is_success ) {
        $logger->fatal('Cannot connect to server. Try again later. Quitting.');
        return undef;
    }

    return \( $response->content );
}

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 of Alceu Rodrigues de Freitas Junior,
E<lt>glasswalk3r@yahoo.com.brE<gt>

This file is part of App-SpamcupNG distribution.

App-SpamcupNG is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

App-SpamcupNG is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
App-SpamcupNG. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
