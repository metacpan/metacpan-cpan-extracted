package Apache::FHandle;

# This tests the 'handle' parameter of filter_input()

use strict;
use Apache::Constants qw(:common);

sub handler {
  my $r = shift->filter_register;
  $r->send_http_header;
  
  local *FH;
  my $file = $r->document_root . $r->path_info;
  open FH, $file;
  #my ($fh, $status) = $r->filter_input(handle=>\*FH);
  #return $status unless $status == OK;
  
  print <FH>;
  
  return OK;
}
1;

