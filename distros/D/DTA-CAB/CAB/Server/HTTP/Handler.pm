##-*- Mode: CPerl -*-

## File: DTA::CAB::Server::HTTP::Handler.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + abstract handler API class for DTA::CAB::Server::HTTP
##======================================================================

package DTA::CAB::Server::HTTP::Handler;
use HTTP::Status;
use DTA::CAB::Logger;
use DTA::CAB::Utils qw(:xml);
use UNIVERSAL;
use strict;

BEGIN {
  *isa = \&UNIVERSAL::isa;
  *can = \&UNIVERSAL::can;
}

our @ISA = qw(DTA::CAB::Logger);

##======================================================================
## API
##======================================================================

## $h = $class_or_obj->new(%options)
sub new {
  my $that = shift;
  return bless { @_ }, ref($that)||$that;
}

## $bool = $h->prepare($server,$path)
sub prepare { return 1; }

## $rsp = $h->run($server, $localPath, $clientConn, $httpRequest)
##  + perform local processing
##  + should return a HTTP::Response object to pass to the client
##  + if the call die()s or returns undef, an error response will be
##    sent to the client instead if it the connection is still open
##  + this method may return the data to the client itself; if so,
##    it should close the client connection ($csock->shutdown(2); $csock->close())
##    and return undef to prevent bogus error messages.
sub run {
  my ($h,$srv,$path,$csock,$hreq) = @_;
  $h->logdie("run() method not implemented");
}

## undef = $h->finish($server, $clientConn)
##  + clean up handler state after run()
##  + default implementation does nothing
sub finish {
  return;
}

##======================================================================
## Generic Utilities

## $rsp = $CLASS_OR_OBJECT->response($code=RC_OK, $msg=status_message($code), $hdr, $content)
##  + $hdr may be a HTTP::Headers object, an array or hash-ref
##  + wrapper for HTTP::Response->new()
sub response {
  my $h = shift;
  my $code = shift;
  $code = RC_OK if (!defined($code));
  ##
  my $msg  = @_ ? shift : undef;
  $msg  = status_message($code) if (!defined($msg));
  ##
  my $hdr  = @_ ? shift : undef;
  $hdr  = [] if (!$hdr);
  ##
  return HTTP::Response->new($code,$msg,$hdr) if (!@_);
  return HTTP::Response->new($code,$msg,$hdr,@_);
}

## $rsp = $CLASS_OR_OBJECT->headResponse()
## $rsp = $CLASS_OR_OBJECT->headResponse(\@headers)
## #$rsp = $CLASS_OR_OBJECT->headResponse(\%headers)
## $rsp = $CLASS_OR_OBJECT->headResponse($httpHeaders)
## + rudimentary handling for HEAD requests
sub headResponse {
  my ($h,$hdr) = @_;
  return $h->response(RC_OK,undef,$hdr);
}

## $rsp = $CLASS_OR_OBJECT->errorResponse()
## $rsp = $CLASS_OR_OBJECT->errorResponse($code)
## $rsp = $CLASS_OR_OBJECT->errorResponse($code, @body)
## + rudimentary error responses; workaround for missing root element in html from HTTP::Daemon::ClientConn::send_error()
sub errorResponse {
  my ($h,$code,@body) = @_;
  $code     //= 500;
  my $msg     = status_message($code);
  @body       = ($msg) if (!@body);
  my $content =<<EOT;
<html>
 <head><title>$code $msg</title></head>
 <body>
  <h1>$code $msg</h1>
  @body
 </body>
</html>
EOT
  return $h->response($code,$msg,["Content-Type"=>"text/html"],$content);
}

## $rsp = $CLASS_OR_OBJECT->errorResponseRaw()
## $rsp = $CLASS_OR_OBJECT->errorResponseRaw($code)
## $rsp = $CLASS_OR_OBJECT->errorResponseRaw($code, @body)
## + rudimentary error response for raw (un-escaped) body strings
sub errorResponseRaw {
  my ($h,$code,@body) = @_;
  return $h->errorResponse($code, "<pre>", xml_escape(join('',@body)), "</pre>");
}


## undef = $h->cerror($csock, $status=RC_INTERNAL_SERVER_ERROR, @msg)
##  + sends an error response and sends it to the client socket
##  + also logs the error at level ($c->{logError}||'warn') and shuts down the socket
sub cerror {
  my ($h,$c,$status,@msg) = @_;
  if (defined($c) && $c->opened) {
    $status   = RC_INTERNAL_SERVER_ERROR if (!defined($status));
    my $chost = $c->peerhost();
    my $msg   = @msg ? xml_escape(join('',@msg)) : status_message($status);
    $h->vlog(($h->{logError}||'error'), "client=$chost: $msg");
    {
      my $_warn=$^W;
      $^W=0;
      #$c->send_error($status, $msg);
      $c->send_response($h->errorResponseRaw($status, $msg));
      $^W=$_warn;
    }
    $c->shutdown(2);
    $c->close();
  }
  return undef;
}

## $rsp = $h->dumpResponse(\$contentRef, %opts)
##  + Create and return a new data-dump response.
##    Known %opts:
##    (
##     raw => $bool,      ##-- return raw data (text/plain) ; defualt=$h->{returnRaw}
##     type => $mimetype, ##-- mime type if not raw mode
##     charset => $enc,   ##-- character set, if not raw mode
##     filename => $file, ##-- attachment name, if not raw mode
##    )
sub dumpResponse {
  my ($h,$dataref,%vars) = @_;
  my $returnRaw   = defined($vars{raw}) ? $vars{raw} : $h->{returnRaw};
  my $contentType = ($returnRaw || !$vars{type} ? 'text/plain' : $vars{type});
  $contentType   .= "; charset=$vars{charset}" if ($vars{charset} && $contentType !~ m|application/octet-stream|);
  ##
  my $rsp = $h->response(RC_OK);
  $rsp->content_type($contentType);
  $rsp->content_ref($dataref) if (defined($dataref));
  $rsp->header('Content-Disposition' => "attachment; filename=\"$vars{filename}\"") if ($vars{filename} && !$returnRaw);
  return $rsp;
}


##======================================================================
## Handler class aliases (for derived classes)
##======================================================================

## %ALIAS = ($aliasName => $className, ...)
our (%ALIAS);

## undef = DTA::CAB::Server::HTTP::Handler->registerAlias($aliasName=>$fqClassName, ...)
sub registerAlias {
  shift; ##-- ignore class argument
  my (%alias) = @_;
  @ALIAS{keys(%alias)} = values(%alias);
}

## $className_or_undef = DTA::CAB::Server::HTTP::Handler->fqClass($alias_or_class_suffix)
sub fqClass {
  my $alias = $_[1]; ##-- ignore class argument

  ##-- Case 0: $alias wasn't defined in the first place: use empty string
  $alias = '' if (!defined($alias));

  ##-- Case 1: $alias is already fully qualified
  return $alias if (isa($alias,'DTA::CAB::Server::HTTP::Handler'));

  ##-- Case 2: $alias is a registered alias: recurse
  return $_[0]->fqClass($ALIAS{$alias}) if (defined($ALIAS{$alias}) && $ALIAS{$alias} ne $alias);

  ##-- Case 2: $alias is a valid "DTA::CAB::Server::HTTP::Handler::" suffix
  return "DTA::CAB::Server::HTTP::Handler::${alias}" if (isa("DTA::CAB::Server::HTTP::Handler::${alias}", 'DTA::CAB::Server::HTTP::Handler'));

  ##-- default: return undef
  return undef;
}

##======================================================================
## Local package aliases
##======================================================================
BEGIN {
  __PACKAGE__->registerAlias(
			     'DTA::CAB::Server::HTTP::Handler::base' => __PACKAGE__,
			     'base' => __PACKAGE__,
			    );
}

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Server::HTTP::Handler - abstract handler API class for DTA::CAB::Server::HTTP

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Server::HTTP::Handler;
 
 ##========================================================================
 ## API
 
 $h = $class_or_obj->new(%options);
 $bool = $h->prepare($server,$path);
 $rsp = $h->run($server, $localPath, $clientConn, $httpRequest);
 undef = $h->finish($server, $clientConn);
 
 ##========================================================================
 ## Generic Utilities
 
 $rsp = $h->headResponse();
 $rsp = $CLASS_OR_OBJECT->response($code=RC_OK, $msg=status_message($code), $hdr, $content);
 undef = $h->cerror($csock, $status=RC_INTERNAL_SERVER_ERROR, @msg);
 $rsp = $h->dumpResponse(\$contentRef, %opts);
 
 ##========================================================================
 ## Handler class aliases (for derived classes)
 
 undef = DTA::CAB::Server::HTTP::Handler->registerAlias($aliasName=>$fqClassName, ...);
 $className_or_undef = DTA::CAB::Server::HTTP::Handler->fqClass($alias_or_class_suffix);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Server::HTTP::Handler is a common base class and abstract API
for request handlers used by L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP>.

=head2 Subclasses

Currently supported subclasses include:

=over 4

=item L<DTA::CAB::Server::HTTP::Handler::CGI|DTA::CAB::Server::HTTP::Handler::CGI>

CAB HTTP Server: request handler: CGI form processing

=item L<DTA::CAB::Server::HTTP::Handler::Directory|DTA::CAB::Server::HTTP::Handler::Directory>

CAB HTTP Server: request handler: directory

=item L<DTA::CAB::Server::HTTP::Handler::File|DTA::CAB::Server::HTTP::Handler::File>

CAB HTTP Server: request handler: static file

=item L<DTA::CAB::Server::HTTP::Handler::Query|DTA::CAB::Server::HTTP::Handler::Query>

CAB HTTP Server: request handler: analyzer queries by CGI form

=item L<DTA::CAB::Server::HTTP::Handler::Response|DTA::CAB::Server::HTTP::Handler::Response>

CAB HTTP Server: request handler: static response

=item L<DTA::CAB::Server::HTTP::Handler::XmlRpc|DTA::CAB::Server::HTTP::Handler::XmlRpc>

CAB HTTP Server: request handler: XML-RPC queries (backwards-compatible)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::Handler: API
=pod

=head2 API

=over 4

=item new

 $h = $class_or_obj->new(%options);

Create a new handler.
Default implementation just blesses \%options into the appropriate class.

=item prepare

 $bool = $h->prepare($server,$path);

Perfvorm server-dependent initialization for handler $h as called
by L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP> $srv
for path (string) $path.
Should return true on success.

Default implementation just returns true.

=item run

 $rsp = $h->run($server, $localPath, $clientConn, $httpRequest);

Run the handler to respond to an HTTP::Request $httpRequest
sent to the L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP> object $server
matching server path $localPath by the client socket $clientConn.

Should return a HTTP::Response object to pass to the client.
If the method call die()s or returns undef, an error response will be
sent to the client instead if it the connection is still open.

This method may return the data to the client itself; if so,
it should close the client connection ($csock-E<gt>shutdown(2); $csock-E<gt>close())
and return undef to prevent bogus error messages.

=item finish

 undef = $h->finish($server, $clientConn);

Clean up handler state after run().
Default implementation does nothing.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::Handler: Generic Utilities
=pod

=head2 Generic Utilities

=over 4

=item headResponse

 $rsp = $h->headResponse();
 $rsp = $h->headResponse(\@headers)
 $rsp = $h->headResponse($httpHeaders)

Rudimentary handling for HEAD requests.

=item response

 $rsp = $CLASS_OR_OBJECT->response($code=RC_OK, $msg=status_message($code), $hdr, $content);

Creates and returns a new HTTP::Response.
$hdr may be a HTTP::Headers object, an array or hash-ref.
Really just a wrapper for HTTP::Response-E<gt>new().

=item cerror

 undef = $h->cerror($csock, $status=RC_INTERNAL_SERVER_ERROR, @msg);

Creates an error response and sends it to the client socket $csock.
Also logs the error at level ($h-E<gt>{logError}||'error') and shuts down the socket.

=item dumpResponse

 $rsp = $h->dumpResponse(\$contentRef, %opts);

Create and return a new data-dump response.
Known %opts:

 (
  raw => $bool,      ##-- return raw data (text/plain) ; defualt=$h->{returnRaw}
  type => $mimetype, ##-- mime type if not raw mode
  charset => $enc,   ##-- character set, if not raw mode
  filename => $file, ##-- attachment name, if not raw mode
 )

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::Handler: Handler class aliases (for derived classes)
=pod

=head2 Handler class aliases (for derived classes)

=over 4

=item %ALIAS

Hash of fully qualified handler class names indexed by short alias names.


=item registerAlias

 undef = DTA::CAB::Server::HTTP::Handler->registerAlias($aliasName=>$fqClassName, ...);

Registers an alias $aliasName for the handler class $fqClassName.

=item fqClass

 $className_or_undef = DTA::CAB::Server::HTTP::Handler->fqClass($alias_or_class_suffix);

Returns a fully qualified class name for an alias or class suffix $alias_or_class_suffix.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<DTA::CAB::Server::HTTP(3pm)|DTA::CAB::Server::HTTP>,
L<DTA::CAB::Server::HTTP::Handler::Builtin(3pm)|DTA::CAB::Server::HTTP::Handler::Builtin>
L<DTA::CAB::Server::HTTP::Handler::CGI(3pm)|DTA::CAB::Server::HTTP::Handler::CGI>
L<DTA::CAB::Server::HTTP::Handler::Directory(3pm)|DTA::CAB::Server::HTTP::Handler::Directory>
L<DTA::CAB::Server::HTTP::Handler::File(3pm)|DTA::CAB::Server::HTTP::Handler::File>
L<DTA::CAB::Server::HTTP::Handler::Query(3pm)|DTA::CAB::Server::HTTP::Handler::Query>
L<DTA::CAB::Server::HTTP::Handler::Response(3pm)|DTA::CAB::Server::HTTP::Handler::Response>
L<DTA::CAB::Server::HTTP::Handler::XmlRpc(3pm)|DTA::CAB::Server::HTTP::Handler::XmlRpc>
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut
