use Test::More tests => 1;
use strict;
use warnings;

# the order is important
use Dancer::SearchApp;
use Dancer::Test;

route_exists [GET => '/'], 'a route handler is defined for /';

# This doesn't find the view in views/ . I don't care why.
#response_status_is ['GET' => '/'], 200, 'response status is 200 for /'
#    or diag Dumper read_logs();