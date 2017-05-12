use strict;
use warnings;

use Test::Pod::Coverage tests => 3;
pod_coverage_ok( "Abstract::Meta::Class", "should have Abstract::Meta::Class coverage");
pod_coverage_ok( "Abstract::Meta::Attribute", "should have Abstract::Meta::Attribute coverage");
pod_coverage_ok( "Abstract::Meta::Attribute::Method", "should have Abstract::Meta::Attribute::Method coverage");
