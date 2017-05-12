#!/usr/bin/perl

use Test::More;
eval "use Test::Pod::Coverage tests => 2";
plan skip_all => "Test::Pod::Coverage required for testing POD Coverage" if $@;
pod_coverage_ok( "Config::DotNetXML", 
                  "Config::DotNetXML is covered" );
pod_coverage_ok( "Config::DotNetXML::Parser" ,
                  "Config::DotNetXML::Parser is covered");
 

