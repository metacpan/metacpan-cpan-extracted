# $Id: XPointer.pm,v 1.13 2004/11/16 03:56:18 asc Exp $
use strict;

package Apache::XPointer;

$Apache::XPointer::VERSION = '1.1';

=head1 NAME

Apache::XPointer - mod_perl handler to address XML fragments.

=head1 SYNOPSIS

 <Directory /foo/bar>

  <FilesMatch "\.xml$">
   SetHandler	perl-script
   PerlHandler	Apache::XPointer::XPath

   PerlSetVar   XPointerSendRangeAs    "application/xml"
  </FilesMatch>

 </Directory>

 #

 my $ua  = LWP::UserAgent->new();
 my $req = HTTP::Request->new(GET => "http://example.com/foo/bar/baz.xml");

 $req->header("Range"  => qq(xmlns("x=http://example.com#")xpointer(*//x:thingy)));
 $req->header("Accept" => qq(application/xml));

 my $res = $ua->request($req);

=head1 DESCRIPTION

Apache::XPointer is a mod_perl handler to address XML fragments using
the HTTP 1.1 I<Range> and I<Accept> headers and the XPath scheme, as described
in the paper : I<A Semantic Web Resource Protocol: XPointer and HTTP>.

Additionally, the handler may also be configured to recognize a conventional
CGI parameter as a valid range identifier.

If no 'range' property is found, then the original document is
sent unaltered.

If an I<Accept> header is specified with no corresponding match, then the
server will return (406) HTTP_NOT_ACCEPTABLE. Successful queries will return
(206) HTTP_PARTIAL_CONTENT.

=head1 IMPORTANT

This package is a base class and not expected to be invoked
directly. Please use one of the scheme-specific handlers instead.

=head1 SUPPPORTED SCHEMES

=head2 XPath

Consult L<Apache::XPointer::XPath>

=head2 RDF Data Query Language (RDQL)

Consult L<Apache::XPointer::RDQL>

=head1 MOD_PERL COMPATIBILITY

This handler will work with both mod_perl 1.x and mod_perl 2.x.

=cut

require 5.6.0;
use mod_perl;

use constant MP2 => ($mod_perl::VERSION >= 1.99) ? 1 : 0;

BEGIN {

     if (MP2) {
         require Apache2;
         require Apache::RequestRec;
         require Apache::RequestIO;
         require Apache::RequestUtil;
         require Apache::Const;
         require Apache::Log;
         require Apache::URI;
         require APR::Table;
         require APR::URI;
         require CGI;

         Apache::Const->import(-compile => qw(OK DECLINED HTTP_NOT_FOUND HTTP_NOT_ACCEPTABLE HTTP_PARTIAL_CONTENT HTTP_INTERNAL_SERVER_ERROR));

         CGI->compile(qw(param));
      }

     else {
         require Apache;
         require Apache::Constants;
         require Apache::Log;
         require Apache::Request;

         # mod_perl 1.x does not declare a 
         # HTTP_PARTIAL_CONTENT constant so
         # it gets hard-coded below

         Apache::Constants->import(qw(OK DECLINED NOT_FOUND HTTP_NOT_ACCEPTABLE SERVER_ERROR));
     }
}

sub handler : method {
  my $pkg    = shift;
  my $apache = shift;

  my $range  = $pkg->range($apache);

  if (! $range) {
      return $pkg->_declined();
  }

  my $accept = undef;

  if (my $possible = $pkg->accept($apache)) {

      foreach my $choice (split(",",$possible)) {
	  
	  $choice =~ s/^\s+//;
	  $choice =~ s/\s+$//;

          # hand-waving...levels
	  # ...more hand-waving

	  $choice =~ s/;.*//;

	  if ($pkg->send_as($choice)) {
	      $accept = $choice;
	      last;
	  }
      }

      if (! $accept) {
	  $apache->log()->error("unable to send request as '$accept'");
	  return $pkg->_not_acceptable();
      }
  }

  #

  my $parsed = $pkg->parse_range($apache,$range);

  if (! $parsed) {
      $apache->log()->error(sprintf("failed to parse range '%s'",
				    $range));
      
      return $pkg->_server_error();
  }

  #

  my $res = $pkg->query($apache,$parsed);

  if ((! $res) || (! $res->{success})) {
      return $res->{response};
  }

  #

  my $ok = $pkg->send_results($apache,$res,$accept);
  return $ok;
}

sub send_results {
    my $pkg    = shift;
    my $apache = shift;
    my $res    = shift;
    my $accept = shift;

    $accept ||= $apache->dir_config("XPointerSendRangeAs");
    
    my $method = $pkg->send_as($accept);

    if (! $pkg->can($method)) {
	$apache->log()->error("Unknown send as method '$method'");
	return $pkg->_server_error();
    }

    #

    $pkg->send_headers($apache,$res,$accept);
    $pkg->$method($apache,$res);

    # We set the status in 'send_headers' because
    # apache/mod_perl keeps trying to send back an
    # HTML error page whenever we return 206...

    return 0;
}

sub send_headers {
    my $pkg    = shift;
    my $apache = shift;
    my $res    = shift;
    my $accept = shift;

    $apache->status($pkg->_partial_content());

    $pkg->_header_out($apache,"Content-Base",
		      sprintf("%s:%s",$apache->hostname(),$apache->get_server_port()));

    $pkg->_header_out($apache,"Content-Location",
		      $apache->uri());

    $pkg->_header_out($apache,"Content-Range",
		      $pkg->range($apache));

    $apache->content_type($accept);

    if (! $pkg->_mp2()) {
	$apache->send_http_header();
    }

    return 1;
}

sub range {
    my $pkg    = shift;
    my $apache = shift;

    my $range = $pkg->_header_in($apache,"Range");
    
    if ((! $range) &&
	($apache->dir_config("XPointerAllowCGI") =~ /^on$/i)) {

	my $rparam  = $apache->dir_config("XPointerCGIRangeParam") || "range";
	$range      = $pkg->_param($apache,$rparam);
    }
    
    return $range;
}

sub accept {
    my $pkg = shift;
    my $apache = shift;

    my $accept = $pkg->_header_in($apache,"Accept");

    if ((! $accept) &&
	($apache->dir_config("XPointerAllowCGI") =~ /^on$/i)) {

	my $aparam  = $apache->dir_config("XPointerCGIAcceptParam") || "accept";		
	$accept     = $pkg->_param($apache,$aparam);
    }

    return $accept;
}

sub send_as {
    my $pkg = shift;
    return $pkg->_nometh(@_);
}

sub parse_range {
    my $pkg = shift;
    return $pkg->_nometh(@_);
}

sub query {
    my $pkg = shift;
    return $pkg->_nometh(@_);
}

sub _mp2 {
    return MP2;
}

sub _param {
    my $pkg    = shift;
    my $apache = shift;
    my $field  = shift;

    if ($pkg->_mp2()) {
	return CGI::param($field);
    }
    
    my $request = Apache::Request->new($apache);
    return $request->param($field);
}

sub _nometh {
    my $pkg    = shift;
    my $apache = shift;

    my $caller = (caller(1))[3];
    $caller =~ s/.*:://;

    $apache->log()->error(sprintf("package %s does not define a '%s' method",
				  $pkg,$caller));
    return 0;
}

sub _declined {
    my $pkg = shift;
    return ($pkg->_mp2()) ? Apache::DECLINED() : Apache::Constants::DECLINED();
}

sub _server_error {
    my $pkg = shift;
    return ($pkg->_mp2()) ? Apache::HTTP_INTERNAL_SERVER_ERROR() : Apache::Constants::SERVER_ERROR();
}

sub _not_found {
    my $pkg = shift;
    return ($pkg->_mp2()) ? Apache::HTTP_NOT_FOUND() : Apache::Constants::NOT_FOUND();
}

sub _not_acceptable {
    my $pkg = shift;
    return ($pkg->_mp2()) ? Apache::HTTP_NOT_ACCEPTABLE() : Apache::Constants::HTTP_NOT_ACCEPTABLE();
}

sub _partial_content {
    my $pkg = shift;
    return ($pkg->_mp2()) ? Apache::HTTP_PARTIAL_CONTENT() : 206;
}

sub _ok {
    my $pkg = shift;
    return ($pkg->_mp2()) ? Apache::OK() : Apache::Constants::OK();
}

sub _header_in {
    my $pkg    = shift;
    my $apache = shift;
    my $field  = shift;

    return ($pkg->_mp2()) ? $apache->headers_in()->{$field} : $apache->header_in($field);
}

sub _header_out {
    my $pkg    = shift;
    my $apache = shift;
    my $field  = shift;
    my $value  = shift;

    ($pkg->_mp2()) ? $apache->headers_out()->{$field} = $value: $apache->header_out($field,$value);
}

=head1 VERSION

1.1

=head1 DATE

$Date: 2004/11/16 03:56:18 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

http://www.mindswap.org/papers/swrp-iswc04.pdf

http://www.w3.org/TR/WD-xptr

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under
the same terms as Perl itself.

=cut

return 1;
