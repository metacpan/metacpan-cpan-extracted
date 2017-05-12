package Apache::ChangeHeader;

use strict;
use Apache::Constants qw(:common);

sub handler {
  my $r = shift->filter_register;
  
  $r->content_type("text/html");
  my ($fh, $status) = $r->filter_input();

  return $status unless $status == OK;

  $r->header_out('X-Test', 'success');
  $r->send_http_header;
  
  print "Blah blah\n";
  return OK;
}
1;

