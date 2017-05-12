#!/usr/bin/env perl
# Try the official 2.0 example, as found in the spec, but then with the
# 2.1 reader
use warnings;
use strict;

use lib 'lib';
use Test::More;
#use Log::Report mode => 3;   # enable debugging

use BPM::XPDL;
use BPM::XPDL::Util ':xpdl21';
use XML::Compile::Util   'pack_type';

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Quotekeys = 0;

my $example_dir = 'examples/xpdl-2.0-sample';
if(-d $example_dir) { ; }
elsif(-d "../$example_dir") { $example_dir = "../$example_dir" }
else { plan skip_all => 'Cannot find the examples to test' }

plan tests => 3;

my ($type, $data) = BPM::XPDL->from( "$example_dir/sample.xpdl");
ok(defined $data, 'class method read');
is($type, pack_type(NS_XPDL_20, 'Package'));
isa_ok($data, 'HASH');


