#########
# Author:        Andy Jenkinson
# Created:       2008-02-20
# Last Modified: $Date: 2010-11-02 11:57:52 +0000 (Tue, 02 Nov 2010) $ $Author: zerojinx $
# Id:            $Id: ip.pm 688 2010-11-02 11:57:52Z zerojinx $
# Source:        $Source$
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/Authenticator/ip.pm $
#
# Authenticator implementation using IP information to control access.
#
package Bio::Das::ProServer::Authenticator::ip;

use strict;
use warnings;
use Net::IP;
use Socket;
use Carp;
use base qw(Bio::Das::ProServer::Authenticator);

our $VERSION = do { my ($v) = (q$LastChangedRevision: 688 $ =~ /\d+/mxsg); $v; };

sub authenticate {
  my ($self, $params) = @_;

  # Reset stored IP
  delete $self->{'ip'};
  # IP addresses checked:
  # 1. All IPs from the X-Forwarded-For header
  # 2. The socket address
  my @query_ips = $params->{'request'} ? split /\s*,\s*/mxs, $params->{'request'}->header('X-Forwarded-For') : ();
  if ($params->{'peer_addr'}) {
    push @query_ips, inet_ntoa( $params->{'peer_addr'} );
  }
  @query_ips = map {
    Net::IP->new($_) || croak 'Unable to determine client IP: '.Net::IP::Error
  } @query_ips;

  # Check each client IP against each whitelist IP range
  for my $query (@query_ips) {
    for my $whitelist (@{$self->{'allow_ip'}}) {
      $self->{'debug'} && carp 'Checking '.$query->ip.' against IP range '.$whitelist->print;
      my $match = $query->overlaps($whitelist);
      if (defined $match && ($match == $IP_A_IN_B_OVERLAP || $match == $IP_IDENTICAL)) {
        $self->{'ip'} = $query->ip;
        return $self->allow($params);
      }
    }
  }

  return $self->deny($params);
}

sub init {
  my $self = shift;
  $self->{'allow_ip'} = [ map {
    Net::IP->new($_) || croak 'Unable to parse whitelist IP range: '.Net::IP::Error
  } split /\s*[,;]+\s*/mxs, $self->{'config'}->{'authallow'}||q() ];
  return;
}

sub ip {
  my $self = shift;
  return $self->{'ip'};
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::Authenticator::ip - authenticates DAS requests by IP address

=head1 VERSION

$LastChangedRevision: 688 $

=head1 SYNOPSIS

To authenticate a request:

  my $auth = Bio::Das::ProServer::Authenticator::ip->new({
    'config' => {
                 'authallow' => $, # IP whitelist
                },
  });
  
  my $allow = $auth->authenticate({
    'peer_addr' => $, # packed
    'request'   => $, # HTTP::Request object
    ...
  });

Once authenticated the IP address is stored:

  if ($allow) {
    my $ip    = $auth->ip();
  }

To simply perform IP address authentication but not deny requests, configure the
source with a lax IP range (e.g. "0/0"). This allows the source to alter its
behaviour in a more subtle fashion (e.g provide different data for different
sites).

=head1 DESCRIPTION

Authenticates requests according to a 'whitelist' of IP address ranges. Requests
from clients not within one of these ranges are denied.

The IP addresses that are checked against the whitelist are:
  1) that of the socket connection
  2) those listed in the X-Forwarded-For HTTP header

The latter is necessary for clients and servers operating behind proxies.

IMPORTANT NOTE:
Because IP addresses can be spoofed by clients, this is NOT a robust method of
securing data.

=head1 CONFIGURATION AND ENVIRONMENT

The whitelist for IP addresses is configured in the source INI section, using
any combination of specific, additive, range or CIDR format IPs. Valid
separators are comma and semicolon.

  [mysource]
  authenticator = ip
  authallow     = 1.2.3.4,193.62.196.0 + 255 , 123.123.123.1 - 123.123.123.10 ; 192.168/16

=head1 SUBROUTINES/METHODS

=head2 authenticate : Applies authentication to a request.

  Requires: a hash reference containing details of the DAS request
  Returns:  either nothing (allow) or a HTTP::Response (deny)

  my $allow = $oAuth->authenticate({
    'peer_addr' => $, # packed (socket IP address)
    'request'   => $, # HTTP::Request object (for X-Forwarded-For header)
    ...
  });

=head2 ip : Gets the authenticated IP address

  my $sIp = $oAuth->ip();

=head2 init : Initialises the IP whitelist

=head1 DIAGNOSTICS

  my $auth = Bio::Das::ProServer::Authenticator::ip->new({
    ...
    'debug'  => 1,
  });

=head1 DEPENDENCIES

=over

=item L<Carp|Carp>

=item L<Net::IP|Net::IP>

=item L<Socket|Socket>

=item L<Bio::Das::ProServer::Authenticator|Bio::Das::ProServer::Authenticator>

=back

=head1 BUGS AND LIMITATIONS

Clients that are separated from the server by an anonymising HTTP proxy (i.e.
one that does not reveal the client's IP address in the X-Forwarded-For HTTP
header) will always fail this method of authentication.

Note that clients may spoof an IP address in the X-Forwarded-For header.
Therefore this method of authentication is not a robust security precaution.

=head1 INCOMPATIBILITIES

None reported.

=head1 AUTHOR

Andy Jenkinson <andy.jenkinson@ebi.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 EMBL-EBI

=cut