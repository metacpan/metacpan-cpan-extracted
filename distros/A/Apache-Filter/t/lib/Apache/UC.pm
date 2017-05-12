package Apache::UC;

# This is just a proof-of-concept, an example of a module
# that uses the Apache::Filter features.

use strict;
use Apache::Constants qw(:common);

sub handler {
  my $r = shift->filter_register;
  $r->deterministic(1);
  
  #$r->content_type("text/html");
  $r->send_http_header;
  my ($fh, $status) = $r->filter_input();
  return $status unless $status == OK;

  print uc while <$fh>;
  return OK;
}
1;

