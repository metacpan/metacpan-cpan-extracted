use Test::More;
use strict;
use warnings;

# the order is important
use App::Beeminder::Hook;
use Dancer::Test;

route_exists [GET => '/hook'], 'a route handler is defined for /';
response_status_is ['GET' => '/hook'], 200, 'response status is 200 for GET /';
response_status_is ['POST' => '/hook'], 200, 'response status is 200 for POST /';

done_testing;
