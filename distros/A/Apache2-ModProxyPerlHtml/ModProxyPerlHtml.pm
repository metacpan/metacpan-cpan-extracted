#------------------------------------------------------------------------------
# Project  : Reverse Proxy HTML link rewriter
# Name     : ModProxyPerlHtml.pm
# Language : perl 5
# Authors  : Gilles Darold, gilles at darold dot net
# Copyright: Copyright (c) 2005-2013: Gilles Darold - All rights reserved -
# Description : This mod_perl2 module is a replacement for mod_proxy_html.c
#		with far better URL HTML rewriting.
# Usage    : See documentation in this file with perldoc.
#------------------------------------------------------------------------------
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
#------------------------------------------------------------------------------
package Apache2::ModProxyPerlHtml;
use strict qw(vars);
use warnings;

require mod_perl2;

use Apache2::Connection ();
use Apache2::RequestRec;
use Apache2::RequestUtil;
use APR::Table;
use APR::URI;
use base qw(Apache2::Filter);
use Apache2::Const -compile => qw(OK DECLINED :conn_keepalive);
use constant BUFF_LEN => 8000;
use Apache2::ServerRec;
use Apache2::URI;


$Apache2::ModProxyPerlHtml::VERSION = '3.6';


%Apache2::ModProxyPerlHtml::linkElements = (
	'a'       => ['href'],
	'applet'  => ['archive', 'codebase', 'code'],
	'area'    => ['href'],
	'bgsound' => ['src'],
	'blockquote' => ['cite'],
	'body'    => ['background'],
	'del'     => ['cite'],
	'embed'   => ['pluginspage', 'src'],
	'form'    => ['action'],
	'frame'   => ['src', 'longdesc'],
	'iframe'  => ['src', 'longdesc'],
	'ilayer'  => ['background'],
	'img'     => ['src', 'lowsrc', 'longdesc', 'usemap'],
	'input'   => ['src', 'usemap','formaction'],
	'ins'     => ['cite'],
	'isindex' => ['action'],
	'head'    => ['profile'],
	'layer'   => ['background', 'src'],
	'link'    => ['href'],
	'object'  => ['classid', 'codebase', 'data', 'archive', 'usemap'],
	'q'       => ['cite'],
	'script'  => ['src', 'for'],
	'table'   => ['background'],
	'td'      => ['background'],
	'th'      => ['background'],
	'tr'      => ['background'],
	'xmp'     => ['href'],
	'button'  => ['formaction'],
);

sub handler
{
	my $f = shift;

	my $debug = $f->r->dir_config->get('ProxyHTMLVerbose');
	if ($debug && $debug =~ /(on|1)/i) {
		$debug = 1;
	} else {
		$debug = 0;
	}

	# Thing we do at the first chunk
	my $content_type = $f->r->content_type() || '';
	unless ($f->ctx) {
		$f->r->headers_out->unset('Content-Length');
		my @pattern = $f->r->dir_config->get('ProxyHTMLURLMap');
		my @rewrite = $f->r->dir_config->get('ProxyHTMLRewrite');
		my $contenttype = $f->r->dir_config->get('ProxyHTMLContentType');
		$contenttype ||= '(text\/javascript|text\/html|text\/css|text\/xml|application\/.*javascript|application\/.*xml)';
		my $badcontenttype = $f->r->dir_config->get('ProxyHTMLExcludeContentType');
		$badcontenttype ||= '(application\/vnd\.openxml)';
		my @exclude = $f->r->dir_config->get('ProxyHTMLExcludeUri');

		my $ct = $f->ctx;
		$ct->{data} = '';
		foreach my $p (@pattern) {
			push(@{$ct->{pattern}}, $p);
		}
		foreach my $p (@rewrite) {
			push(@{$ct->{rewrite}}, $p);
		}
		$ct->{contenttype} = $contenttype;
		$ct->{badcontenttype} = $badcontenttype;
		foreach my $u (@exclude) {
			push(@{$ct->{excluded}}, $u);
		}
		$f->ctx($ct);
	}
	# Thing we do on all invocations
	my $ctx = $f->ctx;
	while ($f->read(my $buffer, BUFF_LEN)) {
		$ctx->{data} .= $buffer;
		$ctx->{keepalives} = $f->c->keepalives;
		$f->ctx($ctx);
	}
	# Thing we do at end
	if ($f->seen_eos) { 
		my $parsed_uri = $f->r->construct_url();
		my $a_encoding = $f->r->headers_in->{'Accept-Encoding'} || '';
		my $c_encoding = $f->r->headers_out->{'Content-Encoding'} || '';
		my $ct = $f->r->headers_out->{'Content-type'} || '';

		# Only proceed URLs that are not excluded from rewritter
		if ( ($#{$ctx->{excluded}} == -1) || !grep($parsed_uri =~ /$_/i, @{$ctx->{excluded}}) ) {

			# if Accept-Encoding: gzip,deflate try to uncompress
			if ( ($c_encoding =~ /gzip|deflate/) && ($ct =~ /$ctx->{contenttype}/is) && ($ct !~ /$ctx->{badcontenttype}/is) ) {
				if ($debug) {
					Apache2::ServerRec::warn("[ModProxyPerlHtml] Uncompressing $ct, Content-Encoding: $c_encoding");
				}
				use IO::Uncompress::AnyInflate qw(anyinflate $AnyInflateError) ;
				my $output = '';
				anyinflate  \$ctx->{data} => \$output or print STDERR "anyinflate failed: $AnyInflateError\n";
				if ($ctx->{data} ne $output) {
					$ctx->{data} = $output;
				} else {
					$c_encoding = '';
				}
			} else {
				$c_encoding = '';
			}

			# Rewrite refresh command in header
			my $refresh = $f->r->headers_out->{'Refresh'};
			if ($refresh) {
				foreach my $p (@{$ctx->{pattern}}) {
					my ($match, $substitute) = split(/[\s\t]+/, $p, 2);
					if ($refresh =~ s#([^\/:])$match#$1$substitute#) {
						if ($debug) {
							Apache2::ServerRec::warn("[ModProxyPerlHtml] Refresh header match '$match', substituted by: /$substitute/");
						}
					}
				}
				$f->r->headers_out->set('Refresh' => $refresh);
			}

			# Rewrite referer in header
			my $referer = $f->r->headers_out->{'Referer'};
			if ($referer) {
				foreach my $p (@{$ctx->{pattern}}) {
					my ($match, $substitute) = split(/[\s\t]+/, $p, 2);
					if ($referer =~ s#([^\/:])$match#$1$substitute#) {
						if ($debug) {
							Apache2::ServerRec::warn("[ModProxyPerlHtml] Referer header match '$match', substituted by: /$substitute/");
						}
					}
				}
				$f->r->headers_out->set('Referer' => $referer);
			}
			
			# Only parse content that should have hyperlinks to rewrite
			if ( ($content_type =~ /$ctx->{contenttype}/is) && ($content_type !~ /$ctx->{badcontenttype}/is) ) {
				if ($debug) {
					Apache2::ServerRec::warn("[ModProxyPerlHtml] Content-type '$content_type' match: /$ctx->{contenttype}/is");
				}
				# Replace links if pattern match
				foreach my $p (@{$ctx->{pattern}}) {
					my ($match, $substitute) = split(/[\s\t]+/, $p, 2);
					&link_replacement(\$ctx->{data}, $match, $substitute, $parsed_uri);

				}
				# Rewrite code if rewrite pattern match
				foreach my $p (@{$ctx->{rewrite}}) {
					my ($match, $substitute) = split(/[\s\t]+/, $p, 2);
					&rewrite_content(\$ctx->{data}, $match, $substitute, $parsed_uri);
				}
			}

			# Compress again data if require
			if (($a_encoding =~ /gzip|deflate/) && ($c_encoding =~ /gzip|deflate/)) {
				if ($debug) {
					Apache2::ServerRec::warn("[ModProxyPerlHtml] Compressing output as Content-Encoding: $c_encoding");
				}
				if ($c_encoding =~ /gzip/) {
					use IO::Compress::Gzip qw(gzip $GzipError) ;
					my $output = '';
					my $status = gzip \$ctx->{data} => \$output or die "gzip failed: $GzipError\n";
					$ctx->{data} = $output;
				} elsif ($c_encoding =~ /deflate/) {
					use IO::Compress::Deflate qw(deflate $DeflateError) ;
					my $output = '';
					my $status = deflate \$ctx->{data} => \$output or die "deflate failed: $DeflateError\n";
					$ctx->{data} = $output;
				}
			}
		}

		# Apply any change
		$f->ctx($ctx);

		# Dump datas out
		$f->print($f->ctx->{data});
		my $c = $f->c;
		if ($c->keepalive == Apache2::Const::CONN_KEEPALIVE && $ctx->{data} && $c->keepalives > $ctx->{keepalives}) {
			if ($debug) {
				Apache2::ServerRec::warn("[ModProxyPerlHtml] Cleaning context for keep alive request");
			}
			$ctx->{data} = '';
			$ctx->{pattern} = ();
			$ctx->{rewrite} = ();
			$ctx->{excluded} = ();
			$ctx->{contenttype} = '';
			$ctx->{badcontenttype} = '';
			$ctx->{keepalives} = $c->keepalives;
		}
			
	}

	return Apache2::Const::OK;
}

sub link_replacement
{
	my ($data, $pattern, $replacement, $uri) = @_;

	return if (!$$data);

	my $old_terminator = $/;
	$/ = '';
	my @TODOS = ();
	my $i = 0;
	# Replace standard link into attributes of any element
	foreach my $tag (keys %Apache2::ModProxyPerlHtml::linkElements) {
		next if ($$data !~ /<$tag/i);
		foreach my $attr (@{$Apache2::ModProxyPerlHtml::linkElements{$tag}}) {
			while ($$data =~ s/(<$tag[\t\s]+[^>]*\b$attr=['"]*)($replacement|$pattern)([^'"\s>]+)/NEEDREPLACE_$i$$/i) {
				push(@TODOS, "$1$replacement$3");
				$i++;
			}
		
		}
	}
	# Replace all links in javascript code
	$$data =~ s/([^\\]['"])($replacement|$pattern)([^'"]*['"])/$1$replacement$3/ig;
	# Some use escaped quote - Do you have better regexp ?
	$$data =~ s/(\&quot;)($replacement|$pattern)(.*\&quot;)/$1$replacement$3/ig;

	# Try to set a fully qualified URI
	$uri =~ s/$replacement.*//;
        # Replace meta refresh URLs
	$$data =~ s/(<meta\b[^>]+content=['"]*.*url=)($replacement|$pattern)([^>]+)/$1$uri$replacement$3/i;
	# Replace base URI
	$$data =~ s/(<base\b[^>]+href=['"]*)($replacement|$pattern)([^>]+)/$1$uri$replacement$3/i;

	# CSS have url import call, most of the time not quoted
	$$data =~ s/(url\(['"]*)($replacement|$pattern)(.*['"]*\))/$1$replacement$3/ig;

	# Javascript have image object or other with a src method.
	$$data =~ s/(\.src[\s\t]*=[\s\t]*['"]*)($replacement|$pattern)(.*['"]*)/$1$replacement$3/ig;
	
	# The single ended tag broke mod_proxy parsing
	$$data =~ s/($replacement|$pattern)>/\/>/ig;
	
	# Replace todos now
	for ($i = 0; $i <= $#TODOS; $i++) {

		$$data =~ s/NEEDREPLACE_$i$$/$TODOS[$i]/i;
	}

	$/ = $old_terminator;

}

sub rewrite_content
{
	my ($data, $pattern, $replacement, $uri) = @_;

	return if (!$$data);

	my $old_terminator = $/;
	$/ = '';

	# Rewrite things in code (case sensitive)
	$replacement = '"' . $replacement . '"';
	$$data =~ s/$pattern/$replacement/eeg;

	$/ = $old_terminator;

}


1;

__END__

=head1 DESCRIPTION

Apache2::ModProxyPerlHtml is the most advanced Apache output filter to rewrite
HTTP headers and HTML links for reverse proxy usage. It is written in Perl and
exceeds all mod_proxy_html.c limitations without performance lost.

Apache2::ModProxyPerlHtml is very simple and has far better parsing/replacement
of URL than the original C code. It also support meta tag, CSS, and javascript
URL rewriting and can be use with compressed HTTP. You can now replace any code
by other, like changing images name or anything else. mod_proxy_html can't do
all of that. Since release 3.x ModProxyPerlHtml is also able to rewrite HTTP
headers with Refresh url redirection and Referer. 

The replacement capability concern only the following HTTP content type:

	text/javascript
	text/html
	text/css
	text/xml
	application/.*javascript
	application/.*xml

other kind of file, will be left untouched (or see ProxyHTMLContentType and ProxyHTMLExcludeContentType).

=head1 AVAIBILITY

You can get the latest version of Apache2::ModProxyPerlHtml from CPAN
(http://search.cpan.org/).

=head1 PREREQUISITES

You must have Apache2, mod_perl2 and IO::Compress::Zlib perl modules installed
on your system.

You also need to install the mod_proxy Apache modules. See documentation at
http://httpd.apache.org/docs/2.0/mod/mod_proxy.html

=head1 INSTALLATION

	% perl Makefile.PL
	% make && make install

=head1 APACHE CONFIGURATION

In your Apache configuration file you have to load the following DSO modules:

    LoadModule deflate_module modules/mod_deflate.so
    LoadModule headers_module modules/mod_headers.so
    LoadModule proxy_module modules/mod_proxy.so
    LoadModule proxy_connect_module modules/mod_proxy_connect.so
    LoadModule proxy_ftp_module modules/mod_proxy_ftp.so
    LoadModule proxy_http_module modules/mod_proxy_http.so
    LoadModule ssl_module modules/mod_ssl.so
    LoadModule perl_module  modules/mod_perl.so

Then in your Apache site or virtualhost configuration file use ModProxyPerlHtml*
as follow:

    ProxyRequests Off
    ProxyPreserveHost Off
    ProxyPass       /webcal/  http://webcal.domain.com/

    PerlInputFilterHandler Apache2::ModProxyPerlHtml
    PerlOutputFilterHandler Apache2::ModProxyPerlHtml
    SetHandler perl-script
    # Use line below iand comment line above if you experience error:
    # "Attempt to serve directory". The reason is that with SetHandler
    # DirectoryIndex is not working 
    # AddHandler perl-script *
    PerlSetVar ProxyHTMLVerbose "On"
    LogLevel Info


    <Location /webcal/>
        ProxyPassReverse /
        PerlAddVar ProxyHTMLURLMap "/ /webcal/"
        PerlAddVar ProxyHTMLURLMap "http://webcal.domain.com /webcal"
    </Location>

Note that here FilterHandlers are set globally, you can also set them in any
<Location> part to set it locally and avoid calling this Apache module globally.

If you want to rewrite some code on the fly, like changing images filename you
can use the perl variable ProxyHTMLRewrite under the location directive as
follow:

    <Location /webcal/>
        ...
        PerlAddVar ProxyHTMLRewrite "/logo/image1.png /images/logo1.png"
	# Or more complicated to handle space in the code as space is the
	# pattern / substitution separator character internally in ModProxyPerlHtml
	PerlAddVar ProxyHTMLRewrite "ajaxurl[\s\t]*=[\s\t]*'/blog' ajaxurl = '/www2.mydom.org/blog'"
        ...
    </Location>

this will replace each occurence of '/logo/image1.png' by '/images/logo1.png' in
the entire stream (html, javascript or css). Note that this kind of substitution
is done after all other proxy related replacements.

In some conditions javascript code can be replaced by error, for example:

        imgUp.src = '/images/' + varPath + '/' + 'up.png';

will be rewritten like this:

        imgUp.src = '/URL/images/' + varPath + '/URL/' + 'up.png';

To avoid the second replacement, write your JS code like that:

        imgUp.src = '/images/' + varPath + unescape('%2F') + 'up.png';

ModProxyPerlHTML replacement is activated on certain HTTP Content Type. If you
experienced that replacement is not activated for your file type, you can use the
ProxyHTMLContentType configuration directive to redefined the HTTP Content Type
that should be parsed by ModProxyPerlHTML. The default value is the following
Perl regular expresssion:

	PerlAddVar ProxyHTMLContentType    (text\/javascript|text\/html|text\/css|text\/xml|application\/.*javascript|application\/.*xml)

If you know exactly what you are doing by editing this regexp fill free to add
the missing Content-Type that must be parsed by ModProxyPerlHTML. Otherwise drop
me a line with the content type, I will give you the rigth expression. If you don't
know about the content type, with FireFox simply type Ctrl+i on the web page.

Some MS Office files may conflict with the above ProxyHTMLContentType regex like .docx or .xlsx
files. The result is that there could suffer of replacement inside and the file will be corrupted.
to prevent this you have the ProxyHTMLExcludeContentType configuration directive to exclude certain
content-type. Here is the default value:
 
	PerlAddVar ProxyHTMLExcludeContentType	(application\/vnd\.openxml)

If you have problem with other content-type, use this directive. For example, as follow:

	PerlAddVar ProxyHTMLExcludeContentType	(application\/vnd\.openxml|application\/vnd\..*text)

this regex will prevent any MS Office XML or text document to be parsed.

Some javascript libraries like JQuery are wrongly rewritten by ModProxyPerlHtml.
The problem is that those javascript code include some code and regex that are
detected as links and rewritten. The only way to fix that is to exclude those
files from the URL rewritter by using the "ProxyHTMLExcludeUri" configuration
directive. For example:

	PerlAddVar ProxyHTMLExcludeUri	jquery.min.js$
	PerlAddVar ProxyHTMLExcludeUri	^.*\/jquery-lib\/.*$

Any downloaded URI that contains the given regex will be returned asis without
rewritting. You can use this directive multiple time like above to match different
cases.

=head1 LIVE EXAMPLE

Here is the reverse proxy configuration I use to give access to Internet users
to internal applications:

    ProxyRequests Off
    ProxyPreserveHost Off
    ProxyPass       /webmail/  http://webmail.domain.com/
    ProxyPass       /webcal/  http://webcal.domain.com/
    ProxyPass       /intranet/  http://intranet.domain.com/


    PerlInputFilterHandler Apache2::ModProxyPerlHtml
    PerlOutputFilterHandler Apache2::ModProxyPerlHtml
    SetHandler perl-script
    # Use line below iand comment line above if you experience error:
    # "Attempt to serve directory". The reason is that with SetHandler
    # DirectoryIndex is not working 
    # AddHandler perl-script *
    PerlSetVar ProxyHTMLVerbose "On"
    LogLevel Info


    # URL rewriting
    RewriteEngine   On
    #RewriteLog      "/var/log/apache/rewrite.log"
    #RewriteLogLevel 9
    # Add ending '/' if not provided
    RewriteCond     %{REQUEST_URI}  ^/mail$
    RewriteRule     ^/(.*)$ /$1/    [R]
    RewriteCond     %{REQUEST_URI}  ^/planet$
    RewriteRule     ^/(.*)$ /$1/    [R]
    # Add full path to the CGI to bypass the index.html redirect that may fail
    RewriteCond     %{REQUEST_URI}  ^/calendar/$
    RewriteRule     ^/(.*)/$ /$1/cgi-bin/wcal.pl    [R]
    RewriteCond     %{REQUEST_URI}  ^/calendar$
    RewriteRule     ^/(.*)$ /$1/cgi-bin/wcal.pl     [R]


    <Location /webmail/>
        ProxyPassReverse /
        PerlAddVar ProxyHTMLURLMap "/ /webmail/"
        PerlAddVar ProxyHTMLURLMap "http://webmail.domain.com /webmail"
        # Use this to disable compressed HTTP
        #RequestHeader   unset   Accept-Encoding
    </Location>


    <Location /webcal/>
        ProxyPassReverse /
        PerlAddVar ProxyHTMLURLMap "/ /webcal/"
        PerlAddVar ProxyHTMLURLMap "http://webcal.domain.com /webcal"
    </Location>


    <Location /intranet/>
        ProxyPassReverse /
        PerlAddVar ProxyHTMLURLMap "/ /intranet/"
        PerlAddVar ProxyHTMLURLMap "http://intranet.domain.com /intranet"
	# Rewrite links that give access to the two previous location 
        PerlAddVar ProxyHTMLURLMap "/intranet/webmail /webmail"
        PerlAddVar ProxyHTMLURLMap "/intranet/webcal /webcal"
    </Location>

This gives access two a webmail and webcal application hosted internally to all
authentified users through their own Internet acces. There's also one acces to
an Intranet portal that have links to the webcal and webmail application. Those
links must be rewritten twice to works.

=head1 BUGS 

Apache2::ModProxyPerlHtml is still under development and is pretty
stable. Please send me email to submit bug reports or feature
requests.

=head1 COPYRIGHT

Copyright (c) 2005-2013 - Gilles Darold

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Apache2::ModProxyPerlHtml was created by :

	Gilles Darold
	<gilles at darold dot net>

and is currently maintain by me.

