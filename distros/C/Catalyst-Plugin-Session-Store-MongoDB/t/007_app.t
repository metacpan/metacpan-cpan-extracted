use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/TestApp/lib";

use Test::More;

BEGIN {
  my @needs = qw/MONGODB_HOST MONGODB_PORT TEST_DB TEST_COLLECTION/;

  map {
    plan skip_all => 'Must set ' . join(",", @needs) . ' environment variables'
      unless(defined($ENV{$_}));
  } @needs;
}

BEGIN { use_ok 'Catalyst::Test', 'TestApp' }

my ($res, $c) = ctx_request('/');

ok $res->is_success, 'Request root';

isa_ok $c, 'Catalyst::Plugin::Session::Store::MongoDB', 'Context object';

my $connection;
eval { $connection = $c->_connection };

ok $connection, 'connection';
is $connection->host, $ENV{MONGODB_HOST}, 'connection host';
is $connection->port, $ENV{MONGODB_PORT}, 'connection port';

done_testing();

