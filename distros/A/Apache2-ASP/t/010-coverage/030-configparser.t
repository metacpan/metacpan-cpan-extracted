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


# Parse a config in multiple ways:
{
  {
    local $config->{system} = { };
    Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
  }
  {
    local $config->{web} = { };
    eval {
      Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
    };
    like $@, qr/Can't call method "application_root" on unblessed reference/,
      'missing the config.web element fails';
  }
  {
    local $config->{data_connections} = { };
    local $config->{system}->{env_vars} = undef;
    # Convert hashref to array:
    local $config->{system}->{load_modules} = { module => 'Carp' };
    Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
  }
  {
    # Convert hashref to array:
    local $config->{system}->{env_vars} = { var => { name => 'foo', value => 'bar' } };
    Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
  }
  {
    local $config->{system}->{post_processors} = { class => 'My::ConfigPostProcessor' };
    Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
  }
  {
    local $config->{system}->{post_processors} = { class => 'My::ConfigPostProcessor' };
    Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
  }
  {
    local $config->{system}->{post_processors} = { class => 'My::ConfigPostProcessor' };
    Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
  }
  {
    local $config->{web}->{request_filters} = { filter => { uri_match => 'yay', class => 'foo' } };
    Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
  }
  {
    local $config->{web}->{disable_persistence} = undef;
    Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
  }
  {
    local $config->{web}->{disable_persistence} = { location => undef };
    Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
  }
  {
    local $config->{web}->{disable_persistence} = { location => { uri_equals => 'yay' } };
    Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
  }
  {
    local $config->{data_connections} = undef;
    Apache2::ASP::ConfigParser->new->parse( { %$config }, $config->web->application_root );
  }
}


