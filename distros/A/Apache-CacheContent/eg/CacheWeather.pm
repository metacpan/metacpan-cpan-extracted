#
# Sample subclass of Apache::CacheContent

package CacheWeather;

use Apache::Constants qw(OK NOT_FOUND);
use Apache::CacheContent;

use strict;

@CacheWeather::ISA = qw(Apache::CacheContent);

sub ttl {
  my($self, $r) = @_;

  my $uri = $r->uri;

  return(60)      if ($uri=~ /hourly\.html$/);
  return(60 * 24) if ($uri=~ /daily\.html$/);
  return $self->SUPER::ttl($r);
}

sub handler ($$) {

  my ($self,$r) = @_;

  # Find arguments via the URL...
  my ($city, $period) = $r->uri =~ m!/(.*?)_(hourly|daily)\.html$!;

  return NOT_FOUND unless ($city and $period);

  my $time = localtime;

  $r->send_http_header('text/html');
  print<<EOF;
    <html>
      <body>
        <h1>Weather for $city - $period Update</h1>
        It is sunny and 85 at $time.
      </body>
    </html>
EOF

  return OK;
}
1;
