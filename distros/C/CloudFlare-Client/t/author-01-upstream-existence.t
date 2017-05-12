#!perl -T

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict; use warnings; no indirect 'fatal'; use namespace::autoclean;

use Readonly;
use Test::More;
use Test::Exception;
use Test::RequiresInternet;

use CloudFlare::Client;

plan tests => 1;

# Check we can hit the service and it fails our call
throws_ok { Readonly my $api => CloudFlare::Client::->new( user   => 'user',
                                                           apikey => 'KEY');
          # Picked because takes no args
          $api->zoneLoadMulti } 'CloudFlare::Client::Exception::Upstream',
          'Upstream service exists and responds'
