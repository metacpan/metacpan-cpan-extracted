package MyDancer2App;
use strictures 1;

BEGIN {
  our $VERSION = '0.001';  # fixed version - NOT handled via DZP::OurPkgVersion.
}

use Dancer2;

BEGIN {
  set content_type => 'text/plain';
  set plugins      => {
    Redis => {
      server   => 'localhost:6379',
      #password => 'Enter your optional Redis password here',
    },
  };
}

use Dancer2::Plugin::Redis;

get '/' => sub {
  my $counter = redis_get('counter');  # Get the counter value from Redis.
  redis_set( counter => ++$counter );  # Increase counter value by 1 and save it back to Redis.
  redis_expire( counter => 10 );       # counter expires after 10 seconds.
  return $counter;
};

dance;
