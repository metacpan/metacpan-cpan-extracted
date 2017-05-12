
package Apache2::ASP::ConfigNode::Web;

use strict;
use warnings 'all';
use base 'Apache2::ASP::ConfigNode';


#==============================================================================
sub new
{
  my $class = shift;
  
  my $s = $class->SUPER::new( @_ );
  $s->{handler_resolver}  ||= 'Apache2::ASP::HTTPContext::HandlerResolver';
  $s->{handler_runner}    ||= 'Apache2::ASP::HTTPContext::HandlerRunner';
  $s->{filter_resolver}   ||= 'Apache2::ASP::HTTPContext::FilterResolver';
  
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
  return $s;
}# end new()


#==============================================================================
sub request_filters
{
  my $s = shift;
  
  @{ $s->{request_filters}->{filter} };
}# end request_filters()


#==============================================================================
sub disable_persistence
{
  my $s = shift;
  
  @{ $s->{disable_persistence}->{location} };
}# end disable_persistence()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::ConfigNode::Web - The $Config->web object.

=head1 SYNOPSIS

Given the following configuration...

  <?xml version="1.0"?>
  <config>
    ...
    <web>
      <application_name>MyApp</application_name>
      <application_root>@ServerRoot@</application_root>
      <handler_root>@ServerRoot@/handlers</handler_root>
      <media_manager_upload_root>@ServerRoot@/MEDIA</media_manager_upload_root>
      <www_root>@ServerRoot@/htdocs</www_root>
      <page_cache_root>/tmp/PAGE_CACHE</page_cache_root>
      <request_filters>
        <filter>
          <uri_match>/members/.*</uri_match>
          <class>My::MemberFilter</class>
        </filter>
        <filter>
          <uri_match>/checkout/.*</uri_match>
          <class>My::HasOrderFilter</class>
        </filter>
      </request_filters>
    </web>
    ...
  </config>

You would access it like this:

  $Config->web->application_name;           # 'MyApp'
  $Config->web->application_root;           # '/usr/local/projects/mysite.com'
  $Config->web->handler_root;               # '/usr/local/projects/mysite.com/handlers'
  $Config->web->media_manager_upload_root;  # '/usr/local/projects/mysite.com/MEDIA'
  $Config->web->www_root;                   # '/usr/local/projects/mysite.com/htdocs'
  $Config->web->page_cache_root;            # '/tmp/PAGE_CACHE'
  
  You will never need to do this:
  foreach my $filter ( $Config->web->request_filters )
  {
    my $regexp  = $filter->uri_match;
    my $class   = $filter->class;
  }# end foreach()

=head1 DESCRIPTION

Apache2::ASP::ConfigNode::Web provides access to the C<web> portion of the configuration.

=head1 PUBLIC PROPERTIES

=head2 application_name

Returns the name of the application.

=head2 application_root

Returns the absolute path to the root of the application, i.e. C</usr/local/projects/mysite.com>

=head2 handler_root

Returns the absolute path to where the 'handlers' are installed, i.e. C</usr/local/projects/mysite.com/handlers>

=head2 media_manager_upload_root

Returns the absolute path to where uploaded files will be stored, i.e. C</usr/local/projects/mysite.com/MEDIA>

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

=head1 SEE ALSO

L<Apache2::ASP::RequestFilter>

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

