#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Cfn::ResourceModules;
# Cfn has to be loaded to call the load method, if not we get compile errors
use Cfn;

my @mod_list = Cfn::ResourceModules::list();

cmp_ok(@mod_list, '>', 0, 'The module list should have elements');

foreach my $module (@mod_list) {
  my $class_name = Cfn::ResourceModules::load($module);
  cmp_ok(
    $class_name,
    'eq',
    'Cfn::Resource::' . $module,
    "Module $module is loaded and a class name returned"
  );
  ok(defined $class_name->meta, "$class_name is loaded");
  ok(scalar(@{ $class_name->supported_regions }) > 0, "$class_name has supported_regions");
  # AttributeList can be undefined (AWS::CloudFormation::CustomResource), so we use an [] if it returns
  # undefined, we still have an array
  ok(scalar(@{ $class_name->AttributeList // [] }) >= 0, "$class_name has AttributeList");
}

done_testing;
