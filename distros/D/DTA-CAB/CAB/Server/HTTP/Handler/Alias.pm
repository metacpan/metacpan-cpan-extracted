##-*- Mode: CPerl -*-

## Alias: DTA::CAB::Server::HTTP::Handler::Alias.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA::CAB::Server::HTTP::Handler class: path alias
##======================================================================

package DTA::CAB::Server::HTTP::Handler::Alias;
use DTA::CAB::Server::HTTP::Handler;
use HTTP::Status;
use HTTP::Date qw();
use Carp;
use strict;

our @ISA = qw(DTA::CAB::Server::HTTP::Handler);

##--------------------------------------------------------------
## Aliases
BEGIN {
  DTA::CAB::Server::HTTP::Handler->registerAlias(
						 'DTA::CAB::Server::Server::HTTP::Handler::alias' => __PACKAGE__,
						 'alias' => __PACKAGE__,
						);
}

##--------------------------------------------------------------
## $h = $class_or_obj->new(%options)
##  + options:
##     path => $aliasPath
sub new {
  my $that = shift;
  return bless { path=>'', @_ }, ref($that)||$that;
}

## $bool = $obj->prepare($srv)
sub prepare { return 1; }

## $rsp = $h->run($server, $localPath, $clientConn, $httpRequest)
sub run {
  my ($h,$srv,$path,$csock,$hreq) = @_;
  my $uri2 = $hreq->uri;
  $uri2->path($h->{path});
  my $h2 = $srv->getPathHandler($uri2);
  return $srv->clientError($csock, RC_NOT_FOUND, "cannot resolve alias URI: ", $uri2->as_string) if (!$h2);
  return $h2->run($srv,$path,$csock,$hreq);
}


1; ##-- be happy

