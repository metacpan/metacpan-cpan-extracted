#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 6;
use Catalyst::Test 'TestApp';

# phaylon noticed that refactored was truncating output on large images.
# This test tests 100K and 1M output content.

my $expected = {
    one => 'x' x (100 * 1024),
    two => 'y' x (1024 * 1024),
};

for my $action ( keys %{$expected} ) {
    ok( my $response = request('http://localhost/engine/response/large/' . $action ),
        'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );

    is( length( $response->content ), length( $expected->{$action} ), 'Length OK' );
}
