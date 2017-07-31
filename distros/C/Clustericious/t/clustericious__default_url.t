use strict;
use warnings;
use Test2::Plugin::FauxHomeDir;
use Test::More tests => 1;
use Clustericious::HelloWorld;
use Clustericious::HelloWorld::Client;

my $app    = Clustericious::HelloWorld->new;
my $client = Clustericious::HelloWorld::Client->new;

is($app->config->url, $client->config->url, "URLs match");

note "url is : @{[ $app->config->url ]}";
