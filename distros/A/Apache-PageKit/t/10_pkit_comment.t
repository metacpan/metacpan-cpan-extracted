use strict;
use warnings FATAL => 'all';
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';
plan tests => 3;

# simple load test
ok 1;

# check if we can request a page
my $url = '/charset_tmpl';

# preform the test twice, the first time to fill the cache and a
# second time to use the results.
for ( 1 .. 2 ) {
  my $data = GET_BODY $url, 'Accept-Charset', 'iso-8859-1';
  ok ( $data !~ /pkit_comment/i );
}
