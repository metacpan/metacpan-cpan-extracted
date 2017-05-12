#########
# Author:        Andy Jenkinson
# Created:       2008-02-20
# Last Modified: $Date: 2010-11-02 11:57:52 +0000 (Tue, 02 Nov 2010) $ $Author: zerojinx $
# Id:            $Id: http.pm 688 2010-11-02 11:57:52Z zerojinx $
# Source:        $Source$
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/Authenticator/http.pm $
#
# Authenticator implementation using a remote authority to control access.
#
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
#
package Bio::Das::ProServer::Authenticator::http;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use Cache::FileCache;
use English qw(-no_match_vars);
use Bio::Das::ProServer::Config;
use base qw(Bio::Das::ProServer::Authenticator);
use English qw(-no_match_vars);

our $VERSION = do { my ($v) = (q$LastChangedRevision: 688 $ =~ /\d+/mxsg); $v; };

sub parse_token {
  my ($self, $params) = @_;
  my $token;

  if (defined $self->{'config'}{'authcookie'}) {
    #########
    # Look in a cookie
    #
    my $k = $self->{'config'}{'authcookie'};
    ($token) = $params->{'request'}->header('cookie') =~ m/$k=([^;]*)/mxs;
    $self->{'debug'} && carp "Authenticator parsed token in cookie: $token";

  } elsif (defined $self->{'config'}{'authparam'}) {
    #########
    # Look in a cgi param
    #
    $token = $params->{'cgi'}->param($self->{'config'}{'authparam'});
    $self->{'debug'} && carp "Authenticator parsed token in param: $token";

  } else {
    #########
    # Look in a specified header (default to 'Authorization')
    #
    $token = $params->{'request'}->header($self->{'config'}{'authheader'}||'Authorization');
    $self->{'debug'} && carp "Authenticator parsed token in header: $token";
  }

  return $token;
}

sub authenticate {
  my ($self, $params) = @_;

  my $token = $self->parse_token($params);
  if(!$token) {
    return $self->deny($params);
  }

  my $auth_response = $self->_cache()->get($token);

  if (defined $auth_response) {
    $self->{'debug'} && carp q(Authenticator found result in cache);

  } else {
    my $url = $self->{'config'}{'authurl'};
    $url    =~ s/%token/$token/mxsg;
    $self->{'debug'} && carp qq(Authenticator issuing remote authentication request to $url);
    $auth_response = $self->_agent()->get($url);

    if ($auth_response->code() != 500) {
      eval {
        delete $auth_response->{'handlers'};
        $self->_cache()->set($token, $auth_response);
        1;
      } or do {
        carp qq[Failed to cache $token response: $EVAL_ERROR];
      };
    }
  }

  if ($auth_response->code() == 200) {
    return $self->allow($params);
  }

  $self->{'debug'} && carp q(Authenticator denied request);
  return $auth_response;
}

sub _cache {
  my $self = shift;

  if (!defined $self->{'_cache'}) {
    $self->{'_cache'} = Cache::FileCache->new({
      'namespace'           => sprintf('%s_auth_cache', $self->{'dsn'}||'unknown'),
      'default_expires_in'  => 30*60, # 30 minutes
      'auto_purge_interval' => 10*60, # 10 minutes
      'auto_purge_on_set'   => 1,
    });

    $self->{'_cache'}->clear();
  }

  return $self->{'_cache'};
}

sub _agent {
  my $self = shift;

  if (!defined $self->{'_agent'}) {
    $self->{'_agent'} = LWP::UserAgent->new(
      env_proxy  => 1,
      keep_alive => 1,
      timeout    => 10,
      agent      => Bio::Das::ProServer::Config::server_version(),
    );
  }

  return $self->{'_agent'};
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::Authenticator::http - authenticates DAS requests by issuing
requests to a remote authority

=head1 VERSION

$LastChangedRevision: 688 $

=head1 SYNOPSIS

To authenticate a request:

  my $auth = Bio::Das::ProServer::Authenticator::http->new({
    'config' => {
                 'authurl'     => 'http://my.example.com/is_root?query=%token',
                },
  });
  
  my $allow = $auth->authenticate({
    'peer_addr' => $, # packed
    'request'   => $, # HTTP::Request object
    'cgi'       => $, # CGI object
    ...
  });
  
=head1 DESCRIPTION

Authenticates DAS requests by connecting to a remote authentication HTTP server.
An authentication token is parsed from the DAS request. By default this should
be in an 'Authorization' header, but the authenticator can be configured to look
in a cookie, CGI parameter or a header with a different name.

The authentication token is referred to a remote server to ask a yes/no question
(e.g. "Is this user in a certain group of users?"). The server, for which the URL
is configurable, should return a status code of either 200 (OK) or a denial
response that will be forwarded to the client. For example if the remote wishes
to deny the request, it could respond with a status code of 403, textual content
for explanation and any necessary custom headers.

Authentication results are cached for 30 minutes in order to minimise the number
of requests issued to the remote server. Internal Server Error responses (code
500) are not cached.

This module may be easily overridden to parse the authentication token in
different ways.

=head1 SUBROUTINES/METHODS

=head2 authenticate : Applies authentication to a request.

  Requires: a hash reference containing details of the DAS request
  Returns:  either nothing (allow) or a HTTP::Response (deny)

  my $allow = $oAuth->authenticate({
    'peer_addr' => $, # packed
    'request'   => $, # HTTP::Request object
    'cgi'       => $, # CGI object
    ...
  });

  The method follows this procedure:
  1. Parse an authentication token from the DAS request (parse_token method).
  2. Check for cached results for this token.
  3. If not found, query the remote server.
  4. Store the response in the cache, unless it is a server error (500)
  4. If the response code is 200 allow the request, otherwise deny.

=head2 parse_token : Parses the DAS request to extract an authentication token

  Requires: a hash reference containing details of the DAS request
  Returns:  a string authentication token

  my $token = $oAuth->parse_token({
    'peer_addr' => $, # packed
    'request'   => $, # HTTP::Request object
    'cgi'       => $, # CGI object
    ...
  });

  Depending on configuration, the authentication token is extracted from:
  1. a named cookie
  2. a named CGI parameter
  3. a named request header
  4. the 'Authorization' request header (default)

This method may be overridden to extract the token in a different manner.

=head1 DIAGNOSTICS

  my $auth = Bio::Das::ProServer::Authenticator::http->new({
    ...
    'debug'  => 1,
  });

=head1 CONFIGURATION AND ENVIRONMENT

The URL to use for remote authentication is configured in the source INI section.
Any instances of "%token" will be replaced by the value of the authentication
token parsed from the DAS request.

  [mysource]
  authenticator = http
  authurl       = http://auth.example.com/is_allowed?query=%token
  ; Optionally define location of auth token (default is 'Authorization' header)
  ; authcookie    = cookiename
  ; authheader    = headername
  ; authparam     = cgiparamname

An HTTP proxy may be specified in the shell environment.

=head1 DEPENDENCIES

=over

=item L<Carp|Carp>

=item L<Bio::Das::ProServer::Authenticator|Bio::Das::ProServer::Authenticator>

=item L<LWP::UserAgent|LWP::UserAgent>

=back

=head1 BUGS AND LIMITATIONS

This authenticator implementation may only be used to ask yes/no questions,
such as "does this token identify a user with sufficient privileges?". Questions
such as "which user does this token identify?" have additional security
implications and are therefore not supported.

=head1 INCOMPATIBILITIES

None reported.

=head1 AUTHOR

Andy Jenkinson <andy.jenkinson@ebi.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 EMBL-EBI

=cut
