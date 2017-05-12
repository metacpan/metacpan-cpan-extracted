# $Id: WebUtils.pm,v 1.9 2003/07/10 09:43:20 matt Exp $

# Original Code and comments from Steve Willer.

package AxKit::XSP::WebUtils;

$VERSION = "1.6";

# taglib stuff
use AxKit 1.4;
use Apache;
use Apache::Constants qw(OK);
use Apache::Util;
use Apache::Request;
use Apache::URI;
use Apache::AxKit::Language::XSP::TaglibHelper;
sub parse_char  { Apache::AxKit::Language::XSP::TaglibHelper::parse_char(@_); }
sub parse_start { Apache::AxKit::Language::XSP::TaglibHelper::parse_start(@_); }
sub parse_end   { Apache::AxKit::Language::XSP::TaglibHelper::parse_end(@_); }

$NS = 'http://axkit.org/NS/xsp/webutils/v1';

@EXPORT_TAGLIB = (
  'env_param($name)',
  'path_info()',
  'query_string()',
  'request_uri()',
  'request_host()',
  'server_root()',
  'redirect($uri;$host,$secure,$use_refresh)',
  'url_encode($string)',
  'url_decode($string)',
  'header($name;$value)',
  'return_code($code)',
  'username()',
  'password()',
  'request_parsed_uri(;$omit)',
  'request_prev_parsed_uri(;$omit)',
  'request_prev_uri()',
  'request_prev_query_string()',
  'request_prev_param($name)',
  'match_useragent($name)',
  'is_https()',
  'is_initial_req()',
  'variant_list():as_xml=true',
  'error_notes()',
  'server_admin()',
);

@ISA = qw(Apache::AxKit::Language::XSP);

use strict;

sub env_param ($) {
    my ($name) = @_;

    return $ENV{$name};
}

sub path_info () {
    my $Request = AxKit::Apache->request;
    return $Request->path_info;
}

sub query_string () {
    my $Request = AxKit::Apache->request;
    return $Request->query_string;
}

sub request_uri () {
    my $Request = AxKit::Apache->request;
    return $Request->uri;
}

sub server_root () {
    my $Request = AxKit::Apache->request;
    return $Request->document_root;
}

sub request_host () {
    my $hostname = Apache->header_in('Via');
    $hostname =~ s/^[0-9.]+ //g;
    $hostname =~ s/ .*//g;
    $hostname ||= $ENV{HTTP_HOST};
    $hostname ||= Apache->header_in('Host');
    return $hostname;
}

sub redirect ($;$$$) {
    my ($uri, $host, $secure, $use_refresh) = @_;
    
    if (lc($secure) eq 'yes') { $secure = 1 }
    elsif (lc($secure) eq 'no') { $secure = 0 }
    if (lc($use_refresh) eq 'yes') { $use_refresh = 1 }
    elsif (lc($use_refresh) eq 'no') { $use_refresh = 0 }
    
    my $myhost = $host;

    my $Request = AxKit::Apache->request;

    if ($uri !~ m|^https?://|oi) {
        if ($uri !~ m#^/#) {
            $uri = "./$uri" if $uri =~ /^\./;

            # relative path, so let's resolve the path ourselves
        my $base = $Request->uri;
            $base =~ s{[^/]*$}{};
        $uri = "$base$uri";
        $uri =~ s{//+}{/}g;
        $uri =~ s{/.(/|$)}{/}g;                     # embedded ./
        1 while ($uri =~ s{[^/]+/\.\.(/|$)}{}g);   # embedded ../
        $uri =~ s{^(/\.\.)+(/|$)}{/}g;              # ../ off of "root"
    }

        if (not defined $host) {
            $myhost = $Request->header_in("Host");

            # if we're going through a proxy, the virtual host is rewritten; yuck
            if ($myhost !~ /[a-zA-Z]/) {
                my $Server = $Request->server;
                $myhost = $Server->server_hostname;
                my $port = $Server->port;
                $myhost .= ":$port" if $port != 80;
            }
        }
        
        my $scheme = 'http';
        $scheme = 'https' if $secure; # Hmm, might break if $port was set above...
        if ($use_refresh) {
            $Request->header_out("Refresh" => "0; url=${scheme}://${myhost}${uri}");
            $Request->content_type("text/html");
            $Request->status(200);
        }
        else {
            $Request->header_out("Location" => "${scheme}://${myhost}${uri}");
            $Request->status(302);
        }
    }
    else {
        if ($use_refresh) {
            $Request->header_out("Refresh" => "0; url=$uri");
            $Request->content_type("text/html");
            $Request->status(200);
        }
        else {
            $Request->header_out("Location" => $uri);
            $Request->status(302);
        }
    }
    
    $Request->send_http_header;
    
    Apache::exit();
}

sub header ($;$) {
    my $name = shift;
    my $r = AxKit::Apache->request;
    
    if (@_) {
        return $r->header_out($name, $_[0]);
    }
    else {
        return $r->header_in($name);
    }
}

sub url_encode ($) {
    return Apache::Util::escape_uri(shift);
}

sub url_decode ($) {
    return Apache::Util::unescape_uri(shift);
}

sub return_code ($) {
    my $code = shift;

    my $Request = AxKit::Apache->request;

    $Request->status($code);
    
    $Request->send_http_header;
    
    Apache::exit();
}

sub username () {
    my $r = AxKit::Apache->request;
    
    return $r->connection->user;
}

sub password () {
    my $r = AxKit::Apache->request;
    
    my ($res, $pwd) = $r->get_basic_auth_pw;
    if ($res == OK) {
        return $pwd;
    }
    return;
}

sub request_parsed_uri ($) {
    my $omit = shift;
    my $r = AxKit::Apache->request;
    my $uri = Apache::URI->parse($r);

    if ($omit eq 'path') {
        $uri->path(undef);
        $uri->query(undef); # we don't want a query without a path
    }
    elsif ($omit eq 'path_info' or $omit eq 'query') {
        $uri->$omit(undef);
    }

    return $uri->unparse;
}

sub request_prev_parsed_uri ($) {
    my $omit = shift;
    my $r = AxKit::Apache->request;
    my $uri = Apache::URI->parse($r->prev||$r);

    if ($omit eq 'path') {
        $uri->path(undef);
        $uri->query(undef); # we don't want a query without a path
    }
    elsif ($omit eq 'path_info' or $omit eq 'query') {
        $uri->$omit(undef);
    }

    return $uri->unparse;
}

sub request_prev_uri () {
    my $r = AxKit::Apache->request;
    return ($r->prev||$r)->uri;
}

sub request_prev_query_string () {
    my $r = AxKit::Apache->request;
    return ($r->prev||$r)->query_string;
}

sub request_prev_param ($) {
    my $name = shift;
    my $apr = Apache::Request->instance((AxKit::Apache->request->prev||AxKit::Apache->request));

    return $apr->param($name);
}

sub match_useragent ($) {
    my $name = shift;
    my $r = AxKit::Apache->request;

    return $r->header_in('User-Agent') =~ $name;
}

sub is_https () {
    my $r = AxKit::Apache->request;
    return 1 if $r->subprocess_env('https');
}

sub is_initial_req () {
    my $r = AxKit::Apache->request;
    return $r->is_initial_req;
}

sub variant_list () {
    my $r = AxKit::Apache->request;
    my $variant_list = ($r->prev||$r)->notes('variant-list');

    $variant_list =~ s/([^:>])\n/$1<\/li>\n/g; # tidy up single li-tags because 
                                               # mod_negotiation's list is not
                                               # well-balanced up to Apache 1.3.28

    return $variant_list;
}

sub error_notes () {
    my $r = AxKit::Apache->request;
    return ($r->prev||$r)->notes('error-notes');
}

sub server_admin () {
    my $r = AxKit::Apache->request;
    return $r->server->server_admin;
}


1;

__END__

=head1 NAME

AxKit::XSP::WebUtils - Utilities for building XSP web apps

=head1 SYNOPSIS

Add the taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::WebUtils

Add the C<web:> namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:web="http://axkit.org/NS/xsp/webutils/v1"
    >

Then use the tags:

  <web:redirect>
    <web:uri>foo.xsp</web:uri>
  </web:redirect>

=head1 DESCRIPTION

The XSP WebUtils taglib implements a number of features for building
web applications with XSP. It makes things like redirects and
getting/setting headers simple.

=head1 TAG REFERENCE

All of the below tags allow the parameters listed to be either passed
as an attribute (e.g. C<<web:env_param name="PATH">>), or as a child
tag:

  <web:env_param>
    <web:name>PATH</web:name>
  </web:env_param>

The latter method allows you to use XSP expressions for the values.

=head2 C<<web:env_param name="..." />>

Fetch the environment variable specified with the B<name> parameter.

  <b>Server admin: <web:env_param name="SERVER_ADMIN"/></b>

=head2 C<<web:path_info/>>

Returns the current PATH_INFO value.

=head2 C<<web:query_string/>>

Returns the current query string

=head2 C<<web:request_uri/>>

Returns the requested URI minus optional query string

=head2 C<<web:request_host/>>

This tag returns the end-user-visible name of this web service

Consider www.example.com on port 80. It is served by a number of
machines named I<abs>, I<legs>, I<arms>, I<pecs> and I<foo1>, on a
diversity of ports. With a proxy server in front that monkies with the
headers along the way. It turns out that, while writing a script,
people often wonder "How do I figure out the name of the web service
that's been accessed?". Various hacks with uname, hostname, HTTP
headers, etc. ensue.   This function is the answer to all your
problems.

=head2 C<<web:server_root/>>

Returns the server root directory, aka document root.

=head2 C<<web:redirect>>

This tag allows an XSP page to issue a redirect.

Parameters (can be attributes or child tags):

=over 4

=item uri (required)

The uri to redirect to.

=item host (optional)

The host to redirect to.

=item secure (optional)

Set to "yes" if you wish to redirect to a secure (ssl/https) server.

=back

Example (uses XSP param taglib):

  <web:redirect secure="yes">
    <web:uri><param:goto/></web:uri>
  </web:redirect>

=head2 C<<web:url_encode string="..."/>>

Encode the string using URL encoding according to the URI specification.

=head2 C<<web:url_decode string="..."/>>

Decode the URL encoded string.

=head2 C<<web:header>>

This tag allows you to get and set HTTP headers.

Parameters:

=over 4

=item name (required)

The name of the parameter. If only name is specified, you will B<get>
the value of the incoming HTTP header of the given name.

=item value (optional)

If you also specify a value parameter, then the tag will B<set> the
outgoing HTTP header to the given value.

=back

Example:

  <p>
  Your browser is: <web:header name="HTTP_USER_AGENT"/>
  </p>

=head2 C<<web:return_code/>>

This tag allows you to set the reply status for the client request.

Parameters:

=over 4

=item code (required)

The integer value of a valid HTTP status code.

=back

=head2 C<<web:username/>>

Returns the name of the authenticated user.

=head2 C<<web:password/>>

If the current request is protected by Basic authentication, this tag
will return the decoded password sent by the client.

=head2 C<<web:request_parsed_uri>>

This tag allows you to get the fully parsed URI for the current request.
In contrast to <web:request_uri/> the parsed URI will always include things like
scheme, hostname, or the querystring.

Parameters:

=over 4

=item omit (optional)

Valid values: B<path>, B<path_info>, and B<query>.
If specified, the corresponding URL components will be ommited for the return value.

=back

=head2 C<<web:request_prev_parsed_uri>>

This tag allows you to get the fully parsed URI for the previous request. This can be useful
in 403 error documents where it is required to post login information back to the originally
requested URI.

Parameters:

=over 4

=item omit (optional)

Valid values: B<path>, B<path_info>, and B<query>.
If specified, the corresponding URL components will be ommited for the return value.

=back

Example:

  <p>Access Denied. Please login</p>
  <form method="post" name="login">
      <xsp:attribute name="action">
          <web:request_prev_parsed_uri omit="query"/>
      </xsp:attribute>
      ...

=head2 C<<web:request_prev_uri/>>

Returns the URI of the previous request minus optional query string

=head2 C<<web:request_prev_query_string/>>

Returns the query string of the previous request.

=head2 C<<web:request_prev_param name="...">>

Returns the value of the requested CGI parameter of the previous request.

Parameters:

=over 4

=item name (required)

The name of the parameter to be retrieved.

=back

=head2 C<<web:match_useragent name="...">>

Returns true if the User Agent pattern in B<name> matches the current User Agent.

Parameters:

=over 4

=item name (required)

A User Agent pattern string to be matched.

=back

Example:

  <xsp:logic>
  if (!<web:match_useragent name="MSIE|Gecko|Lynx|Opera"/>) {
  </xsp:logic>
      <h1>Sorry, your Web browser is not supported.</h1>
  <xsp:logic>
  }
  else {
  </xsp:logic>
  ...

=head2 C<<web:is_https/>>

Returns true if the current request comes in via SSL.

Example:

  <xsp:logic>
  if (!<web:is_https/>) {
  </xsp:logic>
    <a>
      <xsp:attribute name="href">
        https://<web:request_host/><web:request_uri/>
      </xsp:attribute>
      use secure connection
    </a>
  <xsp:logic>
  }
  </xsp:logic>

=head2 C<<web:is_initial_req/>>

Returns true if the current request is the first internal request, returns
false if the request is a sub-request or an internal redirect.

=head2 C<<web:variant_list/>>

Returns the list of variants returned by mod_negotation in case of a 406 HTTP status code.
Useful for 406 error documents.

Example:

  <h1>406 Not Acceptable</h1>
  <p>
    An appropriate representation of the requested resource <web:request_prev_uri/>
    could not be found on this server.
  </p>
  <web:variant_list/>

=head2 C<<web:server_admin/>>

Returns the value of the Apache "ServerAdmin" config directive.

=head2 C<<web:error_notes/>>

Returns the last 'error-notes' entry set by Apache. Useful for verbose 500 error documents.

Example:

    <h1>Server Error</h1>

    <p>An error occured. If the problem persists, please contact <web:server_admin/>.</p>
    <p>Error Details:<br/>
        <web:error_notes/>
    </p>

=head1 AUTHOR

Matt Sergeant, matt@axkit.com

Original code by Steve Willer, steve@willer.cc

=head1 LICENSE

This software is Copyright 2001 AxKit.com Ltd.

You may use or redistribute this software under the terms of either the
Perl Artistic License, or the GPL version 2.0 or higher.

