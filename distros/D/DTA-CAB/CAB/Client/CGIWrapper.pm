##-*- Mode: CPerl; coding: utf-8; -*-

package DTA::CAB::Client::CGIWrapper;

use DTA::CAB::Client;
use DTA::CAB::Client::XmlRpc;
use DTA::CAB::Format;
use DTA::CAB::Format::Builtin;
use DTA::CAB::Datum ':all';

use CGI qw(:standard :cgi-lib);
#use LWP::UserAgent;
use HTTP::Status;
use HTTP::Response;


use URI::Escape;
use Encode qw(encode decode);
use File::Basename qw(basename);
use utf8;
use Data::Dumper;
use strict;

##==============================================================================
## Globals
##==============================================================================
our @ISA = qw(DTA::CAB::Client::XmlRpc);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = $CLASS_OR_OBJECT->new(%args)
## + %args, %$obj:
##   ##
##   ##-- NEW
##   sysid   => "$id str"           ##-- default __PACKAGE__ . " v$DTA::CAB::VERSION"
##   analyzers => \@analyzers,      ##-- supported analyzers (undef to query)
##   fmts => [{class=>$class,label=>$label,level=>$level},...], ##-- supported output formats
##   defaultFmt => $name,           ##-- default format key
##   autoClean => $bool,            ##-- always set 'doAnalyzeClean=1' upstream analysis option
##   debug     => $bool,            ##-- default to debug mode?
##   ##
##   ##-- INHERITED from DTA::CAB::Client::XmlRpc
##   serverURL => $url,             ##-- default: localhost:8000
##   serverEncoding => $encoding,   ##-- default: UTF-8
##   timeout => $timeout,           ##-- timeout in seconds, default: 300 (5 minutes)
##   xcli => $xcli,                 ##-- RPC::XML::Client object
sub new {
  my $that = shift;
  my $wr = $that->SUPER::new(
			     ##-- identity
			     sysid => (__PACKAGE__ . " v$DTA::CAB::VERSION"),
			     analyzers => [qw(dta.cab.norm dta.cab.expand)],
			     autoClean => 0,
			     debug => 0,

			     fmts => [
				      {key=>'csv',  class=>'DTA::CAB::Format::CSV', label=>'CSV'},
				      {key=>'json', class=>'DTA::CAB::Format::JSON', label=>'JSON', level=>1},
				      {key=>'perl', class=>'DTA::CAB::Format::Perl', label=>'Perl', level=>2},
				      {key=>'text', class=>'DTA::CAB::Format::Text', label=>'Text'},
				      {key=>'tt',   class=>'DTA::CAB::Format::TT', label=>'TT'},
				      {key=>'xml',  class=>'DTA::CAB::Format::XmlNative', label=>'XML (Native)', level=>0},
				      {key=>'xmlperl', class=>'DTA::CAB::Format::XmlPerl', label=>'XML (Perl)', level=>0},
				      {key=>'xmlrpc',  class=>'DTA::CAB::Format::XmlRpc', label=>'XML-RPC', level=>0},
				      {key=>'yaml', class=>'DTA::CAB::Format::YAML', label=>'YAML', level=>0},
				     ],
			     defaultFmt => 'text',

			     ##-- user args
			     @_,
			    );

  ##-- update formats
  foreach (@{$wr->{fmts}}) {
    $_->{key} = $_->{class} if (!defined($_->{key}));
  }
  $wr->{fmtsh} = { map {($_->{key}=>$_)} @{$wr->{fmts}} };

  return $wr;
}

##==============================================================================
## Methods: top-level

## undef = $wr->run(\*STDIN)
## undef = $wr->run("$cgi_src_str")
## undef = $wr->run("$cgi_src_file")
## undef = $wr->run(\%cgi_param_hash)
sub run {
  my $wr   = shift;
  my $q    = $wr->{q} = CGI->new(@_);
  $q->charset('utf-8');
  my $qv   = $wr->{qv} = $wr->cgiDecode(scalar($q->Vars));

  my ($contentType,$content) = ('text/html',''); ##-- default content type
  my ($rdoc,$ofkey,$ofdat,$of);

  ##-- get content
  if (defined($qv->{q}) && $qv->{q} ne '') {
    ##-- query given: fetch the results
    $rdoc = $wr->fetchResults()
      || return $wr->http_error();
    #print $q->pre(Data::Dumper->Dump([$rdoc],['rdoc'])); ##-- debug

    ##-- format
    $ofkey = $qv->{format} || $wr->{defaultFmt};
    $ofdat = $wr->{fmtsh}{$ofkey};
    return $wr->http_error("unknown format: $ofkey") if (!$ofdat);
    $of    = $ofdat->{class}->new(level=>$ofdat->{level},encoding=>'UTF-8');
    $content = $of->putDocumentRaw($rdoc)->toString;
    $content = decode('utf8',$content) if (!utf8::is_utf8($content));
    $contentType = $of->mimeType;

    if ($contentType ne 'text/html') {
      print
	($q->header(-type=>($contentType =~ /\/(?:xml|plain)$/ ? $contentType : 'text/plain'),
		    -status=>'200 OK',
		    -charset => 'utf-8'),
	 $content);
      return $wr->finish();
    }
  }

  ##-- no query: just print html form
  print
    ($wr->html_header,
     $wr->html_qform,
     #$wr->html_vars, ##-- debug
     ($content ne ''
      ? $q->div({id=>'section'},
		$q->h2("Results (", $q->tt($ofdat->{class}), ")"),
		$content
	       )
      : ''),
     $wr->html_footer,
    );
}

## undef = $wr->finish()
##  + cleanup after ourselves
sub finish {
  my $wr = shift;
  $wr->disconnect;
  delete @$wr{qw(q qv error)};
  return;
}

##==============================================================================
## Methods: Generic

## \%vars = $wr->cgiDecode(\%vars)
##  + decodes cgi params in \%vars
sub cgiDecode {
  my ($wr,$qv) = @_;
  ##-- auto-decode some vars
  my @u8keys = qw(q);
  my ($vr);
  foreach (grep {exists $qv->{$_}} @u8keys) {
    $vr = \$qv->{$_};
    foreach (ref($$vr) ? @{$$vr} : $$vr) {
      $_ = decode('utf8',$_) if (!utf8::is_utf8($_));
    }
  }
  return $qv;
}

## $rdoc_or_undef = $wr->fetchResults()
## $rdoc_or_undef = $wr->fetchResults($analyzer,$qdoc,\%qopts)
##  + calls Client::XmlRpc::analyzeDocument($analyzer,$qdoc,\%qopts)
sub fetchResults {
  my ($wr,$qa,$qdoc,$qopts) = @_;
  $qa    = $wr->parseQueryAnalyzer() if (!$qa);
  $qdoc  = $wr->parseQueryDoc() if (!$qdoc);
  $qopts = $wr->parseQueryOpts() if (!$qopts);

  #my $fmt = DTA::CAB::Format::JSON->new;
  my $fmt = DTA::CAB::Format::YAML->new;
  my $qstr = $fmt->putDocument($qdoc)->toString
    or return $wr->set_error(ref($fmt)."::putDocument() failed");
  $qopts->{reader} = $qopts->{writer} = {class=>ref($fmt)};

  $wr->connect()
    or return $wr->set_error("connect() failed: $!");
  #my $rdoc = $wr->analyzeDocument($qa,$qdoc,$qopts) or return $wr->set_error("analyzeData() failed: $!");
  my $rstr = $wr->analyzeData($qa,$qstr,$qopts)
    or return $wr->set_error("analyzeData() failed: $!");
  $wr->disconnect();

  my $rdoc  = $fmt->flush->fromString($rstr)->parseDocument()
    or return $wr->set_error(ref($fmt)."::parseDocument() failed");

  return $rdoc;
}

## $qopts = $wr->parseQueryAnalyzer()
##  + currently just returns 'dta.cab.default'
sub parseQueryAnalyzer {
  return $_[0]{qv}{analyzer} if ($_[0]{qv} && $_[0]{qv}{analyzer});
  return 'dta.cab.default';
}

## $qopts = $wr->parseQueryOpts(\%qvars)
## $qopts = $wr->parseQueryOpts()
##  + currently just returns {}
sub parseQueryOpts {
  my ($wr,$qv) = @_;
  $qv = $wr->{qv} if (!$qv);
  return {
	  ##-- autoClean
	  ($wr->{autoClean} || !$qv->{debug} ? (doAnalyzeClean=>1) : qw()),

	  ##-- format
	 }
}


## $qdoc_or_undef = $wr->parseQueryDoc(\%qvars)
## $qdoc_or_undef = $wr->parseQueryDoc()
##  + on error sets $wr->{error}
sub parseQueryDoc {
  my ($wr,$qv) = @_;
  $qv = $wr->{qv} if (!$qv);

  ##-- parse query string to document
  my $qs  = $qv->{q};
  my ($qdoc);

  ##-- parse: as sentence
  $qdoc = toDocument([toSentence([map {toToken($_)}
				  grep {defined($_)}
				  map {split(/\s+/,$_)}
				  (ref($qs) ? @$qs : ($qs))
				 ])
		     ]);

  ##-- return
  return $wr->set_error('could not parse query string "$qs"') if (!$qdoc);
  return $qdoc;
}

## undef = $wr->set_error(@err)
##  + also logs error
sub set_error {
  my ($wr,@err) = @_;
  $wr->error(@err);
  $wr->{error} = join('', @err);
  return undef;
}

##==============================================================================
## Methods: HTML

## @html = $wr->html_error()
##  + returns error string for $wr->{error}
sub html_error {
  my $wr = shift;
  return (span({style=>'font-size: large; color: #ff0000;'},
	       b('Error: '), htmlesc($wr->{error} || '???')),
	  br,
	 );
}

## @http = $wr->http_error()
## @http = $wr->http_error(@msg)
##  + prints HTTP headers & error string for $wr->{error}
sub http_error {
  my $wr = shift;
  $wr->set_error(@_) if (@_);
  print
    (header(-type=>'text/html',
	    -charset=>'utf-8',
	    -status=>'500 Internal Server Error'),
     start_html(-title => (__PACKAGE__ . " Error"),
		-style=>{'src'=>'taxi.css'},
	       ),
     $wr->html_error,
     ##
     $wr->html_begin_content(),
     $wr->html_qform,
     $wr->html_footer,
     end_html,
    );
  return $wr->finish;
}


## @html = $wr->html_header()
sub html_header {
  my $wr = shift;
  return
    (header(-type=>'text/html', -charset=>'utf-8'),
     start_html(-title=>'DTA::CAB Client Wrapper',
		-style=>{'src'=>'taxi.css'},
	       ),
     $wr->html_begin_content(),
    );
}

## @html = html_begin_content($h1_title_text)
sub html_begin_content {
  my $wr = shift;
  return
    (openTag('div',{id=>'outer'}),
     div({id=>'headers'}, h1(@_ ? @_ : 'DTA::CAB Client Wrapper')),
     openTag('div',{id=>'content'}),
    );
}

## @html = $wr->html_footer()
sub html_footer {
  my $wr = shift;
  my $q = $wr->{q};
  return
    (
     closeTag('div',{id=>'content'}),
     '<div id="footers">',
     "<tt>$wr->{sysid}</tt>", $q->br,
     '<address><a href="mailto:moocow@cpan.org">moocow@cpan.org</a></address>',
     '</div>',
     closeTag('div',{id=>'outer'}),
     $q->end_html,
    );
}

## @html = $wr->html_vars()
sub html_vars {
  my $wr = shift;
  local $Data::Dumper::Indent = 2;
  return $wr->{q}->pre(Data::Dumper->Dump([$wr->{qv}],['vars']));
}

## @html = $wr->html_qform()
sub html_qform {
  my $wr = shift;
  my $q = $wr->{q};

  ##-- get analyzer list
  if (!defined($wr->{analyzers})) {
    my @a = $wr->analyzers();
    return $wr->set_error("could get analyzer list: ".$a[0]->value) if (!@a || ref($a[0]));
    $wr->{analyzers} = \@a;
  }

  return
    (
     div({id=>'section'},
	 #h2('Query'),
	 start_form(-method=>'GET', -id=>'queryForm'),
	 table({class=>'sep'},
	       tbody(
		     Tr(td({id=>'searchLabel'}, "Query:"),
			td({colspan=>3}, textfield(-name=>'q',-size=>64,-id=>'searchText')),
		       ),
		     ##
		     Tr(td({id=>'searchLabel'}, "Analyzer:"),
			td(popup_menu({-name=>'analyzer',
				       -values=>[ @{$wr->{analyzers}} ],
				       -default=>($wr->{analyzers}[0] || 'dta.cab.default')
				      }))),
		     ##
		     Tr(
			td({id=>'searchLabelE'}, "Format:"),
			td(popup_menu({-name=>'format',
				       -values=>[ map {$_->{key}} @{$wr->{fmts}} ],
				       -default=>$wr->{defaultFmt},
				       -labels => { map {($_->{key}=>$_->{label})} @{$wr->{fmts}} },
				      }))),
		     ##
		     Tr(
			td({id=>'searchLabelE'}, "Debug:"),
			td(checkbox(-name=>'debug',
				    -checked=>($wr->{autoClean} || !$wr->{debug} ? 0 : 1),
				    -value=>1,
				    -label=>'',
				    ($wr->{autoClean} ? (-disabled=>1) : qw()))),
		       ),
		     ##
		     Tr(td(),
			td(submit(-name=>'submit',-value=>'submit')),
		       ),
		    )),
	 end_form,
	),
    );
}

##==============================================================================
## Functions: utils

sub htmlesc {
  my $str = shift;
  $str =~ s/\&/&amp;/g;
  $str =~ s/\</&lt;/g;
  $str =~ s/\>/&gt;/g;
  $str =~ s/\"/&quot;/g;
  $str =~ s/\'/&apos;/g;
  return $str;
}
sub openTag {
  my ($name,$attrs) = @_;
  return "<$name".join('', map {" $_=\"".htmlesc($attrs->{$_})."\""} sort keys %$attrs).">";
}
sub closeTag {
  my $name = shift;
  return "</$name>";
}
sub elt {
  my ($name,$attrs,@content) = @_;
  return (openTag($name,$attrs), @content, closeTag($name));
}
sub mydiv { return elt('div',@_); }
sub mytable { return elt('table',@_); }
sub mytbody { return elt('tbody',@_); }
sub mytr { return elt('tr',@_); }
sub mytd { return elt('td',@_); }
sub myth { return elt('th',@_); }
sub myspan { return elt('span',@_); }
sub mya { return elt('a',@_); }

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Client::CGIWrapper - CGI wrapper for DTA::CAB::Client::XmlRpc

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Client::CGIWrapper;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = $CLASS_OR_OBJECT->new(%args);
 
 ##========================================================================
 ## Methods: top-level
 
 undef = $wr->run(\*STDIN);
 undef = $wr->finish();
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Client::CGIWrapper is a wrapper for demonstrating the
basic capabilities of L<DTA::CAB::Client::XmlRpc|DTA::CAB::Client::XmlRpc>
using an HTML CGI interface.

It is largely obsolete, as this functionality has been for the most part superseded
by the L<DTA::CAB::Server::XmlRpc|DTA::CAB::Server::XmlRpc>
and L<DTA::CAB::Client::XmlRpc|DTA::CAB::Client::XmlRpc> modules, which see.

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Client::CGIWrapper: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = $CLASS_OR_OBJECT->new(%args);

 %args, %$obj:
 ##
 ##-- NEW
 sysid   => "$id str"           ##-- default __PACKAGE__ . " v$DTA::CAB::VERSION"
 analyzers => \@analyzers,      ##-- supported analyzers (undef to query)
 fmts => [{class=>$class,label=>$label,level=>$level},...], ##-- supported output formats
 defaultFmt => $name,           ##-- default format key
 autoClean => $bool,            ##-- always set 'doAnalyzeClean=1' upstream analysis option
 debug     => $bool,            ##-- default to debug mode?
 ##
 ##-- INHERITED from DTA::CAB::Client::XmlRpc
 serverURL => $url,             ##-- default: localhost:8000
 serverEncoding => $encoding,   ##-- default: UTF-8
 timeout => $timeout,           ##-- timeout in seconds, default: 300 (5 minutes)
 xcli => $xcli,                 ##-- RPC::XML::Client object

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Client::CGIWrapper: Methods: top-level
=pod

=head2 Methods: top-level

=over 4

=item run

 undef = $wr->run(\*STDIN);
 undef = $wr->run("$cgi_src_str")
 undef = $wr->run("$cgi_src_file")
 undef = $wr->run(\%cgi_param_hash)

Run the CGI wrapper.

=item finish

 undef = $wr->finish();

Cleanup after ourselves.

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

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<dta-cab-http-server.perl(1)|dta-cab-http-server.perl>,
L<dta-cab-http-client.perl(1)|dta-cab-http-client.perl>,
L<dta-cab-xmlrpc-server.perl(1)|dta-cab-xmlrpc-server.perl>,
L<dta-cab-xmlrpc-client.perl(1)|dta-cab-xmlrpc-client.perl>,
L<DTA::CAB::Server(3pm)|DTA::CAB::Server>,
L<DTA::CAB::Client(3pm)|DTA::CAB::Client>,
L<DTA::CAB::Format(3pm)|DTA::CAB::Format>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...

=cut
