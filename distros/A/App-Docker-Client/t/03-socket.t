#!perl -T
use 5.16.0;
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin qw($Bin);

plan( skip_all => "No docker socket found" )
  unless -e File::Spec->catfile( '', 'var', 'run', 'docker.sock' );

plan tests => 2;

require App::Docker::Client;
require App::Docker::Client::Exception;

my $client = new_ok( 'App::Docker::Client' => [] );

is( scalar @{ $client->get('/containers/json') } >= 0, 1, "Check list is running on socket" );
