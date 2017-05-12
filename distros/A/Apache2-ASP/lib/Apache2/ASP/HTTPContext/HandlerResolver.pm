
package Apache2::ASP::HTTPContext::HandlerResolver;

use strict;
use warnings 'all';
my %HandlerCache = ( );


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}# end new()


#==============================================================================
sub context { Apache2::ASP::HTTPContext->current }


#==============================================================================
sub resolve_request_handler
{
  my ($s, $uri) = @_;
  
  ($uri) = split /\?/, $uri;
  return $HandlerCache{$uri} if $HandlerCache{$uri};
  if( $uri =~ m/^\/handlers\// )
  {
    (my $handler = $uri) =~ s/^\/handlers\///;
    $handler =~ s/[^a-z0-9_]/::/gi;
    (my $path = "$handler.pm") =~ s/::/\//g;
    my $filepath = $s->context->config->web->handler_root . "/$path";
    if( -f $filepath )
    {
      $s->context->_load_class( $handler );
      return $HandlerCache{$uri} = $handler;
    }
    else
    {
      return;
    }# end if()
  }
  else
  {
    my $handler = 'Apache2::ASP::ASPHandler';
    $s->context->_load_class( $handler );
    return $HandlerCache{$uri} = $handler;
  }# end if()
}# end resolve_request_handler()

1;# return true:

