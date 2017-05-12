# mod_perl startup file
#
# Add module to preload here
use Apache;
use Apache::Cookie;
use Apache::Request;

use Apache::DBI;
use HTML::Embperl;

use lib "/home/francis/copiscan/lib";

# Preload all the iNcom modules
use iNcom;
use iNcom::Session;
use iNcom::PgStore;

# Other stuff
# Reinstall remote address if the request was proxied
sub My::ProxyRemoteAddr ($) {
  my $r = shift;

  # we'll only look at the X-Forwarded-For header if the requests
  # comes from our proxy at localhost
  return OK unless ($r->connection->remote_ip eq "127.0.0.1");

  if (my ($ip) = $r->header_in('X-Forwarded-For') =~ /([^,\s]+)$/) {
    $r->connection->remote_ip($ip);
  }
  return OK;
}

1;
