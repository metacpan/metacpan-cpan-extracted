use strict;
use warnings;
use Test::Clustericious::Cluster 0.26;
use Test::More tests => 12;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('SomeService');

require_ok 'SomeService::Client';

my $client = SomeService::Client->new;

is($client->welcome(), 'welcome', 'Got welcome route');

my $test_obj = { a => 'b' };

is_deeply($client->foo($test_obj), $test_obj, 'Create object');

is_deeply($client->foo('a'), $test_obj, 'Retrieve object');

is($client->meta_for("welcome")->get("jambo"), "sana", "Set metadata");

is($client->meta_for("welcome")->doc, "Say hello", "Set metadata");

is($client->broken, undef, 'client.broken');
is $client->errorstring, '(404) Not Found', 'client.errormessage';

isa_ok $client->config, 'Clustericious::Config';
is_deeply scalar $client->config->{a}, {b => [1,2,3]};

isa_ok $client->ua, 'Mojo::UserAgent';

__DATA__

@@ etc/SomeService.conf
---
url: <%= cluster->url %>

a:
  b: [1,2,3]

@@ lib/SomeService.pm
package Fake::Object::Thing;

my $persist;  # Always find the last one created

sub new     { my $class = shift; $persist = bless { got => {@_} }, $class; }
sub save    { return 1; }
sub load    { 1; }
sub as_hash { return shift->{got} };

package Fake::Object;

sub find_class  {  return "Fake::Object::Thing";     }
sub find_object {  return $persist || Fake::Object::Thing->new() }

package SomeService;

use base 'Clustericious::App';
use Clustericious::RouteBuilder;
use Clustericious::RouteBuilder::CRUD
        "read"   => { -as => "do_read" },
        "create" => { -as => "do_create" },
        defaults => { finder => "Fake::Object" };

get  '/'              => sub { shift->render(text => 'welcome') };
post '/:table'        => \&do_create;
get  '/:table/(*key)' => \&do_read;

1;


@@ lib/SomeService/Client.pm
package SomeService::Client;

use Clustericious::Client;

route 'welcome' => '/';
route_doc 'welcome' => "Say hello";
route_meta 'welcome' => { jambo => 'sana' };
route 'broken' => '/borked';

object 'foo';

1;
