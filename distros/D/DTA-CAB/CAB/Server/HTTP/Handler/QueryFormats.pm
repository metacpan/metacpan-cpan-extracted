##-*- Mode: CPerl -*-

## File: DTA::CAB::Server::HTTP::Handler::QueryFormats.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + CAB HTTP Server: request handler: analyzer list (rsp. query handler)
##======================================================================

package DTA::CAB::Server::HTTP::Handler::QueryFormats;
use DTA::CAB::Server::HTTP::Handler::Query;
use HTTP::Status;
use URI::Escape qw(uri_escape uri_escape_utf8);
use CGI ':standard';
use XML::LibXML;
use Carp;
use strict;

##--------------------------------------------------------------
## Globals

our @ISA = qw(DTA::CAB::Server::HTTP::Handler::CGI);

##--------------------------------------------------------------
## Aliases
BEGIN {
  DTA::CAB::Server::HTTP::Handler->registerAlias(
						 'QueryFormats' => __PACKAGE__,
						 'queryformats' => __PACKAGE__,
						);
}

##--------------------------------------------------------------
## Methods: API

## $h = $class_or_obj->new(%options)
## %$h, %options:
##  (
##   ##-- INHERITED from Handler::CGI
##   #encoding => $defaultEncoding,  ##-- default encoding (UTF-8)
##   allowGet => $bool,             ##-- allow GET requests? (default=1)
##   allowPost => $bool,            ##-- allow POST requests? (default=1)
##   allowList => $bool,            ##-- if true, allowed analyzers will be listed for 'PATHROOT/.../list' paths
##   pushMode => $mode,             ##-- push mode for addVars (default='keep')
##   ##
##   ##-- NEW in Handler::QueryFormats
##   qh => $queryHandler,           ##-- underlying query handler
##  )
sub new {
  my $that = shift;
  my $h =  $that->SUPER::new(
			     qh => undef,
			     #encoding=>'UTF-8', ##-- default CGI parameter encoding
			     allowGet=>1,
			     allowPost=>1,
			     @_,
			    );
  return $h;
}

## $bool = $h->prepare($server)
##  + checks that $h->{qh} is defined
sub prepare {
  my ($h,$srv) = @_;
  $h->logconfess("no query handler 'qh' defined!") if (!$h->{qh});
  return 1;
}

## $bool = $path->run($server, $localPath, $clientSocket, $httpRequest)
## + process $httpRequest as CGI form-encoded format list query
## + form parameters:
##   (
##    f    => $formatRegex,          ##-- format name in @{$qh->{formats}{reg}}
##    fmt  => $queryFormat,          ##-- query/response format (default=$h->{defaultFormat})
##    #enc  => $queryEncoding,        ##-- query encoding (default='UTF-8')
##    raw  => $bool,                 ##-- if true, data will be returned as text/plain (default=$h->{returnRaw})
##    pretty => $level,              ##-- response format level
##   )
our %localParams = map {($_=>undef)} qw(f fmt raw pretty);
sub run {
  my ($h,$srv,$path,$c,$hreq) = @_;

  ##-- check for HEAD
  return $h->headResponse() if ($hreq->method eq 'HEAD');

  ##-- parse list query parameters
  my $vars = $h->cgiParams($c,$hreq) or return undef;
  $h->vlog($h->{logVars}, "got query params:\n", Data::Dumper->Dump([$vars],['vars']));

  #my $enc = $h->getEncoding(@$vars{qw(enc encoding)},$hreq,$h->{encoding});
  #return $h->cerror($c, undef, "unknown encoding '$enc'") if (!defined(Encode::find_encoding($enc)));

  $h->decodeVars($vars, vars=>[qw(f fmt format)], allowHtmlEscapes=>0);
  $h->trimVars($vars,  vars=>[qw(f fmt format)]);

  ##-- get matching formats
  my $qh  = $h->{qh};
  my $reg = $qh->{formats};
  my $qre = defined($vars->{a}) ? qr/$vars->{a}/ : qr//;
  my @fmts = (grep {$_->{name} =~ $qre || $_->{short} =~ $qre}
	      sort {$a->{short} cmp $b->{short} || $a->{name} cmp $b->{name}}
	      @{$reg->{reg}});

  ##-- get format
  my $fc  = $vars->{format} || $vars->{fmt} || $qh->{defaultFormat};
  my $fmt = $qh->{formats}->newFormat($fc,level=>$vars->{pretty})
    or return $h->cerror($c, undef, "unknown output format '$fc': $@");

  ##-- dump analyzers
  $fmt->{raw} = 1; ##-- hack to allow format dump of raw (non-document) data
  my ($ostr);
  if ($fmt->isa('DTA::CAB::Format::TT')) {
    $ostr = join("\n",
		 map { join("\t", map {$_||''} @$_{qw(short name)}) } #readerClass writerClass filenameRegex
		 @fmts);
  }
  elsif ($fmt->isa('DTA::CAB::Format::XmlNative')) {
    my $doc = XML::LibXML::Document->new(1.0,'UTF-8');
    my $root = XML::LibXML::Element->new('formats');
    $doc->setDocumentElement($root);
    my ($f,$nod);
    foreach $f (@fmts) {
      $nod = $root->addNewChild(undef,'format');
      $nod->setAttribute($_, ($f->{$_}||'')) foreach (qw(short name)); #readerClass writerClass filenameRegex
    }
    $ostr = $doc->toString($vars->{pretty}||0);
  }
  else {
    ##-- raw data
    $fmt->toString(\$ostr)->putData(\@fmts)->flush;
  }
  utf8::encode($ostr) if (utf8::is_utf8($ostr));

  ##-- dump response
  return $h->dumpResponse(\$ostr,
			  raw=>$vars->{raw},
			  type=>$fmt->mimeType,
			  charset=>'UTF-8',
			  filename=>("analyzers".$fmt->defaultExtension),
			 );
}


##--------------------------------------------------------------
## Methods: Local

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Server::HTTP::Handler::QueryFormats - CAB HTTP Server: request handler: format list queries

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Server::HTTP::Handler::QueryFormats;
 
 ##========================================================================
 ## Methods: API
 
 $h = $class_or_obj->new(%options);
 $bool = $h->prepare($server);
 $bool = $path->run($server, $localPath, $clientSocket, $httpRequest);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Server::HTTP::Handler::QueryFormats
is a request handler class for use with a
L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP> server
which handles format list queries for a selected
L<DTA::CAB::Server::HTTP::Handler::Query|DTA::CAB::Server::HTTP::Handler::Query>
handler.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::Handler::QueryFormats: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Server::HTTP::Handler::QueryFormats inherits from
L<DTA::CAB::Server::HTTP::Handler::CGI> and implements the
L<DTA::CAB::Server::HTTP::Handler> API.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::Handler::QueryFormats: Methods: API
=pod

=head2 Methods: API

=over 4

=item new

 $h = $class_or_obj->new(%options);

%$h, %options:

  (
   ##-- INHERITED from Handler::CGI
   #encoding => $defaultEncoding,  ##-- default encoding (UTF-8)
   allowGet => $bool,             ##-- allow GET requests? (default=1)
   allowPost => $bool,            ##-- allow POST requests? (default=1)
   allowList => $bool,            ##-- if true, allowed analyzers will be listed for 'PATHROOT/.../list' paths
   pushMode => $mode,             ##-- push mode for addVars (default='keep')
   ##
   ##-- NEW in Handler::QueryFormats
   qh => $qh,                     ##-- associated query handler
  )

=item prepare

 $bool = $h->prepare($server);

Checks that $h-E<gt>{qh} is defined.

=item run

 $bool = $path->run($server, $localPath, $clientSocket, $httpRequest);

Process $httpRequest matching $localPath as CGI form-encoded format list query.
The following CGI form parameters are supported:

 (
  f => $analyerRegex,            ##-- format name regex for $qh->{formats}
  fmt => $format,                ##-- I/O format
  #enc => $enc,                   ##-- I/O encoding
  pretty => $level,              ##-- pretty-printing level
  raw => $bool,                  ##-- if true, data will be returned as text/plain (default=$h->{returnRaw})
 )

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

Copyright (C) 2011-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<DTA::CAB::Server::HTTP::Handler::Query(3pm)|DTA::CAB::Server::HTTP::Handler::Query>,
L<DTA::CAB::Server::HTTP::Handler::CGI(3pm)|DTA::CAB::Server::HTTP::Handler::CGI>,
L<DTA::CAB::Server::HTTP::Handler(3pm)|DTA::CAB::Server::HTTP::Handler>,
L<DTA::CAB::Server::HTTP(3pm)|DTA::CAB::Server::HTTP>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...

=cut
