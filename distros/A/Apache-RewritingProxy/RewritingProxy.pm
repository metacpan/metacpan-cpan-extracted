package Apache::RewritingProxy;

use strict;
use Apache::Constants qw(:common);
use vars '$req';
use vars '$res';
use vars qw($VERSION @ISA);

$VERSION = '1.3';

use DynaLoader ();

@ISA = qw(DynaLoader);




sub handler
  {
  my $r = shift;

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
  use LWP::UserAgent;
  use HTML::TokeParser;
  use HTTP::Cookies;
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
  if ($r->method eq 'GET')
    {
    # We have to append the query string since it got munged by
    # apache when this was first requested.
    $url .= "?". $r->args if ($r->args =~ /\=/);
    $req = new HTTP::Request 'GET' => "$url";
    
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
    $req = new HTTP::Request 'POST' => "$url";
    $req->content_type('application/x-www-form-urlencoded');
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
    $textHeaders =~ s#http:#http://$script_home/http:#i;
    # Dump out the headers as though we had created them.
    # Nothing like a little bit of http-plagiarism.
    $r->send_cgi_header($textHeaders); 
    }

  # Before we process the content, we should parse any cookies
  # the server sent us, rewrite them, and send them to the client.
  
  # TODO:COOKIE STUFF HERE

  # We only process html documents.  Maybe someday we will
  # work on other types, but there is no need right now since 
  # this program only wants to look at web pages anyhow.
  if ($res->content_type =~ /html/i)
    {
    my $content = $res->content;                 # The actual text
    my $outString = "";				 # The content the user sees
    my $baseHref = "";				 # storage space for <base
    my $p = HTML::TokeParser->new(\$content)
	|| warn "No Content: $!"; # TODO: This needs to be changed from warnr!
    while (my $tolkens = $p->get_token )
      {
      my $text = "";
      # We process all of the possible token types.  I do not know what
      # happens to java script, since it doesn't currenty show at all.
      # As soon as I find that token type, I will lump it together with 
      # text. God damned foofy client side languages.
      if ($tolkens->[0] eq 'T')
	{
      	$outString .= $tolkens->[1];
	}
      elsif ($tolkens->[0] eq 'S' && ($tolkens->[1] eq 'a' ||
	$tolkens->[1] eq 'A'))
	{
        $text = $tolkens->[4];
        if ($tolkens->[2]{href})
          {
          my $newLink = &fixLink($r,$tolkens->[2]{href},$url);
          # This silly little regex fixes &?+| in the URL for me.
	  $tolkens->[2]{href} =~ s/(\+|\?|\||\&)/\\$1/g;
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
	  $tmpLink =~ s/(\+|\?|\||\&)/\\$1/g;
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
      elsif ($tolkens->[1] =~ /^(frame|img|input)$/i && $tolkens->[0] eq 'S')
  	{
	$text = $tolkens->[4];
        if ($tolkens->[2]{src} && $tolkens->[0] eq 'S')
	  {
	  my $newLink = &fixLink($r,$tolkens->[2]{src},$url);
          # This silly little regex fixes &?+| in the URL for me.
	  $tolkens->[2]{src} =~ s/(\+|\?|\||\&)/\\$1/g;
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
	  $text =~ s#$tolkens->[2]{action}#$newLink#;
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
      else
	{
	  $outString .= $tolkens->[4];
	}
      }

    $r->content_type($res->content_type);
    print $outString;
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

  $hostname = "$protocol//$hostname";
  ($script_name,$junk) = split (/http:/, $script_name);
  $script_name = "/proxy/";
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


=head1 TODO

Make cookies work

Fix occasional query string munging for redirected requests

Add caching or incorporate some other caching mechanism

Enable this module to at least print scripts that occur within comments

Add an external script to enable this to be called as a cgi or a mod_perl module (for testing)

=head1 SEE ALSO

mod_perl(3), Apache(3), LWP::UserAgent(3)

=head1 AUTHOR

Apache::RewritingProxy by Ken Hagan <ken.hagan@louisville.edu>

=head1 COPYRIGHT

The Apache::RewritingProxy module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
