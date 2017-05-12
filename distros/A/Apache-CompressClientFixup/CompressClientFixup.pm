package Apache::CompressClientFixup;

use 5.004;
use strict;
use Apache::Constants qw(OK DECLINED);
use Apache::Log();
use Apache::URI();

use vars qw($VERSION);
$VERSION = "0.07";

sub handler {
	my $r = shift;
	my $qualifiedName = join(' ', __PACKAGE__, 'handler'); # name to log
	my $dbg_msg;
	my $uri_ref = Apache::URI->parse($r);
	if ($r->header_in('Accept-Encoding')) {
		$dbg_msg = ' with announced Accept-Encoding: '.$r->header_in('Accept-Encoding');
	} else {
		$dbg_msg = ' with no Accept-Encoding HTTP header.';
	}
	$r->log->debug($qualifiedName.' has a client '.$r->header_in('User-Agent')
		.' which requests scheme '.$uri_ref->scheme().' over '.$r->protocol.' for uri = '.$r->uri.$dbg_msg);
    {
	local $^W = 0; # quiet warning when there is no 'Accept-Encoding' header.
	return DECLINED unless $r->header_in('Accept-Encoding') =~ /gzip/io; # have nothing to downgrade
    }

	# since the compression is ordered we have a job:
	my $msg = ' downgrades the Accept-Encoding due to '; # message patern to log

	# Range for any Client:
	# =====================
    if ( lc $r->dir_config('RestrictRangeCompression') eq 'on'
	 and $r->header_in('Range') ) {
		$r->headers_in->unset('Accept-Encoding');
		$r->log->info($qualifiedName.$msg.'Range HTTP header');
		return OK;
	}

	# NN-4.X:
	# =======
	# 
	# From: Michael.Schroepl@telekurs.de
	# To: 	mod_gzip@lists.over.net
	# Date: Wed, 15 Jan 2003 20:05:06 +0200
	#
	# ... Our customers still include 17% Netscape 4 users, sigh ...
	# 
 
    if ( $r->header_in('User-Agent') and
	 ($r->header_in('User-Agent') =~ /Mozilla\/4\./o) and
	 (!($r->header_in('User-Agent') =~ /compatible/io))
       ) {
		my $printable = lc $r->dir_config('NetscapePrintable') eq 'on';
		if ( $printable ){
			$r->headers_in->unset('Accept-Encoding');
			$r->log->info($qualifiedName.$msg.'printable for NN-4.X');
	} elsif (defined $r->content_type and # quiets a warning if $r->content_type isn't defined.
		 $r->content_type =~ /application\/x-javascript|text\/css/io
		) {
			$r->headers_in->unset('Accept-Encoding');
			$r->log->info($qualifiedName.$msg.'content type for NN-4.X');
		}
		return OK;
	}

	# M$IE:
	# =====
	if ( (lc $r->dir_config('RestrictMSIEoverSSL') eq 'on')
	    and ($uri_ref->scheme() =~ /https/io) and ($r->header_in('User-Agent') =~ /MSIE/io) ) {
		$r->headers_in->unset('Accept-Encoding');
		$r->log->info($qualifiedName.$msg.'MSIE over SSL');
		return OK;
	}
	return OK;
}

1;

__END__

=head1 NAME

Apache::CompressClientFixup - Perl extension for Apache-1.3.X to avoid C<gzip> compression
for some buggy browsers.

=head1 SYNOPSIS

It is assumed that the C<Apache::CompressClientFixup> package is installed in your Perl library.
See C<README> for installation instructions if necessary.

You may use something like the following in your C<httpd.conf>:

  PerlModule Apache::CompressClientFixup
  <Location /devdoc/Dynagzip>
      SetHandler perl-script
      PerlFixupHandler Apache::CompressClientFixup
      Order Allow,Deny
      Allow from All
  </Location>

You can, for example, restrict compression for MSIE over SSL
and restrict compression for C<Netscape Navigator 4.X> with

  PerlModule Apache::CompressClientFixup
  <Location /devdoc/Dynagzip>
    SetHandler perl-script
    PerlFixupHandler Apache::CompressClientFixup
    PerlSetVar RestrictMSIEoverSSL On
    PerlSetVar NetscapePrintable On
    Order Allow,Deny
    Allow from All
  </Location>

=head1 INTRODUCTION

Standard gzip compression significantly scales bandwidth,
and helps to satisfy clients, who receive the compressed content faster,
especially on dial up's.

Obviously, the success of proper implementation of content compression depends on quality of both sides
of the request-response transaction.
Since on server side we have 6 open source modules/packages for web content compression (in alphabetic order):

=over 4

=item ·Apache::Compress

=item ·Apache::Dynagzip

=item ·Apache::Gzip

=item ·Apache::GzipChain

=item ·mod_deflate

=item ·mod_gzip

=back

the main problem of implementation of web content compression deals with fact that some buggy web clients
declare the ability to receive
and decompress gzipped data in their HTTP requests, but fail to keep promises
when the response arrives really compressed.

All known content compression modules rely on C<Accept-Encoding: gzip> HTTP request header
in accordance with C<rfc2616>. HTTP server should never respond with compressed content
to the client which fails to declare self capability to uncompress data accordingly.

Thinking this way, we would try to unset the incoming C<Accept-Encoding> HTTP header
for those buggy clients, because they would better never set it up...

We would separate this fixup handler from the main compression module for a good reason.
Basically, we would benefit from this extraction, because in this case
we may create only one common fixup handler for all known compression modules.
It would help to

=over 4

=item ·Share specific information;

=item ·Simplify the control of every compression module;

=item ·Wider reuse the code of the requests' correction;

=item ·Simplify further upgrades.

=back

=head2 Acknowledgments

Thanks to Rob Bloodgood for the patch that helps to eliminate some unnecessary warnings.

=head1 DESCRIPTION

This handler is supposed to serve the C<fixup> stage on C<mod-perl> enabled Apache-1.3.X.

It unsets HTTP request header C<Accept-Encoding> for the following web clients:

=head2 Microsoft Internet Explorer

Internet Explorer sometimes loses the first 2048 bytes of data
that are sent back by Web Servers that use HTTP compression,
- Microsoft confirms for MSIE 5.5 in Microsoft Knowledge Base Article - Q313712
(http://support.microsoft.com/default.aspx?scid=kb;en-us;Q313712).

The similiar statement about MSIE 6.0 is confirmed in Microsoft Knowledge Base Article - Q312496.

In accordance with Q313712 and Q312496, these bugs affect transmissions through

=over 4

=item HTTP

=item HTTPS

=item FTP

=item Gopher

=back

and special patches for MSIE-5.5 and MSIE-6.0 were published on Internet.

Microsoft has confirmed that this was a problem in the Microsoft products.

Microsoft states that this problem was first corrected in Internet Explorer 6 Service Pack 1.

Since then, later versions of MSIE are not supposed to carry this bug at all.

This version of the handler does not restrict compression for MSIE over HTTP.

Restriction over HTTPS for all versions of MSIE could be configured with

    PerlSetVar RestrictMSIEoverSSL On

in C<httpd.conf> if required.

=over 4

=item Note:

It is not recommended any more to restrict MSIE over SSL since Vlad Jebelev reported
successfull delivery of compressed content to MSIE over SSL providing dynamic Apache
downgrade from HTTP/1.1 to HTTP/1.0 in accordance with SSL recommendations.
Since then it would be considered preferable solution to downgrade the protocol for this client
instead of discarding compression.

This approach works fine with C<Apache::Dynagzip 0.09>, or later.

=back

=head2 Netscape 4.X

This is C<HTTP/1.0> client.
Netscape 4.X is failing to

=over 4

=item a) handle <script> referencing compressed JavaScript files (Content-Type: application/x-javascript)

=item b) handle <link> referencing compressed CSS files (Content-Type: text/css)

=item c) display the source code of compressed HTML files

=item d) print compressed HTML files

=back

See detailed description of these bugs at
http://www.schroepl.net/projekte/mod_gzip/browser.htm - Michael Schroepl's Web Site.

This version serves cases (a) and (b) as default for this type of browsers.
Namely, it unsets HTTP request header C<Accept-Encoding> for C<Content-Type: application/x-javascript>
and for C<Content-Type: text/css> when the request is originated from Netscape 4.X client.

This version serves cases (c) and (d) conditionally:
To activate printability for C<Netscape Navigator 4.X> you need to place

    PerlSetVar NetscapePrintable On

in your C<httpd.conf>. It turns off any compression for that buggy browser.

On Wednesday January 15, 2003 Michael Schroepl wrote to C<mod_gzip@lists.over.net>:

    ... Our customers still include 17% Netscape 4 users, sigh ...

=head2 Partial Request from Any Web Client

In accordance with C<rfc2616> server I<may> ignore C<Range> features of the request and respond
with full HTTP body indeed. Usually you should not care about compression features in this case.

For experimental reasons this version unsets HTTP header C<Accept-Encoding> for any web client conditionally when

    PerlSetVar RestrictRangeCompression On

is present in your C<httpd.conf> and HTTP header C<Range> is present within the request.
You may experiment with this option when you know what you are doing...

=head1 DEPENDENCIES

This module requires these other modules and libraries:

   Apache::Constants;
   Apache::Log;
   Apache::URI;

which come bandled with C<mod_perl>. You don't need to install them additionally.

=head1 AUTHOR

Slava Bizyayev E<lt>slava@cpan.orgE<gt> - Freelance Software Developer & Consultant.

=head1 COPYRIGHT AND LICENSE

I<Copyright (C) 2002, 2003 Slava Bizyayev. All rights reserved.>

This package is free software.
You can use it, redistribute it, and/or modify it under the same terms as Perl itself.

The latest version of this module can be found on CPAN.

=head1 SEE ALSO

C<mod_perl> at F<http://perl.apache.org>

C<Apache::Dynagzip> at F<http://search.cpan.org/author/SLAVA/>

Web Content Compression FAQ at F<http://perl.apache.org/docs/tutorials/client/compression/compression.html>

Michael Schroepl's Web Site at F<http://www.schroepl.net/projekte/mod_gzip/browser.htm>

=cut

