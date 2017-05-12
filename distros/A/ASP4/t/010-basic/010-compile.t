#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok( 'ASP4::Config' );
use_ok( 'ASP4::ConfigLoader' );
use_ok( 'ASP4::Request' );
use_ok( 'ASP4::Response' );
use_ok( 'ASP4::SessionStateManager' );
use_ok( 'ASP4::Server' );
use_ok( 'ASP4::HTTPContext' );
use_ok( 'ASP4::Page' );
use_ok( 'ASP4::MasterPage' );
use_ok( 'ASP4::PageParser' );

ok( my $config = ASP4::ConfigLoader->load(), 'load' );

is(
  $config->web->application_name => "DefaultApp"
);

is(
  $config->system->settings->foo => "bar", "foo = bar"
);

is(
  $config->system->env_vars->myvar => "Some-Value"
);

