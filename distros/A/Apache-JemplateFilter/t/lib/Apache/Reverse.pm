package Apache::Reverse;

# This is just a proof-of-concept, an example of a module
# that uses the Apache::Filter features.
# It prints the lines of its input in reverse order.

use strict;
use Apache::Constants qw(:common);


sub handler {
  my $r = shift->filter_register;
  $r->deterministic(1);

  $r->content_type("text/html");
  $r->send_http_header;
  my ($fh, $status) = $r->filter_input();
warn "STATUS is $status";
  return $status unless $status == OK;

  print reverse <$fh>;
  return OK;
}
1;

