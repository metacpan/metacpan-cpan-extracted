#!/usr/bin/env perl
# Try the official 2.0 example, as found in the spec
use warnings;
use strict;

use lib 'lib';
use Test::More;
#use Log::Report mode => 3;   # enable debugging

use BPM::XPDL;
use BPM::XPDL::Util ':xpdl20';
use XML::Compile::Util   'pack_type';

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Quotekeys = 0;

my $example_dir = 'examples';
if(-d $example_dir) { ; }
elsif(-d "../$example_dir") { $example_dir = "../$example_dir" }
else { plan skip_all => 'Cannot find the examples to test' }

my $example10 = "$example_dir/xpdl-1.0-sample";
my $example20 = "$example_dir/xpdl-2.0-sample";

plan tests => 3;

# This one is simple
my $xpdl = BPM::XPDL->new(version => '2.0', support_deprecated => 1);

#
# Load additional schema's
#

$xpdl->addSchemaDirs($example10);

# xyz schema needs a little help

use constant NS_XYZ => 'http://www.xyzeorder.com/workflow';
$xpdl->importDefinitions('xyzSchema.xsd'
  , target_namespace => NS_XYZ);  # poor schema lacks "target_namespace"
$xpdl->prefixes(xyz => NS_XYZ);
$xpdl->addKeyRewrite('PREFIXED(xyz)');

# orderschema and such are not needed to interpret the XPDL, but define
# the communication between the Applications.

#
# Finally we can read it
#

my ($type, $data) = $xpdl->from( "$example20/sample.xpdl");
is($type, pack_type(NS_XPDL_20, 'Package'));
isa_ok($data, 'HASH');

open OUT, '>:encoding(utf-8)', "$example20/output.dd"
    or die;

print OUT Dumper $data;
close OUT;

ok(1, 'dump successful');

print $xpdl->template('PERL', 'Package');
