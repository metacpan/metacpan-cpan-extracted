##-*- Mode: CPerl -*-

## File: DTA::CAB::Server::HTTP::Handler::CGI.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + CAB HTTP Server: request handler: CGI form processing
##======================================================================

package DTA::CAB::Server::HTTP::Handler::CGI;
use DTA::CAB::Server::HTTP::Handler;
use HTTP::Status;
use URI::Escape qw(uri_escape uri_escape_utf8);
use CGI;
use Carp;
use strict;

our @ISA = qw(DTA::CAB::Server::HTTP::Handler);

##--------------------------------------------------------------
## Aliases
BEGIN {
  DTA::CAB::Server::HTTP::Handler->registerAlias(
						 'DTA::CAB::Server::Server::HTTP::Handler::CGI' => __PACKAGE__,
						 'cgi' => __PACKAGE__,
						);
}

##--------------------------------------------------------------
## Methods

## $h = $class_or_obj->new(%options)
## + %options:
##     #encoding => $defaultEncoding,  ##-- default encoding (UTF-8)
##     allowGet => $bool,             ##-- allow GET requests? (default=1)
##     allowPost => $bool,            ##-- allow POST requests? (default=1)
##     pushMode => $mode,             ##-- push mode for addVars (dfefault='push')
##     prepare  => \&prepare,         ##-- CODE-ref for prepare()
##     run      => \&run,             ##-- CODE-ref for run()
##     finish   => \&finish,          ##-- CODE-ref for finish()
##
## + runtime %$h data:
##     #cgi => $cgiobj,               ##-- CGI object (after cgiParse())
##     #vars => \%vars,               ##-- CGI variables (after cgiParse())
##     #cgisrc => $cgisrc,            ##-- CGI source (after cgiParse())
sub new {
  my $that = shift;
  my $h =  bless {
		  #encoding=>'UTF-8', ##-- default CGI parameter encoding
		  allowGet=>1,
		  allowPost=>1,
		  pushMode => 'push',
		  @_
		 }, ref($that)||$that;
  return $h;
}

## $bool = $h->prepare($server)
##  + calls $h->{prepare}->($h,$server) if defined
sub prepare {
  return $_[0]{prepare}->(@_) if ($_[0]{prepare});
  return 1;
}

## \%vars = $h->decodeVars(\%vars,%opts)
##  + decodes cgi-style variables using $h->decodeString($str,%opts)
##  + %opts:
##     vars    => \@vars,      ##-- list of vars to decode (default=keys(%vars))
##     someKey => $someVal,    ##-- passed to $h->decodeString()
sub decodeVars {
  my ($h,$vars,%opts) = @_;
  return undef if (!defined($vars));
  my $keys = $opts{vars} || [keys %$vars];
  my ($vref);
  foreach (grep {exists $vars->{$_}} @$keys) {
    $vref = \$vars->{$_};
    if (ref($$vref)) {
      $h->decodeStringRef(\$_,%opts) foreach (@{$$vref});
    } else {
      #$$vref = $h->decodeString($$vref,%opts); ##-- BUG here with YAML data (test-pp.t.yaml) UTF-8 flag not set after call!
      $h->decodeStringRef($vref,%opts);
    }
  }
  return $vars;
}

## \$string = $h->decodeString(\$string,%opts); ##-- decodes in-place
## $decoded = $h->decodeString( $string,%opts); ##-- decode by copy
##  + decodes string as UTF-8, optionally handling HTML-style escapes
##  + %opts:
##     allowHtmlEscapes => $bool,    ##-- whether to handle HTML escapes (default=false)
##     #encoding        => $enc,     ##-- source encoding (default=$h->{encoding}; see also $h->requestEncoding())
sub decodeString {
  my ($h,$str,%opts) = @_;
  return $h->decodeStringRef($str,%opts) if (ref($str));
  return ${$h->decodeStringRef(\$str,%opts)};
}

## \$string = $h->decodeStringRef(\$string,%opts); ##-- decodes in-place
##  + decodes string in-place as UTF-8, optionally handling HTML-style escapes
##  + %opts:
##     allowHtmlEscapes => $bool,    ##-- whether to handle HTML escapes (default=false)
##     #encoding         => $enc,     ##-- source encoding (default=$h->{encoding}; see also $h->requestEncoding())
sub decodeStringRef {
  my ($h,$sref,%opts) = @_;
  return $sref if (!defined($sref) || !ref($sref));
  utf8::decode($$sref) if (!utf8::is_utf8($$sref));
  if ($opts{allowHtmlEscapes}) {
    $$sref =~ s/\&\#(\d+)\;/pack('U',$1)/eg;
    $$sref =~ s/\&\#x([[:xdigit:]]+)\;/pack('U',hex($1))/eg;
  }
  return $$sref;
}


## \%vars = $h->trimVars(\%vars,%opts)
##  + trims leading and trailing whitespace from selected values in \%vars
##  + %opts:
##     vars    => \@vars,      ##-- list of vars to trim (default=keys(%vars))
sub trimVars {
  my ($h,$vars,%opts) = @_;
  return undef if (!defined($vars));
  my $keys = $opts{vars} || [keys %$vars];
  my ($vref);
  foreach (grep {exists $vars->{$_}} @$keys) {
    $vref = \$vars->{$_};
    if (ref($$vref)) {
      foreach (@{$$vref}) {
	$_ =~ s/^\s+//;
	$_ =~ s/\s+$//;
      }
    } else {
      $$vref =~ s/^\s+//;
      $$vref =~ s/\s+$//;
    }
  }
  return $vars;
}

## \%vars = $h->addVars(\%vars,\%push,$mode='push')
##  + CGI-like variable push; destructively adds\%push onto \%vars
##  + if $mode is 'push', dups are treated as array push
##  + if $mode is 'clobber', dups in %push clobber values in %vars
##  + if $mode is 'keep', dups in %push are ignored
sub addVars {
  my ($h,$vars,$push,$mode) = @_;
  $mode = $h->{pushMode} if (!defined($mode));
  $mode = 'push' if (!defined($mode));
  if ($mode eq 'clobber') {
    @$vars{keys %$push} = values %$push;
  }
  elsif ($mode eq 'keep') {
    $vars->{$_} = $push->{$_} foreach (grep {!exists $vars->{$_}} keys %$push);
  }
  else {
    foreach (grep {defined($push->{$_})} keys %$push) {
      if (!exists($vars->{$_})) {
	$vars->{$_} = $push->{$_};
      } else {
	$vars->{$_} = [ $vars->{$_} ] if (!ref($vars->{$_}));
	push(@{$vars->{$_}}, ref($push->{$_}) ? @{$push->{$_}} : $push->{$_});
      }
    }
  }
  return $vars;
}


## \%params = $h->uriParams($hreq,%opts)
##  + gets GET-style parameters from $hreq->uri
##  + %opts:
##      #(none)
BEGIN { *uriParams = \&uriParams_uri; }
sub uriParams_uri {
  my ($h,$hreq) = @_;
  return {$hreq->uri->query_form};
}
sub uriParams_CGI {
  my ($h,$hreq) = @_;
  if ($hreq->uri =~ m/\?(.*)$/) {
    ##-- see also: $hreq->uri->query_form(), also URI::QueryParam
    return scalar(CGI->new($1)->Vars);
  }
  return {};
}

## \%params = $h->contentParams($hreq,%opts)
##  + gets POST-style content parameters from $hreq
##  + if content-type is neither 'application/x-www-form-urlencoded' nor 'multipart/form-data',
##    but content is present, returns $hreq
##  + %opts:
##      defaultName => $name,       ##-- default parameter name (default='POSTDATA')
##      #defaultCharset => $charset, ##-- default charset (always UTF-8)
sub contentParams {
  my ($h,$hreq,%opts) = @_;
  my $dkey = defined($opts{defaultName}) ? $opts{defaultName} : 'POSTDATA';
  #my $denc = defined($opts{defaultCharset}) ? $opts{defaultCharset} : $h->requestEncoding($hreq);
  if ($hreq->content_type eq 'application/x-www-form-urlencoded') {
    ##-- x-www-form-urlencoded
    #return scalar(CGI->new($hreq->content)->Vars); ##-- : parse with CGI module
    return {URI->new('?'.$hreq->content)->query_form};
  }
  elsif ($hreq->content_type eq 'multipart/form-data') {
    ##-- multipart/form-data: parse by hand
    my $vars = {};
    my ($part,$name,$penc);
    foreach $part ($hreq->parts) {
      my $dis = $part->header('Content-Disposition');
      $penc = $h->messageEncoding($part);
      $penc = 'UTF-8' if (!defined($penc));
      if ($dis =~ /^form-data\b/) {
	##-- multipart/form-data: part: form-data
	if ($dis =~ /\bname=[\"\']?([\w\-\.\,\+]*)[\'\"]?/) {
	  ##-- multipart/form-data: part: form-data; name="PARAMNAME"
	  $h->addVars($vars, { $1 => $part->content });
	} else {
	  ##-- multipart/form-data: part: form-data; other (POSTDATA)
	  $h->addVars($vars, { $opts{defaultName} => $part->content });
	}
      }
      else {
	##-- multipart/form-data: part: anything other than 'form-data'
	$h->addVars($vars, { $opts{defaultName} => $part->content });
      }
    }
    return $vars;
  }
  elsif ($hreq->content_length > 0) {
    ##-- unknown content: use default data key
    return {
	    $opts{defaultName} => $hreq->content
	   };
  }
  return {}; ##-- no parameters at all
}

## \%params = $h->params($hreq,%opts)
## + wrapper for $h->pushVars($h->uriParams(),$h->contentParams())
## + %opts are passed to uriParams, contentParams
sub params {
  my ($h,$hreq,%opts) = @_;
  my $vars = $h->uriParams($hreq,%opts);
  $h->addVars($vars, $h->contentParams($hreq,%opts));
  return $vars;
}


## \%vars = $h->cgiParams($srv,$clientConn,$httpRequest, %opts)
##  + parses cgi parameters from client request
##  + only handles GET or POST requests
##  + wrapper for $h->uriParams(), $h->contentParams()
##  + %opts are passed to uriParams, contentParams
sub cgiParams {
  my ($h,$csock,$hreq,%opts) = @_;

  if ($hreq->method eq 'GET') {
    ##-- HTTP request: GET
    return $h->cerror($csock, RC_METHOD_NOT_ALLOWED, "CGI::cgiParams(): GET method not allowed") if (!$h->{allowGet});
    return $h->uriParams($hreq,%opts);
  }
  elsif ($hreq->method eq 'POST') {
    ##-- HTTP request: POST
    return $h->cerror($csock, RC_METHOD_NOT_ALLOWED, "CGI::cgiParams(): POST method not allowed") if (!$h->{allowPost});
    return $h->params($hreq,%opts);
  }
  else {
    ##-- HTTP request: unknown
    return $h->cerror($csock, RC_METHOD_NOT_ALLOWED, ("CGI::cgiParams(): method not allowed: ".$hreq->method));
  }

  return {};
}

## $enc = $h->messageEncoding($httpMessage,$defaultEncoding)
##  + attempts to guess messagencoding from (in order of descending priority):
##    - HTTP::Message header Content-Type charset variable
##    - HTTP::Message header Content-Encoding
##    - $defaultEncoding (default=undef)
sub messageEncoding {
  my ($h,$msg,$default) = @_;
  my $ctype = $msg->header('Content-Type'); ##-- note: $msg->content_type() truncates after ';' !
  ##-- see also HTTP::Message::decoded_content() for a better way to parse header parameters!
  ##
  return $1 if (defined($ctype) && $ctype =~ /\bcharset=([\w\-]+)/);
  #$ctype    = $msg->header('Content-Encoding');
  #return $1 if (defined($ctype) && $ctype =~ /\bcharset=([\w\-]+)/);
  #return $ctype if (defined($ctype));
  return $default;
}

## $enc = $h->getEncoding(@sources)
##  + attempts to guess request encoding from the first defined
##    encoding in @sources, each element $_ of which may be:
##     - a HASH-ref             : encoding is $_->{encoding}
##     - a HTTP::Message object : encoding is $h->messageEncoding($_)
##     - a literal scalar       : encoding is $_
sub getEncoding {
  my $h = shift;
  my ($enc);
  foreach (@_) {
    if (UNIVERSAL::isa($_,'HTTP::Message')) {
      $enc = $h->messageEncoding($_,undef);
    }
    elsif (UNIVERSAL::isa($_,'HASH')) {
      $enc = $_->{encoding};
    }
    elsif (!ref($_)) {
      $enc = $_;
    }
    return $enc if ($enc);
  }
  return undef;
}


## $enc = $h->requestEncoding($httpRequest,\%vars)
##  + attempts to guess request encoding from (in order of descending priority):
##    - CGI param 'encoding', from $vars->{encoding}
##    - HTTP::Message encoding via $h->messageEncoding($httpRequest)
##    - $h->{encoding}
sub requestEncoding {
  my ($h,$hreq,$vars) = @_;
  return $h->getEncoding($vars->{encoding},$hreq,$h->{encoding});
}

## $rsp = $h->run($server, $localPath, $clientConn, $httpRequest)
##  + return $h->{run}->(@_) if defined
sub run {
  my $h = shift;
  return $h->{run}->($h,@_) if ($h->{run});
  return $h->SUPER::run(@_);
}


## undef = $h->finish($server, $clientSocket)
##  + clean up handler state after run()
##  + override deletes @$h{qw(cgi vars cgisrc)}
sub finish {
  my $h = shift;
  return $h->{finish}->($h,@_) if ($h->{finish});
  delete(@$h{qw(cgi vars cgisrc)});
  return;
}


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Server::HTTP::Handler::CGI - DTA::CAB::Server::HTTP::Handler class: CGI form processing

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Server::HTTP::Handler::CGI;
 
 ##========================================================================
 ## Methods
 
 $h = $class_or_obj->new(%options);
 $bool = $h->prepare($server);
 undef = $h->finish($server, $clientSocket);
 
 \%params = $h->uriParams($hreq,%opts);
 \%params = $h->contentParams($hreq,%opts);
 \%params = $h->params($hreq,%opts);
 \%vars = $h->cgiParams($srv,$clientConn,$httpRequest, %opts);
 
 \%vars = $h->decodeVars(\%vars,%opts);
 \$string = $h->decodeString(\$string,%opts); ##-- decodes in-place;
 \$string = $h->decodeStringRef(\$string,%opts); ##-- decodes in-place;
 $enc = $h->messageEncoding($httpMessage,$defaultEncoding);
 $enc = $h->requestEncoding($httpRequest,\%vars);
 
 \%vars = $h->trimVars(\%vars,%opts);
 \%vars = $h->addVars(\%vars,\%push,$mode='push');
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::Handler::CGI: Methods
=pod

=head2 Methods

=over 4

=item new

 $h = $class_or_obj->new(%options);

%option, %$h:

 encoding => $defaultEncoding,  ##-- default encoding (UTF-8)
 allowGet => $bool,             ##-- allow GET requests? (default=1)
 allowPost => $bool,            ##-- allow POST requests? (default=1)
 pushMode => $mode,             ##-- push mode for addVars (dfefault='push')

=item prepare

 $bool = $h->prepare($server);

Just returns 1.


=item finish

 undef = $h->finish($server, $clientSocket);

Clean up handler state after run().
Override deletes @$h{qw(cgi vars cgisrc)}.



=item uriParams

 \%params = $h->uriParams($hreq,%opts)

Parses GET-style form parameters from $hreq-E<gt>uri.

=item contentParams

 \%params = $h->contentParams($hreq,%opts);

Parses POST-style content parameters from $hreq.
If $hreq content-type is neither 'application/x-www-form-urlencoded' nor 'multipart/form-data',
but content is present, returns $hreq content as the value of the pseudo-variable $opts{defaultName}.
Known %opts:

 defaultName => $name,       ##-- default parameter name (default='POSTDATA')
 defaultCharset => $charset, ##-- default charset

=item params

 \%params = $h->params($hreq,%opts);

Wrapper for $h-E<gt>pushVars($h-E<gt>uriParams(),$h-E<gt>contentParams())
%opts are passed to L</uriParams>(), L</contentParams>().


=item cgiParams

 \%vars = $h->cgiParams($srv,$clientConn,$httpRequest, %opts);


=over 4


=item *

parses cgi parameters from client request

=item *

only handles GET or POST requests

=item *

wrapper for $h-E<gt>uriParams(), $h-E<gt>contentParams()

=item *

%opts are passed to uriParams, contentParams

=back




=item decodeVars

 \%vars = $h->decodeVars(\%vars,%opts);

Decodes cgi-style variables using $h-E<gt>decodeString($str,%opts).
Known %opts:

 vars    => \@vars,      ##-- list of vars to decode (default=keys(%vars))
 someKey => $someVal,    ##-- passed to $h-E<gt>decodeString()

=item decodeString

 \$string = $h->decodeString(\$string,%opts); ##-- decodes in-place;
 $decoded = $h->decodeString( $string,%opts); ##-- decode by copy

Wrapper for L</decodeStringRef>().

=item decodeStringRef

 \$string = $h->decodeStringRef(\$string,%opts); ##-- decodes in-place;

Decodes string in-place as $h-E<gt>{encoding}, optionally handling HTML-style escapes.
Known %opts:

%opts:
 allowHtmlEscapes => $bool,    ##-- whether to handle HTML escapes (default=false)
 encoding         => $enc,     ##-- source encoding (default=$h->{encoding}; see also $h->requestEncoding())



=item messageEncoding

 $enc = $h->messageEncoding($httpMessage,$defaultEncoding);

Atempts to guess messagencoding from (in order of descending priority):

=over 4

=item *

HTTP::Message header Content-Type charset variable

=item *

HTTP::Message header Content-Encoding

=item *

$defaultEncoding (default=undef)

=back



=item requestEncoding

 $enc = $h->requestEncoding($httpRequest,\%vars);

Attempts to guess request encoding from (in order of descending priority):

=over 4

=item *

CGI param 'encoding', from $vars-E<gt>{encoding}

=item *

HTTP::Message encoding via $h-E<gt>messageEncoding($httpRequest)

=item *

$h-E<gt>{encoding}

=back


=item trimVars

 \%vars = $h->trimVars(\%vars,%opts);

Trims leading and trailing whitespace from selected values in \%vars.
Known %opts:

 vars    => \@vars,      ##-- list of vars to trim (default=keys(%vars))

=item addVars

 \%vars = $h->addVars(\%vars,\%push,$mode='push');

CGI-like variable push; destructively adds \%push onto \%vars.

=over 4

=item *

if $mode is 'push', dups are treated as array push

=item *

if $mode is 'clobber', dups in %push clobber values in %vars

=item *

if $mode is 'keep', dups in %push are ignored

=back

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

L<DTA::CAB::Server::HTTP::Handler(3pm)|DTA::CAB::Server::HTTP::Handler>,
L<DTA::CAB::Server::HTTP(3pm)|DTA::CAB::Server::HTTP>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...


=cut
