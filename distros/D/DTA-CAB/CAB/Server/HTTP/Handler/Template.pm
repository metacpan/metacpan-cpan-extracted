##-*- Mode: CPerl -*-

## File: DTA::CAB::Server::HTTP::Handler::Template.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA::CAB::Server::HTTP::Handler class: Template-Toolkit templates
##======================================================================

package DTA::CAB::Server::HTTP::Handler::Template;
use DTA::CAB::Server::HTTP::Handler;
use HTTP::Status;
use HTTP::Date qw();
use Template;
use Carp;
use strict;

our @ISA = qw(DTA::CAB::Server::HTTP::Handler);

##--------------------------------------------------------------
## Aliases
BEGIN {
  DTA::CAB::Server::HTTP::Handler->registerAlias(
						 'DTA::CAB::Server::Server::HTTP::Handler::template' => __PACKAGE__,
						 'template' => __PACKAGE__,
						);
}

##--------------------------------------------------------------
## $h = $class_or_obj->new(%options)
##  + options:
##     contentType => $mimeType,    ##-- default: text/plain ; alt. e.g. 'text/plain; charset="UTF-8"'
##     src         => $src,         ##-- template source (filename, fh, or string ref)
##     config      => \%ttconfig,   ##-- see Template(3pm)
##     vars        => \%vars,       ##-- extra vars
##     tmpl        => $template,    ##-- Template object (created by prepare())
sub new {
  my $that = shift;
  return bless {
		src=>undef,
		contentType=>undef,
		config => {
			   INTERPOLATE => 1,
			   POST_CHOMP  => 0,
			   EVAL_PERL   => 1,
			   ABSOLUTE    => 1,
			   RELATIVE    => 1,
			  },
		vars => {},
		tmpl => undef,
		@_,
	       }, ref($that)||$that;
}

## $bool = $obj->prepare($srv)
sub prepare {
  my ($h,$srv) = @_;
  $h->{tmpl} = Template->new($h->{config})
    or $h->logconfess("could not create Template object: $Template::ERROR");
  return 1;
}

## $rsp = $h->run($server, $localPath, $clientConn, $httpRequest)
sub run {
  my ($h,$srv,$path,$csock,$hreq) = @_;

  my $vars = { h=>$h, srv=>$srv, path=>$path, csock=>$csock, hreq=>$hreq, src=>$h->{src}, %{$h->{vars}||{}} };
  my $tmpl = $h->{tmpl};
  my $data = '';

  $tmpl->process($h->{src}, $vars, \$data)
    or return $h->cerror($csock, undef, 'template error: '.$tmpl->error);

  return HTTP::Response->new(RC_OK,
			     status_message(RC_OK),
			     [
			      ($h->{contentType} ? ('Content-Type' => $h->{contentType}) : qw()),
			     ],
			     $data);
}


1; ##-- be happy
