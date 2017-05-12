#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use Apache2::ASP::API;
my $api; BEGIN { $api = Apache2::ASP::API->new }

can_ok( $api, 'config' );
ok( $api, 'got an API object' );
isa_ok( $api, 'Apache2::ASP::API' );

ok(
  my $config = $api->config,
  '$api->config'
);
isa_ok( $config, 'Apache2::ASP::Config' );

# Load a class that can't be loaded:
{
  eval { $config->load_class('FooClass::123') };
  like $@, qr/Cannot load FooClass::123: /,
  'Loading invalid classes fails';
}


# Setter/getter tests:
{
  # Setting fails silently:
  my $original = $config->web->application_root;
  $config->web->application_root('yay');
  is( $config->web->application_root => $original, 'Setting value had no effect' );
  
  eval { $config->foo };
  like $@, qr/Unknown method or property 'foo'/,
    'Acessing invalid config elements dies';
}


# Make a ConfigNode::Web object from scratch:
{
  my $node = Apache2::ASP::ConfigNode::Web->new({
    request_filters => { filter => [ ] },
    disable_persistence => { location => [ ] },
  });
  my $node2 = Apache2::ASP::ConfigNode::Web->new({
    request_filters => { filter => [ 
      { uri_match => 'foo', class => 'bar' },
    ] },
    disable_persistence => { location => [
      { uri_match => 'foo' }
    ] },
  });
  my $node3 = Apache2::ASP::ConfigNode::Web->new({
    request_filters => { filter => [ 
      { uri_equals => '/foo', class => 'bar' },
    ] },
    disable_persistence => { location => [
      { uri_equals => '/foo' }
    ] },
  });
}


# Finally, blow the config away:
{
  $config->DESTROY;
}

