use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More;
use YAML::XS qw( Load );

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('SomeService');
my $t = $cluster->t;

$t->post_ok("/my_table", form => { foo => "bar" }, {}, "posted to create")
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_is('', {foo => "bar"}, "got structure back");

$t->get_ok('/my_table/foo',
           { Accept => 'application/json' })
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_is('', {foo => "bar"}, "got structure back in JSON");

$t->get_ok('/my_table/foo',
           { Accept => 'application/bogus;q=0.8,application/json' })
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_is('', {foo => "bar"}, "got structure back in JSON");

$t->get_ok('/my_table/foo',
           { Accept => 'application/bogus;q=0.8' })
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_is('', {foo => "bar"}, "got structure back in JSON");

$t->get_ok('/my_table/foo',
           { Accept => 'text/x-yaml' })
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'text/x-yaml')
  ->content_is("---\nfoo: bar\n", "got structure back in YAML");

$t->get_ok('/my_table/foo',
           { 'Content-Type' => 'text/x-yaml' })
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'text/x-yaml')
  ->content_is("---\nfoo: bar\n", "got structure back in YAML");

$t->post_ok("/my_table",
            json => { foo => 'bar' },
            "Post json")
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_is('', {foo => "bar"}, "got structure back");


$t->post_ok("/my_table",
            { 'Content-Type' => 'application/json; charset=UTF-8' },
            json => { foo => 'bar' },
            "Post json with charset")
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_is('', {foo => "bar"}, "got structure back");

$t->get_ok('/my_table/foo',
           { Accept => 'text/x-yaml' })
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'text/x-yaml')
  ->content_is("---\nfoo: bar\n", "got structure back in YAML");

$t->post_ok("/my_table", json => { foo => 'bar' },
            { Accept => 'application/json',
              'Content-Type' => 'text/x-yaml' },
            "Post json")
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_is('', {foo => "bar"}, "got structure back");

$t->get_ok('/my_table/foo')
  ->status_is(200, "got 200")
  ->header_is('Content-Type' => 'application/json')
  ->json_is('', {foo => "bar"}, "got structure back");

my $whatever = { foo => 'bar', baz => [1,2,3] };

$t->get_ok('/whatever')
  ->status_is(200)
  ->json_is('', $whatever);

$t->get_ok('/whatever.yml')
  ->status_is(200);

is_deeply YAML::XS::Load($t->tx->res->body), $whatever, 'yml matches';

$t->get_ok('/whatever.unknown')
  ->status_is(200)
  ->json_is('', $whatever);

done_testing;

__DATA__

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

post '/:table'        => \&do_create;
get  '/:table/(*key)' => \&do_read;

get '/whatever' => sub {
  shift->stash->{autodata} = { foo => 'bar', baz => [1,2,3] };
};

1;
