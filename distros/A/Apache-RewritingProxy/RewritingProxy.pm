package Apache::RewritingProxy;

use strict;
use Apache::Constants qw(:common);
use vars '$req';
use vars '$res';
use vars '$proxiedCookieJar';
use vars '$replayCookies';
use vars '$serverCookies';
use vars '$jar';
use vars '$textHandlerSub';
use vars qw($VERSION @ISA @EXPORT);
$|=1;

$VERSION = '0.7';

# use DynaLoader ();
# @ISA = qw(DynaLoader Exporter);

use Exporter();
@ISA = qw(Exporter);
@EXPORT = qw(new handler fixLink fetchURL);

# This is the directory in which cacheing will eventually take
# place.  More importantly, a subdirectory of this named cookies
# MUST exist and be writeable by the web server.  This is where users'
# cookie jars are stored.

$Apache::RewritingProxy::cacheRoot = '/web/httpd/RewritingProxy';


sub new 
  {
  my $class = shift;
  my $self = {};
  bless $self,$class;
  return $self;
  }

sub handler
  {
  my $r = shift;
  $textHandlerSub = shift;

  # Find the URL we are to fetch...
  my $urlToFetch = substr($r->path_info,1);

  # I only know one protocol thus far.
  return DECLINED if ($urlToFetch !~ /^http:/);

  # Get the resource and shovel it out to the client.
  &fetchURL($r, $urlToFetch);

  # If nothing has happened thus far, we'll assume that's good.
  return OK;
  }

##################################
# sub fetchURL
#
# Parameters:
#
# $r - an Apache request object
# $url - the URL to fetch and process.
#
# Returns:
#
# OK if it's happy.
# an HTTP response code if one other than 200 
# is received.

sub fetchURL
  {
  # This is the guy who actually grabs the page and then parses it.
  # My goal is to find all of the links made in the urlToFetch
  # and rewrite them to be absolute links passing through this module
  # again.
  use Apache::Util qw(:all);
  use LWP::UserAgent;
  use HTML::TokeParser;
  use HTTP::Cookies;
  use CGI;
  my $r = shift;
  my $url = shift;
  my $ua = new LWP::UserAgent;
  # As we form the request to go to the remote server,
  # We should stuff any cookies that might be relavant
  # into the request.  We need to use the Table class
  # here to fetch the cookies and see what cookies 
  # apply to $url.  We then sent those cookies 
  # in the request after yanking out our own URL from 
  # the cookies.
  
  # Fetch a cookie named RewritingProxy from the client.
  my $cookieKey;
  my $clientCookies = $r->header_in('Cookie');
  my @clientCookiePairs = split (/; /, $clientCookies);
  my $thisClientCookiePair;
  foreach $thisClientCookiePair (@clientCookiePairs)
    {
    my ($name,$value) = split (/=/, $thisClientCookiePair);
    $cookieKey = $value if ($name eq "RewritingProxyCookieJar");
    }

  # Set the cookie to be the client's current IP (doesn' really matter).
  # Set the cookie to expire in 6 months.
  # TODO: Make this thing refresh if a client keeps using the proxy.
  if (!$cookieKey)
    {
    $cookieKey = $r->get_remote_host();
    my $cookieString = "RewritingProxyCookieJar=$cookieKey; expires=".
      ht_time(time+518400). "; path=/; domain=".$r->get_server_name;	
    $r->header_out('Set-Cookie'=>$cookieString);
    }
    
  # We now need to open the User's cookie jar and see if any cookies 
  # need to be sent to this particular server.
  $jar = "$Apache::RewritingProxy::cacheRoot/cookies/$cookieKey";
  $serverCookies = HTTP::Cookies->new(
	File => "$jar",
        ignore_discard=>1,
        AutoSave=>1);
  # Load the cookies into memory...
  $serverCookies->load() if (-e $jar);

  # Let's take care of Referer also.
  my $referer = $r->header_in('Referer');
  my $script_name = $r->location;
  $referer =~ s/(.*$script_name\/)//i;

  # Let's carry the User Agent to the server also.
  # TODO: We need to include the proxied via header here.
  my $browser = $r->header_in('User-Agent');
  $ua->agent($browser);

  # We have to append the query string since it got munged by
  # apache when this was first requested.
  my $rurl = $url;
  $rurl .= "?". $r->args if ($r->args && $url !~ /\?/);

  if ($r->method eq 'GET')
    {
    $req = new HTTP::Request 'GET' => "$rurl";
    $req->header('Referer'=>"$referer");
    $serverCookies->add_cookie_header($req);
    # This needs to be a simple request or else the redirects will 
    # not work very nicely.  LWP is too smart sometimes.
    $res = $ua->simple_request($req);
    }
  elsif ($r->method eq 'POST')
    {
    # This is a little bit of tricky ju ju here.
    # We will use another PERLy package to 
    # prepare the URL and pack in the encoded form data.
    use URI::URL;
    my %FORM;
    $req = new HTTP::Request 'POST' => "$rurl";
    $req->header('Referer'=>"$referer");
    $req->content_type('application/x-www-form-urlencoded');
    $serverCookies->add_cookie_header($req);
    # $req->content('$buffer');
    my $pair;
    my @pairs = split (/&/, $r->content);
    # TODO: This next bit more efficiently.
    # It works for the occasional cgi, but not for constant
    # hammering away at this code.  There has to be a better
    # and more OOP way.
    foreach $pair (@pairs)
      {
      my ($name, $value) = split (/=/, $pair);
      # Un-Webify plus signs and %-encoding
      $value =~ tr/+/ /;
      $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
      $FORM{$name} = $value;
      }
    # Now we build the new URL structure with the form data
    # to be sent to the server on the client's behalf.
    my $curl = url("http:");
    $curl->query_form(%FORM);
    $req->content($curl->equery);
    $res = $ua->simple_request($req);
    }

  # We need to store any cookies the server sent to us for future use.

  #Old cookie jar...

  # TODO: Make this much much better.  We still need to lock the cookie
  # jar to keep simultaneous requests from killing each others' changes.
  while (-e "$Apache::RewritingProxy::cacheRoot/cookies/$cookieKey.lock")
	{sleep(1);}
  open (LOCK, ">$Apache::RewritingProxy::cacheRoot/cookies/$cookieKey.lock");
  print LOCK " ";
  close LOCK;
  # New cookies sent by the server...
  my $responseCookies = HTTP::Cookies->new;
  $responseCookies->extract_cookies($res);
  $responseCookies->scan(\&storeCookies);
  # Store the old plus the new...
  # $proxiedCookieJar->save();
  unlink ("$Apache::RewritingProxy::cacheRoot/cookies/$cookieKey.lock");


  sub storeCookies
    {
    my $version = shift;
    my $key = shift;
    my $val = shift;
    my $path = shift;
    my $domain = shift;
    my $port = shift;
    my $path_spec = shift;
    my $secure = shift;
    my $expires = shift;
    my $discard = shift;
    my $hash = shift;
     

    # if (!$expires )
      # {
      # $expires = ht_time(time+3600, '%Y-%m-%d %H:%M:%S',0);
      # }
    my $proxiedCookieJar = HTTP::Cookies->new(
	File => "$jar",
	ignore_discard=>1,
	AutoSave=>1);
    $proxiedCookieJar->load();
    $proxiedCookieJar->set_cookie($version,$key,$val,$path,
	$domain,$port,$path_spec,$secure,$expires);
    $proxiedCookieJar->save();
    }
    
  if ($res->code =~ /^3/)
    {
    # This means it was a server redirect.
    # We should process the headers and insert 
    # ourselves into the headers everywhere we need to.
    my $textHeaders = $res->headers_as_string;


    # We need the address of the current script.
    my ($tmpUri,$junk) = split (/\/http/i, $r->uri);
    my $script_home = $r->get_server_name .":".
	$r->server->port . $tmpUri;

    # Replace any redirect links with a link pointing through us.
    if ($textHeaders =~ /Location: http:/i)
      {
      $textHeaders =~ s#http:#http://$script_home/http:#i;
      }
    else
      {
      $textHeaders =~ s#Location: (.*)
#Location: http://$script_home/$url$1#i;
      }
    # Dump out the headers as though we had created them.
    # Nothing like a little bit of http-plagiarism.
    $r->send_cgi_header($textHeaders); 
    }


  # We only process html documents.  Maybe someday we will
  # work on other types, but there is no need right now since 
  # this program only wants to look at web pages anyhow.
  if ($res->content_type =~ /html/i)
    {
    my $content = $res->content;                 # The actual text
    my $outString = "";				 # The content the user sees
    my $baseHref = "";				 # storage space for <base
    my $p = HTML::TokeParser->new(\$content)
	|| $r->log_error("No Content: $!"); 
		# TODO: This needs to be changed from warn!
    while (my $tolkens = $p->get_token )
      {
      my $text = "";
      # We process all of the possible token types.  
      # text and comments are printed unmolested to the browser.
      # Javascript would have to be parsed out by editing the text
      # between script tags.
      if ($tolkens->[0] eq 'T')
	{
  	if ($textHandlerSub)
	  {
          $outString .= &{$textHandlerSub}($r,$tolkens->[1]);
	  }
	else
	  {
          $outString .= mainTextHandler($r,$tolkens->[1]);
	  }
      	# $outString .= $tolkens->[1];
	}
      elsif ($tolkens->[0] eq 'C')
	{
	# HTML COmments. Wrap them back in their comment tags and
	# send em on to the browser...
	$outString .= "<!-- ".$tolkens->[1]." -->";
	}
      elsif ($tolkens->[0] eq 'S' && ($tolkens->[1] eq 'a' ||
	$tolkens->[1] eq 'A'))
	{
        $text = $tolkens->[4];
        if ($tolkens->[2]{href})
          {
          my $newLink = &fixLink($r,$tolkens->[2]{href},$url);
	  $tolkens->[2]{href} = regexEscape($tolkens->[2]{href});
          $text =~ s($tolkens->[2]{href})($newLink)gsx;
          }
        $outString .= $text;
	}
      elsif ($tolkens->[0] eq 'E')
	{
	$outString .= "</" . $tolkens->[1] . ">";
	}
      elsif ($tolkens->[1] =~ /^base$/i && $tolkens->[0] eq 'S')
  	{
	$text = $tolkens->[4];
        if ($tolkens->[2]{href})
	  {
	  my $newLink = &fixLink($r,$tolkens->[2]{href},$url);
	  $text =~ s#$tolkens->[2]{href}#$newLink#;

          $url = $tolkens->[2]{href};
	  }
	$outString .= $text;
	}
      elsif ($tolkens->[1] =~ /^meta$/i)
  	{
	$text = $tolkens->[4];
        if ($tolkens->[2]{content} =~ /url/i)
	  {
	  my ($junk,$tmpLink) = split (/=/, $tolkens->[2]{content});
	  my $newLink = &fixLink($r,$tmpLink,$url);
	  $tmpLink = regexEscape($tmpLink);
	  $text =~ s#$tmpLink#$newLink#;
	  }
	$outString .= $text;
	}
      elsif ($tolkens->[1] =~ /^(area|link)$/i && $tolkens->[0] eq 'S')
  	{
	$text = $tolkens->[4];
        if ($tolkens->[2]{href})
	  {
	  my $newLink = &fixLink($r,$tolkens->[2]{href},$url);
	  $text =~ s#$tolkens->[2]{href}#$newLink#;
	  }
	$outString .= $text;
	}
      elsif ($tolkens->[1] =~ /^(frame|img|input)$/i 
		&& $tolkens->[0] eq 'S')
  	{
	$text = $tolkens->[4];
        if ($tolkens->[2]{src} && $tolkens->[0] eq 'S')
	  {
	  my $newLink = &fixLink($r,$tolkens->[2]{src},$url);
	  $tolkens->[2]{src} = regexEscape($tolkens->[2]{src});
	  $text =~ s#$tolkens->[2]{src}#$newLink#;
	  }
	$outString .= $text;
	}
      elsif ($tolkens->[1] =~ /^form$/i && $tolkens->[0] eq 'S')
  	{
	$text = $tolkens->[4];
        if ($tolkens->[2]{action})
	  {
	  my $newLink = &fixLink($r,$tolkens->[2]{action},$url);
          my $action = regexEscape($tolkens->[2]{action});
	  $text =~ s#$action#$newLink#;
	  }
	$outString .= $text;
	}
      elsif ($tolkens->[1] =~ /^(td|body)$/i && $tolkens->[0] eq 'S')
  	{
	$text = $tolkens->[4];
        if ($tolkens->[2]{background})
	  {
	  my $newLink = &fixLink($r,$tolkens->[2]{background},$url);
	  $text =~ s#$tolkens->[2]{background}#$newLink#;
	  }
	$outString .= $text;
	}
      elsif ($tolkens->[1] =~ /^script$/i 
		&& $tolkens->[0] eq 'S')
  	{
	$text = $tolkens->[4];
        if ($tolkens->[2]{src} && $tolkens->[0] eq 'S')
	  {
	  my $newLink = &fixLink($r,$tolkens->[2]{src},$url);
	  $tolkens->[2]{src} = regexEscape($tolkens->[2]{src});
	  $text =~ s#$tolkens->[2]{src}#$newLink#;
	  }
	$outString .= $text;
	}
      else
	{
	  $outString .= $tolkens->[4];
	}
      }

    $r->content_type($res->content_type);
    print "\n" . $outString;
    return(OK);
    }
  else
    {
    $r->content_type($res->content_type);
    $r->header_out('Content-length'=> length($res->content));
    print "\n" .$res->content;
    return(OK);
    }
  undef $ua;
  return (SERVER_ERROR);
  }

###############################
# sub fixLink
#
# Parameters:

# $r - an Apache request object.
# $url - a reference to another resource.
#     It can be a URL or a relative reference.
#     fixLink will do the right thing with it.
# $baseLink - the link pointing to the current resource.

# Returns:
# a fixed URL using this module again.
#################################
sub fixLink
  {
  my $r = shift;
  my $link = shift;
  my $baseLink = shift;
  my $server_name = $r->get_server_name;
  my $script_name = $r->uri;
  my $i;
  my $urlPath = "";
  my $hostName = "";
  
  my ($protocol, $junk, $hostname, @dirs);
  ($protocol, $hostname) = split (/\/\//, $baseLink);
  ($hostname, @dirs) = split (/\//, $hostname);
  if ($dirs[1] =~ /\w/)
    {
    $urlPath = join ("/", @dirs);
    }
  else
    {
    $urlPath = $dirs[0] unless ($baseLink =~ /\w$/);
    }
  if ($baseLink =~ /\w$/ && $dirs[1] =~ /\w/)
    {
    for ($i = length($urlPath); $i > 0; $i--)
      {
      last if (substr($urlPath, $i, 1) eq "/");
      }
    $urlPath = substr ($urlPath, 0, $i) if ($i && $urlPath =~ /\//);
   
    }

   # $hostname = "$protocol//$hostname";

   # Fix By Tim DiLauro <timmo@pembroke.mse.jhu.edu> to repair something
   # really silly that I had done...
   # set name that will prefix all URLs.  Add trailing slash if not
   # included in location
   $script_name = $r->location();
   ($script_name,$junk) = split (/http:/, $script_name);
   $script_name .= '/'  if $script_name !~ m#/$#o;


   if ($r->server->port != 80)
     {
     $server_name .= ":".$r->server->port;
     }

  $hostname = "$protocol//$hostname";
  if ($r->server->port != 80)
    {
    $server_name .= ":".$r->server->port;
    }
  if ($link =~ /^http:/i)
    {
    return "http://". $server_name. $script_name . $link;
    }
  elsif ($link =~ /^mailto:/i)
    {
    return $link;
    }
  elsif ($link =~ /^\//)
    {
    return "http://". $server_name. $script_name . $hostname . $link;
    }
  elsif ($link =~ /^\w/)
    {
    if ($urlPath)
      {
      return "http://". $server_name.$script_name.$hostname.
	"/".$urlPath. "/".$link;
      }
    else
      {
      return "http://". $server_name.$script_name.$hostname.
	"/".$link;
      }
    }
  elsif ($link =~ /^\.\./)
    {
    # FOR THE LOVE OF GOD!!! WHY MUST THEY DO THIS!?!?!
        return "http://". $server_name.$script_name.$hostname.
        "/".$urlPath. "/".$link;
    }
  } #end of sub fixLink

# This is the function that one would replace if one were to 
# want to change the way this program handled text.
sub mainTextHandler
  {
  my $r = shift;
  my $string = shift;
  return($string);
  }

# We just escape the necessary crap in the URL we are given so that
# it can then be compared in a regex and all will be happy
sub regexEscape
  {
  my $url = shift;
  # This silly little regex fixes (*&?+|) in the URL for me.
  # withhout this regex, any of these characters in a URL will
  # cause a server error (unless they resolve into something
  # sensible to regex, in which case the server does something
  # magical and unpredictable with the URL)
  $url =~ s/(\-|\[|\]|\(|\)|\*|\+|\?|\||\&)/\\$1/g;
  return $url;
  }


1;

__END__

=head1 NAME

Apache::RewritingProxy - proxy that works by rewriting requested documents with no client proxy config needed.

=head1 SYNOPSIS

# Configuration in httpd.conf

	<Location /foo>
	SetHandler perl-script
	PerlHandler Apache::RewritingProxy
	Options ExecCGI
	PerlSendHeader On
	</Location>

requests to /foo/http://domain.dom/ will return the resource located at
http://domain.dom with all links pointing to /foo/http://otherlink.dom

=head1 DESCRIPTION

This module allows proxying of web sites without any configuration changes
on the client's part.  The client is simply pointed to a URL using this
module and it fetches the resource and rewrites all links to continue
using this proxy.  

RewritingProxy can also now be subclassed to allow users to write different
handlers for the text. See the eg for examples of this in action.

=head1 INSTALLATION


perl Makefile.PL;
make;
make install;

=head1 REQUIREMENTS

You need the following modules installed for this module to work:

  LWP::UserAgent
  HTML::TokeParser
  URI::URL
  Of course, mod_perl and Apache would also help greatly.
  Mod_Perl needs to have lots of hooks enabled.  Preferably ALL_HOOKS
  If not, the proxy will just give lots of server errors and not really
  do that much.  In particular, the Apache::Table and Apache::Util
  seem to be necessary for the module to run properly. 


=head1 TODO/BUGS

Make cookies work better.

Eat fewer cookies in real life.

Add caching or incorporate some other caching mechanism.


=head1 SEE ALSO

mod_perl(3), Apache(3), LWP::UserAgent(3)

=head1 AUTHOR

Apache::RewritingProxy by Ken Hagan <ken.hagan@louisville.edu>

	Debugging, suggestions, and helpful comments courtesy of
	Mike Reiling <miker@softcoin.com>
	Steve Baker <steveb@web.co.nz>
	Tim DiLauro <timmo@jhu.edu>
	and a few other people foolish enough to download
	and run this thing.

=head1 COPYRIGHT

The Apache::RewritingProxy module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.  

=cut
