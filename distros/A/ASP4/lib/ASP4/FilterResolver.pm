
package
ASP4::FilterResolver;

use strict;
use warnings 'all';
my %FilterCache = ( );


sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}# end new()


sub context { ASP4::HTTPContext->current }


sub resolve_request_filters
{
  my ($s, $uri) = @_;
  
  ($uri) = split /\?/, $uri;
  my $key = "$ENV{DOCUMENT_ROOT}:$uri";
  return @{$FilterCache{$key}} if $FilterCache{$key};
  $FilterCache{$key} = [
    grep {
      if( my $pattern = $_->uri_match )
      {
        $uri =~ m{^$pattern}
      }
      else
      {
        $uri eq $_->uri_equals;
      }# end if()
    } $s->context->config->web->request_filters
  ];
  return @{$FilterCache{$key}};
}# end resolve_request_filters()

1;# return true:

