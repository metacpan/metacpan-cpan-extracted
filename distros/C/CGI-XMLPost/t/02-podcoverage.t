#!/usr/bin/perl

use Test::More;
eval "use Test::Pod::Coverage tests => 1";
plan skip_all => "Test::Pod::Coverage required for testing POD Coverage" if $@;
pod_coverage_ok( "CGI::XMLPost", {also_private => [ qr/constant/]},
                  "CGI::XMLPost is covered" );
 

