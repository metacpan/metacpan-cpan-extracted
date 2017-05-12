
package ASP4::ConfigNode::Web;

use strict;
use warnings 'all';
use base 'ASP4::ConfigNode';
use Carp 'confess';
use JSON::XS;


sub new
{
  my $class = shift;
  
  my $s = $class->SUPER::new( @_ );
  $s->{handler_resolver}  ||= 'ASP4::HTTPContext::HandlerResolver';
  $s->{handler_runner}    ||= 'ASP4::HTTPContext::HandlerRunner';
  $s->{filter_resolver}   ||= 'ASP4::HTTPContext::FilterResolver';
  
  map {
    $_->{uri_match} = undef unless defined($_->{uri_match});
    $_->{uri_equals} = undef unless defined($_->{uri_equals});
    $_ = $class->SUPER::new( $_ );
  } $s->request_filters;
  map {
    $_->{uri_match} = undef unless defined($_->{uri_match});
    $_->{uri_equals} = undef unless defined($_->{uri_equals});
    $_->{disable_session} ||= 0;
    $_->{disable_application} ||= 0;
    $_ = $class->SUPER::new( $_ );
  } $s->disable_persistence;
  
  # Do we have "routes"?:
  eval { require Router::Generic };
  $s->{__has_router} = ! $@;
  
  return $s;
}# end new()


sub request_filters
{
  my $s = shift;
  
  @{ $s->{request_filters} };
}# end request_filters()


sub disable_persistence
{
  my $s = shift;
  
  @{ $s->{disable_persistence} };
}# end disable_persistence()


sub router
{
  my $s = shift;
  $s->_parse_routes() unless $s->{__parsed_routes}++;
  $s->{router};
}

sub routes
{
  my $s = shift;
  return unless $s->{__has_router};
  $s->_parse_routes() unless $s->{__parsed_routes}++;
  $s->{routes};
}# end routes()


sub _parse_routes
{
  my $s = shift;
  
  my @original = @{ $s->{routes} };
  my $app_root = $s->application_root;
  @{ $s->{routes} } = map {
    $_->{include_routes} ? do {
      my $item = $_;
      $item->{include_routes} =~ s/\@ServerRoot\@/$app_root/sg;
      $item->{include_routes} =~ s{\\\\}{\\}g;
      open my $ifh, '<', $item->{include_routes}
        or die "Cannot open '$item->{include_routes}' for reading: $!";
      local $/;
      my $json = eval { decode_json( scalar(<$ifh>) ) }
        or confess "Error parsing '$item->{include_routes}': $@";
      ref($json) eq 'ARRAY'
        or confess "File '$item->{include_routes}' should be an arrayref but it's a '@{[ ref($json) ]}' instead.";
      @$json;
    } : $_
  } @original;
  
  my $router = Router::Generic->new();
  map { $router->add_route( %$_ ) } @{ $s->{routes} };
  $s->{router} = $router;
}# end _parse_routes()

1;# return true:

=pod

=head1 NAME

ASP4::ConfigNode::Web - The $Config->web object.

=head1 SYNOPSIS

Given the following configuration...

  {
    ...
    web: {
      application_name: "DefaultApp",
      application_root: "@ServerRoot@",
      www_root:         "@ServerRoot@/htdocs",
      handler_root:     "@ServerRoot@/handlers",
      page_cache_root:  "/tmp/PAGE_CACHE",
      handler_resolver: "ASP4::HandlerResolver",
      handler_runner:   "ASP4::HandlerRunner",
      filter_resolver:  "ASP4::FilterResolver",
      request_filters: [
        {
          uri_match:    "^/.*",
          filter_class: "My::Filter"
        }
      ],
      disable_persistence: [
        {
          uri_match:            "^/nostate/.*",
          disable_session:      true,
          disable_application:  false
        }
      ]
    }
    ...
  }

You would access it like this:

  $Config->web->application_name;           # 'MyApp'
  $Config->web->application_root;           # '/usr/local/projects/mysite.com'
  $Config->web->handler_root;               # '/usr/local/projects/mysite.com/handlers'
  $Config->web->www_root;                   # '/usr/local/projects/mysite.com/htdocs'
  $Config->web->page_cache_root;            # '/tmp/PAGE_CACHE'
  
  You will never need to do this:
  foreach my $filter ( $Config->web->request_filters )
  {
    my $regexp  = $filter->uri_match;
    my $class   = $filter->class;
  }# end foreach()

=head1 DESCRIPTION

ASP4::ConfigNode::Web provides access to the C<web> portion of the configuration.

=head1 PUBLIC PROPERTIES

=head2 application_name

Returns the name of the application.

=head2 application_root

Returns the absolute path to the root of the application, i.e. C</usr/local/projects/mysite.com>

=head2 handler_root

Returns the absolute path to where the 'handlers' are installed, i.e. C</usr/local/projects/mysite.com/handlers>

=head2 www_root

Returns the absolute path to where the normal website files (ASP, images, css, javascripts, etc) are located, 
i.e. C</usr/local/projects/mysite.com/htdocs>

=head2 page_cache_root

Returns the absolute path to where 'compiled' ASP scripts are stored, i.e. C</tmp/PAGE_CACHE>

Since the 'compiled' ASP scripts are overwritten whenever the source ASP script has been changed on disk,
the webserver process must have read/write access to this location.

It is recommended that a temporary path is used - '/tmp' on most Linux distributions.

=head2 request_filters

Returns a list of ConfigNodes that represent individual C<filter> elements in the configuration.

=head2 router

B<*IF*> you have defined a "routes" section in your config - like this:

  ...
  "web": {
    ...
    "routes": [
      {
        "name":   "Wiki",
        "path":   "/:lang-:locale/{*page}",
        "target": "/wiki-page.asp",
        "defaults": {
          "page":   "home",
          "lang":   "en",
          "locale": "us"
        }
      }
    ]
    ...
  }

Then the C<router> property will return a L<Router::Generic> object based on your routes.

You can access it from the C<$Config> like this:

  $Config->web->router

=head1 SEE ALSO

L<ASP4::RequestFilter>

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

