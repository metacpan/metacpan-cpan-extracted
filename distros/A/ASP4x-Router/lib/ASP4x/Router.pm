
package ASP4x::Router;

use strict;
use warnings 'all';
use base 'ASP4::RequestFilter';
BEGIN {
  # Only conditionally inherit from ASP4::TransHandler':
  eval { require ASP4::TransHandler };
  push @ASP4x::Router::ISA, 'ASP4::TransHandler' unless $@;
}
use Router::Generic;
use ASP4::ConfigLoader;
use vars __PACKAGE__->VARS;

our $VERSION = '0.022';

our %routers = ( );


sub handler : method
{
  my ($class, $r) = @_;
  
  return -1 if $r->pnotes('__routed');
  $r->pnotes( __routed => 1 );
  
  my $res = $class->SUPER::handler( $r );
  my $Config = ASP4::ConfigLoader->load;
  
  if( my $app = eval { $Config->app } )
  {
    map {
      $Config->load_class( $_ );
      $_->import;
    } @$app;
  }# end if()
  
  my $router = $class->get_router();
  $r->pnotes( route => $router->route_for( $r->uri, $r->method ) );
  
  my $fullpath = $r->document_root . $r->uri;
  if( $fullpath =~ m{/$} && -f $fullpath . 'index.asp' )
  {
    $r->uri( $r->uri . 'index.asp' );
    return -1;
  }
  elsif( -f $fullpath )
  {
    return -1;
  }
  elsif( $r->uri =~ m{^/handlers/} )
  {
    (my $handler_path = $r->uri) =~ s{\.}{/}g;
    $handler_path = $Config->web->application_root . "$handler_path.pm";
    if( -f $handler_path )
    {
      return -1;
    }# end if()
  }# end if()
  
  return $res unless $router;
  
  my @matches = $router->match( $r->uri . ( $r->args ? '?' . $r->args : '' ), $r->method )
    or return -1;
  
  # TODO: Check matches to see if maybe they point to another route not on disk:
  my ($new_uri) = grep {
    my ($path) = split /\?/, $_;
    if( m{^/handlers/} )
    {
      $path =~ s/\./\//g;
      $path .= ".pm";
      if( -f $Config->web->application_root . $path )
      {
        1;
      }# end if()
    }
    else
    {
      -f ($r->document_root . $path);
    }# end if()
  } @matches
    or return -1;
  
  # Require a trailing '/' on the end of the URI:
  unless( $r->uri =~ m{\.[^/]+$} || $r->uri =~ m{/$} )
  {
    my $loc = $r->uri . '/';
    if( $r->args )
    {
      $loc .= "?" . $r->args;
    }# end if()
    $r->status( 301 );
    $r->err_headers_out->add( Location => $loc );
    return 301;
  }# end unless()

  my ($uri, $args) = split /\?/, $new_uri;
  my @args = split /&/, $args if defined($args) && length($args);
  $r->args( join '&', @args );
  $ENV{QUERY_STRING} = $r->args;
  $r->uri( $uri );
  
  return -1;
}# end handler()


sub run
{
  my ($s, $context) = @_;
  
  if( my $route = $context->r->pnotes('route') )
  {
    $Stash->{route} = $route;
  }# end if()
  return $Response->Declined if $context->r->pnotes('__routed');
  
  if( my $app = eval { $Config->app } )
  {
    map {
      $Config->load_class( $_ ); 
      $_->import
    } @$app;
  }# end if()
  
  my $router = $s->get_router()
    or return $Response->Declined;
  
  my ($uri) = split /\?/, $ENV{REQUEST_URI};
  my $route = $router->route_for( $uri, $ENV{REQUEST_METHOD} );
  $Stash->{route} = $route;
  
  my $r = $context->r;
  my $path = $r->document_root . $r->uri;
  if( $path =~ m{/$} && -f $path . 'index.asp' )
  {
    return $Response->Declined;
  }
  elsif( -f $path )
  {
    return $Response->Declined;
  }
  elsif( $r->uri =~ m{^/handlers/} )
  {
    # Check to see if there is a handler on-disk that matches the uri:
    (my $handler_path = $r->uri) =~ s{\.}{/}g;
    $handler_path = $Config->web->application_root . "$handler_path.pm";
    if( -f $handler_path )
    {
      return $Response->Declined;
    }# end if()
  }# end if()

  # Try routing:
  if( my @matches = $router->match( $ENV{REQUEST_URI}, $ENV{REQUEST_METHOD} ) )
  {
    # TODO: Check matches to see if maybe they point to another route not on disk:
    my ($new_uri) = grep {
      my ($path) = split /\?/, $_;
      if( $path =~ m{^/handlers/} )
      {
        $path =~ s/\./\//g;
        $path .= ".pm";
        -f $Config->web->application_root . $path;
      }
      else
      {
        -f $Server->MapPath($path);
      }# end if()
    } @matches or return $Response->Declined;
    
    $Stash->{route} = $router->route_for( $ENV{REQUEST_URI}, $ENV{REQUEST_METHOD} );
    $Request->Reroute( $new_uri );
  }
  else
  {
    return $Response->Declined;
  }# end if()
}# end run()


sub get_router
{
  ASP4::ConfigLoader->load()->web->router;
}# end get_router()


1;# return true:

=pod

=head1 NAME

ASP4x::Router - URL Routing for your ASP4 web application.

=head1 DEPRECATED

L<ASP4> has been deprecated and by extension this module as well.

=head1 SYNOPSIS

% httpd.conf

  PerlModule ASP4x::Router
  
  ...
  
  <VirtualHost *:80>
  ...
    PerlTransHandler ASP4x::Router
  ...
  </VirtualHost>

% asp4-config.json

  ...
  "web": {
    ...
    "request_filters": [
      ...
      {
        "uri_match": "/.*",
        "class":     "ASP4x::Router"
      }
      ...
    ]
    ...
    "routes": [
      {
        "include_routes":   "@ServerRoot@/conf/routes.json"
      },
      {
        "name":   "CreatePage",
        "path":   "/main/:type/create",
        "target": "/pages/create.asp",
        "method": "GET"
      },
      {
        "name":   "Create",
        "path":   "/main/:type/create",
        "target": "/handlers/dev.create",
        "method": "POST"
      },
      {
        "name":   "View",
        "path":   "/main/:type/{id:\\d+}",
        "target": "/pages/view.asp",
        "method": "*"
      },
      {
        "name":   "EditPage",
        "path":   "/main/:type/{id:\\d+}/edit",
        "target": "/pages/edit.asp",
        "method": "GET"
      },
      {
        "name":   "Edit",
        "path":   "/main/:type/{id:\\d+}/edit",
        "target": "/handlers/dev.edit",
        "method": "POST"
      },
      {
        "name":     "List",
        "path":     "/main/:type/list/{page:\\d*}",
        "target":   "/pages/list.asp",
        "method":   "*",
        "defaults": { "page": 1 }
      },
      {
        "name":   "Delete",
        "path":   "/main/:type/{id:\\d+}/delete",
        "target": "/handlers/dev.delete",
        "method": "POST"
      }
    ]
    ...
  }
  ...

% In your ASP scripts and Handlers:

  <%
    # Get the router:
    my $router = $Config->web->router;
    
    # Get the uri:
    my $uri = $router->uri_for('EditPage', { type => 'truck', id => 123 });
  %>
  <a href="<%= $Server->HTMLEncode( $uri ) %>">Edit this Truck</a>

Comes out like this:

  <a href="/main/truck/123/edit/">Edit this Truck</a>

=head1 DESCRIPTION

For a gentle introduction to URL Routing in general, see L<Router::Generic>, since
C<ASP4x::Router> uses L<Router::Generic> to handle all the routing logic.

Long story short - URL Routing can help decouple the information architecture from
the actual layout of files on disk.

=head2 How does it work?

C<ASP4x::Router> uses L<Router::Generic> for the heavy lifting.  It functions as
both a mod_perl C<PerlTransHandler> and as a L<ASP4::RequestFilter>, providing the
same exact routing behavior for both L<ASP4::API> calls and for normal HTTP requests
handled by the mod_perl interface of your web server.

When a request comes in to Apache, mod_perl will know that C<ASP4x::Router> might
make a change to the URI - so it has C<ASP4x::Router> take a look at the request.  If
any changes are made (eg - C</foo/bar/1/> gets changed to C</pages/baz.asp?id=1>)
then the server handles the request just as though C</pages/baz.asp?id=1> had been
requested in the first place.

For testing - if you run this:

  $api->ua->get('/foo/bar/1/');

C<ASP4x::Router> will "reroute" that request to C</pages/baz.asp?id=1> as though you
had done it yourself like this:

  $api->ua->get('/pages/baz.asp?id=1');

=head2 What is the point?

Aside from the "All the cool kids are doing it" argument - you get super SEO features
and mad street cred - all in one shot.

Now, instead of 1998-esque urls like C</page.asp?category=2&product=789&revPage=2> you get
C</shop/marbles/big-ones/reviews/page/4/>

=head2 What about performance?

Unless you have literally B<*thousands*> of different entries in the "C<routing>"
section of your C<conf/asp4-config.json> file, performance should be B<quite> fast.

=head2 Where can I learn more?

Please see the documentation for L<Router::Generic> to learn all about how to 
specify routes.

=head1 PREREQUISITES

L<ASP4>, L<Router::Generic>

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the same terms as any version of Perl itself.

=cut

