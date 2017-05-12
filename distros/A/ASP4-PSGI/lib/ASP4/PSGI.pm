
package ASP4::PSGI;

use strict;
use warnings 'all';
use ASP4::SimpleCGI;
use Plack::Request;

our $VERSION = '0.004';


sub app
{
  return sub {
    my $env = shift;
    my $preq = Plack::Request->new( $env );

    local %ENV = %$env;
    require ASP4::API;
    my $api = ASP4::API->new();
    
    # Parse cookies:
    foreach my $cookie ( split /;\s*/, ($ENV{HTTP_COOKIE}||'') )
    {
      my ($k,$v) = map { ASP4::SimpleCGI->unescape($_) } split /\=/, $cookie;
      $api->ua->add_cookie( $k => $v );
    }# end foreach()
    
    # Execute the request:
    my $method = lc( $ENV{REQUEST_METHOD} );
    my $res = do {
      # Is it a GET, POST or Upload?
      if( $method eq 'get' )
      {
        # GET
        $api->ua->get( $env->{REQUEST_URI} );
      }
      else
      {
        if( $ENV{CONTENT_TYPE} =~ m{^multipart/form\-data;} )
        {
          # Upload:
          my @pairs = $preq->parameters->flatten;
          # Prepare the upload:
          foreach my $up ( keys %{ $preq->uploads } )
          {
            my $upload = $preq->uploads->{$up};
            push @pairs, $up => [
              $upload->{tempname}, $upload->{filename},
              'content-type' => $upload->{'content-type'}
            ];
          }# end foreach()
          
          # Now we can upload:
          $api->ua->upload( $env->{REQUEST_URI}, \@pairs );
        }
        else
        {
          # POST:
          $api->ua->post( $env->{REQUEST_URI}, [ $preq->parameters->flatten ] );
        }# end if()
      }# end if()
    };
    
    # Check for a 404 response.  If we got one, then see if we've got a /404.asp:
    my ($status) = $res->status_line =~ m{^(\d+)};
    if( $status eq 404 && -f $api->config->web->www_root . '/404.asp' )
    {
      # Try to do the right thing:
      $res = $api->ua->get( '/404.asp' );
    }# end if()
    
    # Return a PSGI-compliant response:
    return [
      $status,
      [
        %{ $res->headers }
      ],
      [
        $res->content
      ]
    ];
  };
}# end app()

1;# return true:

=pod

=head1 NAME

ASP4::PSGI - Run your ASP4 web application under PSGI/Plack.

=head1 SYNOPSIS

In your C<app.psgi> file:

  use ASP4::PSGI;
  
  ASP4::PSGI->app;

That's it!

=head1 DESCRIPTION

L<ASP4> is a great way to build web applications.  L<PSGI>/L<Plack> is a great way
to abstract a web application from the environment in which it is run.

While I wouldn't B<yet> run a high-traffic ASP4 web application in this way, it works
very well for smaller tools and apps.

=head1 SEE ALSO

L<Plack>, L<PSGI>, L<http://plackperl.org/>

=head1 SPECIAL THANKS TO

* Tatsuhiko Miyagawa - The man behind Plack and PSGI.

* Everyone else who has worked on the Plack and PSGI projects.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4-PSGI> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

This software is Free software and may be used and redistributed under the same
terms as perl itself.

=cut


