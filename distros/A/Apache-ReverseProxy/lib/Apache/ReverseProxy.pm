package Apache::ReverseProxy;

# Copyright (c) 1999-2005 Clinton Wong.
# Additional modifications Copyright (c) 2000 David Jao.
# Additional modifications Copyright (c) 2005 Penny Leach.
# All rights reserved.

# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# This is based on Apache::ProxyPass, by Michael
# Smith <mjs@iii.co.uk>, which is based on Apache::ProxyPassThru.

use strict;
use Apache::Constants ':common';
use LWP;
use CGI;
use Symbol 'gensym';
use vars qw($VERSION);
$VERSION = '0.07';

sub handler {

  my $r = shift;
  my %regex;
  my %exact;
  my %cookie_trans;
  my %no_query_replace;

  # figure out the config file
  my $conf = $r->dir_config('ReverseProxyConfig');
  if (! defined $conf ) {
    $r->log_error("ReverseProxyConfig directive not defined");
    return DECLINED;
  }

  my $chain = $r->dir_config('ReverseProxyChain');
  my $noproxy = $r->dir_config('ReverseProxyNoChain');

  # read config file
  my $f = gensym();
  if (! open($f, $conf) )  {
    $r->log_error("Couldn't open config file: " . $conf);
    return DECLINED;
  }

  while (my $line=<$f>) {
    chomp($line);
    $line =~ s/(^\s+)|(\s+$)//;          # kill leading,trailing space
    next if (substr($line,0,1) eq '#');  # skip comments
    
    if ($line =~ /^([^\s]+)\s+([^\s]+)(\s+([^\s]+)){0,1}/) {
      my $from = $1; my $to=$2; my $options = $3 || '';

      # do URL mappings
      if ($options =~ /exact/i) { $exact{$from} = $to }
      else { $regex{$from} = $to }
      if ($options =~ /cookietrans/i) { $cookie_trans{$from} = 1 }
      if ($options =~ /noquerykeyreplace/i) { $no_query_replace{$from} = 1 }

    } # if valid line
  } # while config file input
  close($f);

  my $uri = $r->uri();

  my $uri_with_qs = $uri;
  my $query = $r->args() || '';   # from the user's request
  if (length $query) { $uri_with_qs .= '?' . $query }
  
  my $changed=0;


  if ( defined $exact{$uri} ) {			# try an exact uri match first
    $uri = $exact{$uri};
    $changed=1;
  }
  elsif ( defined $exact{$uri_with_qs} ) {	# try exact uri with qs 
    $uri = $exact{$uri_with_qs};
    $changed=1;
  }
  else {

    # otherwise, try regular expression matching
    foreach my $key (keys(%regex)) {
      if ($uri =~ /^$key/) {

	$changed=1;

        # replace URI's first, then append query string
        my $replace_uri = $regex{$key};
        my $replace_query='';
        if ($replace_uri =~ s/\?(.*)$//) { $replace_query = $1 }

        $uri =~ s/$key/${replace_uri}/;
	if (length $replace_query) { $uri .= '?' . $replace_query }
        last;
      }
    } # for each regex match...

  } # regex matching


  if ($changed) {

    # strip out possible query string from re-written uri, store it
    my $munged_uri = $uri;
    my $munged_uri_query = '';
    if ($munged_uri =~ s/\?(.*)$//) { $munged_uri_query = $1 }

    # query string processing
    my $query = $r->args() || '';   # from the user's request
 
    # user has query, but munged url doesn't
    if ( defined $query && length($query) && length($munged_uri_query)==0) {
      $munged_uri_query = $query;
    }
    elsif (defined $query && length($query)) {
          # if the user had a query string, add it in to the munged uri's qs
      my $internal = new CGI($munged_uri_query);
      my $user_query = new CGI($query);
      foreach my $user_key ( $user_query->param() ) {
        # if we can't replace and the variable exists in both places, skip it

#        unless ($internal->param($user_key) && $user_query->param($user_key) 
#                  && defined $no_query_replace{$orig_uri} ) {

          $internal->param($user_key, $user_query->param($user_key) );
#        }
      } # for each variable in the user's query string
      $munged_uri_query = $internal->query_string();  # stringify 
    }

    if (length $munged_uri_query) { $uri = $munged_uri .'?'. $munged_uri_query }


    my $request = new HTTP::Request($r->method, $uri);

    # copy in client headers
    my(%headers) = $r->headers_in();
    for (keys(%headers)) {
      $request->header($_, $headers{$_});
    }
 
    my $host = $uri;
    $host =~ s/([a-zA-z]*:\/\/)([a-zA-Z0-9.-]*)([:0-9]*)\/.*/$2/;
    $request->header('Host', $host);
    my $ua = new LWP::UserAgent('max_redirect' => 0);

    if (defined $chain) {
      $ua->proxy(['http', 'https', 'ftp', 'gopher'], $chain);
      if (defined $noproxy) { $ua->noproxy($noproxy) }
    }
    
    # copy over the client's user-agent, since some servers look at
    # this and customize their response based on it.

    my $origin_ua = $r->header_in('user-agent');
    if (defined $origin_ua && length $origin_ua) {
      $ua->agent($origin_ua)
    }

    # copy over the content type
    my $content_type = $r->header_in('content-type');
    if (defined $content_type && length $content_type) {
      $request->header('content-type', $content_type);
    }

    # copy over the entity body as well
    my $entity_body = $r->content();
    if (defined $entity_body && length $entity_body) {
      $request->content($entity_body);
    } else {
        my $buff = '';
        $r->read($buff, $r->header_in('Content-length'));
        if ($buff ne '') {
            $request->content($buff);
        }
    }

    # Okay now for the fireworks. We use a custom subroutine to send an
    # http header and then display the content in chunks of 4096 bytes.
    # In this way we avoid reading the entire request into core and forcing
    # the web browser to wait for the entire file to be downloaded before
    # receiving any data.
    my $first_time=1;
    my $response = $ua->request($request, sub {
      my($data, $response, $protocol) = @_;
      if ($first_time == 1) {
        $r->content_type($response->header('Content-type'));
        $r->status($response->code());

        $r->status_line($response->code() . ' ' .  $response->message());

        $response->scan(sub { $r->headers_out->add(@_); });
        $r->send_http_header();
        $first_time=0;
      }
      print "$data";
    }
, 4096);
    # If the custom subroutine above did not get called, that means our
    # http request must have failed (c.f. LWP::UserAgent documentation).
    # We handle that case here.
    if ($first_time == 1) {
      $r->content_type($response->header('Content-type'));
      $r->status($response->code());

      $r->status_line($response->code() . ' ' . $response->message());

      $response->scan(sub { $r->headers_out->add(@_); });
      $r->send_http_header();
      $first_time=0;
      print $response->content();
    }
    return OK;

  }  # if uri changed

  return DECLINED;

} # handler

1;
__END__

=head1 NAME

Apache::ReverseProxy - An Apache mod_perl reverse proxy

=head1 SYNOPSIS

 # In Apache config file
 <Location />
 SetHandler perl-script
 PerlHandler Apache::ReverseProxy
 PerlSetVar ReverseProxyConfig /usr/local/apache/conf/rproxy.conf
 </Location>

# In rproxy.conf
 / http://www.cpan.org/

=head1 DESCRIPTION

This is a reverse proxy module for Apache with mod_perl.  It is intended
to replace Apache::ProxyPass.  Given a list of URI mappings,
this module will translate an incoming URI, retrieve the contents for
the translated URI, and return the contents to the original requestor.
This module allows you to specify exact matching (instead of regular
expression matching) and handles query string translations.

=head1 CONFIGURATION

You will need to set the ReverseProxyConfig perl variable in Apache
to the path of the reverse proxy mapping file.  For example:

 <Location />
 SetHandler perl-script
 PerlHandler Apache::ReverseProxy
 PerlSetVar ReverseProxyConfig /usr/local/apache/conf/rproxy.conf

 # Optional configuration items:
 #PerlSetVar ReverseProxyChain http://proxy.mycompany.com:8888/
 #PerlSetVar ReverseProxyNoChain mycompany.com
 </Location>

B<ReverseProxyChain> specifies a proxy server to use.  This is 
sometimes called I<proxy chaining> when one proxy server uses
another proxy server.  The B<ReverseProxyNoChain> directive can specify
a domain to not use proxy chaining on.


Reverse proxy configuration files have three fields, each separated by
white space.  The first field is the uri to look for, the second
field is the replacement uri, and the third field is optional
and allows you to specify comma separated options for the mapping.
The only option that is currently supported is the B<exact> parameter,
which will make the reverse proxy use exact matching for the first
parameter instead of using regular expressions.  This feature
is convenient when the first parameter contains characters
that may need to be escaped or quotemeta'ed.  Exact options are
evaluated first.  If there isn't an exact match, regular expression
matches are performed.  Configuration files may contain comments,
which start with a pound sign.  For example:

 /news/ http://www.news.com/
 / http://www.perl.com/
 /stats http://localhost/stats exact
 # /stats maps exactly to http://localhost/stats
 # /stats/b maps to http://www.perl.com/stats/b
 /french/news http://www.news.com/?language=french
 # /french/news/index -> http://www.news.com/index?language=french
 # /french/news/index?a=b -> http://www.news.com/index?language=french&a=b


=head1 TO-DO

  1. Cookie header translation.
  2. Verbose/debug logging.

=head1 REQUIREMENTS

 This module requires LWP, available at:
 http://www.cpan.org/modules/by-module/LWP/

=head1 AUTHOR

 Clinton Wong, http://search.cpan.org/~clintdw/

=head1 COPYRIGHT

 Copyright (c) 1999-2005 Clinton Wong.
 Additional modifications Copyright (c) 2000 David Jao.
 Additional modifications Copyright (c) 2005 Penny Leach.
 All rights reserved.
 
 This program is free software; you can redistribute it
 and/or modify it under the same terms as Perl itself.
 
 This module is based on Apache::ProxyPass, by Michael
 Smith <mjs@iii.co.uk>, which is based on Apache::ProxyPassThru.

=cut

