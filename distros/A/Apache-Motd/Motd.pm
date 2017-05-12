package Apache::Motd;
## FILE: Apache/Motd.pm 
##       $Id: Motd.pm,v 1.2 2002/11/01 00:39:57 ramirezc Exp $

use strict;
use vars qw($VERSION);
use Apache;
use Apache::Cookie;
use Apache::Constants qw(:common REDIRECT);

$VERSION = '1.00';

sub handler {
    my $r    = shift;
    my $uri  = $r->uri;
    my $cn   = $r->dir_config('CookieName')     || 'seenMOTD';
    my $exp  = $r->dir_config('ExpireCookie')   || '+1d';
    my $file = $r->dir_config('MessageFile')    || 0;
    my $cookieless = $r->dir_config('SupportCookieLess') || 1;
    my $port = ($r->server->port eq '80') ? "" : ':'.$r->server->port;
    my $tquery = $r->args; 

    ## If the request is the part of the cookie test redirect, then
    ## take out the ct=1 query_string value and make a note of it
    ## by setting $ct_request
    my $ct_request = 0;
    if ($tquery =~ /ct=1/) { 
       $ct_request=1;
       $tquery =~ s/ct=1//; 
       $r->args($tquery) if ($tquery =~ /=/);
    }

    return OK unless $r->is_initial_req;

    ## MessageFile appears to be missing, pass onto next phase
    return OK unless $file;
    return OK unless -e $file;
 
    ## Look for cookie ($cn) and verify it's value
    my $cookies = Apache::Cookie->new($r)->parse;
    if (my $c = $cookies->{$cn}) {
       my $cv = $c->value;
       return OK if ($ct_request == 0  && $cv eq '1');
       displayMotd($r);
       return DONE;
    }

    ## Prepare cookie information and add outgoing headers
    my $cookie = Apache::Cookie->new($r,
                      -name => $cn,-value => '1',-expires => $exp );
    $cookie->bake;

    ## Handle Cookieless clients
    if ($cookieless) {
       ## Apparently this client does not like cookies, pass it on to
       ## next phase
       $r->log_error("Apache::Motd::Bypassed by ".
                     $r->connection->remote_ip) if $ct_request;
       return OK if $ct_request;

       my $host   = $r->hostname;
       my $ct_url = 'http://'.$host.$port.$uri.'?ct=1';
       ## Test for client for cookie worthiness by redirecting client
       ## to same $uri but along with the cookie testflag (ct=1) in the
       ## query_string
       $r->header_out("Location" => $ct_url);
       return REDIRECT;
    }

    displayMotd($r);
    return DONE;
}

sub displayMotd {
    my $r    = shift;
    my $uri  = $r->uri;
    my $file = $r->dir_config('MessageFile');
    my $sec  = $r->dir_config('RedirectInSecs') || 10;

    ## Open motd file, otherwise server error
    unless (open MSG,$file) {
       $r->log_error("Apache::Motd::Error : Unable to load: $file");
       return SERVER_ERROR;
    }
 
    ## Slurp message $file into a string
    my $msg = "";
    {
      local $/;
      $msg = <MSG>;
    }
    close MSG;
 
    ## Substitute template variables
    $msg =~ s/<VAR_URI>/$uri/g;
    $msg =~ s/<VAR_REDIRECT>/$sec/g;

    ## Maintain a small logging trail
    $r->log_error("Apache::Motd::Display URI: $uri ".$r->connection->remote_ip);

    my $headers = $r->headers_out;
       $headers->{'Pragma'} = $headers->{'Cache-control'} = 'no-cache';

    ## straight form the mod_perl guide
    $r->no_cache(1);
    $r->send_http_header('text/html');
    $r->print($msg);
}

1;
__END__


=head1 NAME

Apache::Motd - Provide motd (Message of the Day) functionality to a webserver

=head1 SYNOPSIS

 in your httpd.conf 

 <Directive /path/>
   PerlHeaderParserHandler Apache::Motd
   PerlSetVar MessageFile       /path/to/motd/message 
   PerlSetVar CookieName        CookieName [default: seenMOTD]
   PerlSetVar ExpireCookie      CookieExpirationTime [default: +1d]
   PerlSetVar RedirectInSecs    N [default: 10]
   PerlSetVar SupportCookieLess (1|0) [default: 1]

=head1 DESCRIPTION

This Apache Perl module provides a web administrator the ability to 
configure a webserver with motd (Message of the Day) functionality, just
like you find on UNIX systems. This allows custom messages to appear when 
visitors enter a website or a section of the website, without the need to
modify any webpages or web application code!  The message can be a "Message 
of the Day", "Terms of Use", "Server Going Down in N Hours", etc. When 
applied in the main server configuration (i.e. non <Location|Directory|Files> 
directives), any webpage accessed on the webserver will redirect the visitor 
to the custom message momentarily. Then after N seconds, will be redirected 
to their originally requested URI, at the same time setting a cookie so that 
subsequent requests will not be directed to the custom message.  A link to the 
requested URI can also be provided, so that the user has the option of 
proceeding without having to wait the entire redirect time. (See motd.txt 
example provided in this distribution)
 

The intention of this module is to provide an alternate and more efficient
method of notifying your web users of potential downtime or problems affecting
your webserver and/or webservices.


=head1 CONFIGURATION

The module can be placed in <Location>, <Directory>, <Files> and main server
configuration areas. 

=over 4

=item B<MessageFile>

The absolute path to the file that contains the custom message. 

 i.e. MessageFile /usr/local/apache/motd.txt

If the file is not found in the specified directory all requests will not be 
directed to the B<motd>.  Therefore you can rename,delete this file from the 
specified location to disable the B<motd> without having to edit the 
httpd.conf entry and/or restart the web server.

See B<MessageFile Format> for a description how the message should
be used.

=item B<RedirectInSecs> (default: 10 seconds)

This sets the wait time (in seconds) before the visitor is redirected to the
initally requested URI


=item B<CookieName> (default: seenMOTD)

Set the name of the cookie name 


=item B<ExpireCookie> (default: +1d, 1 day)

Set the expiration time for the cookie

=item B<SupportCookieLess> (default: 1)

This option is set by default to handle clients that do not support
cookies or that have cookies turned off. It performs an external
redirect to the requested C<$uri> along with a C<ct=1> query_string to test
if the client accepts cookies. If the external redirect successfully sets 
the cookie, the user is presented with the B<motd>,  otherwise the user is
not directed to the B<motd> but to the C<$uri>.

Future versions will correctly support non-cookie clients via URL munging.

Setting this option to 0 is ideally used for when you are totally certain
that all your visitors will accept cookies. This is usually much faster since
it elminates the external redirect. ***Use with caution. Cookieless clients
will get the motd message and *only* the motd if this option is false.

=back

   Example:

   <Location />
    PerlHeaderParserHandler Apache::Motd
    PerlSetVar MessageFile /proj/www/motd.txt
    PerlSetVar CookieName TermUsage
    PerlSetVar RedirectInSecs 5
   </Location>


  The example above, sets a server wide message (/proj/www/motd.txt) that
  sets a cookie called TermUsage which expires in one day (default value)
  and redirects the user to the original URI in 5 seconds.


=head1 Message File Format

The text file should at least include the folowing tag variables.  These
tags provide neccessary information to allow redirection to the original
request and the time (in secs) before the redirection take place.

=over 4

=item B<VAR_URI>

This tag will be replaced with the requested URI. 

Recommended usage:

<a href="<VAR_URI>">click here to proceed</a>

The above example provides a link to the original requested URI, so that
a user can click and bypass the time redirect.



=item B<VAR_REDIRECT>

This tag will be replaced with the value set in RedirectInSecs.
Which can be used in the meta tag for redirection. 

=back

Example:

   ...
   <head>
   <meta http-equiv="refresh" content="<VAR_REDIRECT>;URL=<VAR_URI>">
   ...
   </head>
   ...

The custom message should at least contain a redirect (using a meta tag) and
a link to allow users to bypass the redirect time (for impatient users and
as a courtesy). Omitting these will result in the page not redirecting the user
to the initially requested page.

=head1 NOTES

B<Bypassing Motd>

<Directory> and <Location> configuration settings propogate to sub-directories
and sub-locations matches. One way to turn off the motd on a motd'd 
sub-directories and locations is to do the following:

 <Location />
  PerlHeaderParserHandler Apache::Motd
 </Location>

 ## Bypass motd on locations under /foo
 <Location /foo>
  PerlHeaderParserHandler Apache::Motd:OK
 </Location>

 **Example courtesy of Jerrad Pierce

B<Logging>

There are two times Apache::Motd logs non-error messages to the apache
error_logs. One instance is when the motd is displayed and the other
is when the motd is bypassed because cookies were rejected.

 ## motd displayed sample entry
 [Wed Dec 13 14:17:57 2000] [error] Motd::Display for URI: /requested/doc.html from $remote_ip

 ## motd is bypassed sample entry
 [Wed Dec 13 14:17:57 2000] [error] Motd::Bypassed by $remote_ip


These entries can by used to gather statistics about how many times the
motd is being encountered and how many times it's being bypassed.


=head1 BUGS

=over 4

=item Minimal Support for cookie-less clients

Browsers that have their cookies turned off or that do not support them
will not see the motd. I hope to implement a URL-based solution so that
Apache::Motd will support these browsers correctly. So in the meantime,
you must find other ways of relaying your urgent messages to your visitors. 

=item No error checking on the custom message

The template is not checked for the neccessary information required for the
redirection to work properly, i.e. usage of <VAR_URI> and <VAR_REDIRECT>. 
Therefore not using the available tags as described will result in 
unpredictable behavior.

=back
 

=head1 REQUIREMENTS

 L<mod_perl>, L<Apache::Cookie>


=head1 CREDITS

Fixes, Bug Reports, Optimizations and Ideas have been generously provided by:

Jerrad Pierce <jpierce@cpan.org>
 - no-cache pragma on motd file
 - motd bypass on sub-directories and location matches
 - no-cookie browser problem bug report

Marion Gazdak
 - Missing server port bug. Fixes problem when testing on the
   non-standard port (80)
 - Check for existance of motd file specified in MessageFile. Removing
   motd file from location specified in MessageFile disables motd. Now
   works as advertised.

=head1 AUTHOR

 Carlos Ramirez <carlos@quantumfx.com>

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 

If you have questions or problems regarding use or installation of this module
please feel free to email me directly.


=cut
