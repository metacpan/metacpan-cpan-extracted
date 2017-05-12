package Apache::CacheTest;

# This tests the 'deterministic' method

use strict;
use Apache::Constants qw(:common);


sub handler {
  my $r = shift->filter_register;
  
  $r->content_type("text/html");
  my ($fh, $status) = $r->filter_input();
  return $status unless $status == OK;
  
  if ($r->changed_since(time)) {
    print "Changed since right now\n";
  } else {
    print "Hasn't changed since right now\n";
  }
  
  return OK;
}
1;

