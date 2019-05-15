#!/usr/bin/env perl

use strict;
use warnings;
use Cfn;

use Test::More;

{
  my $cfn = Cfn->new;
  $cfn->addResource('Custom', 'Custom::MyCustom', ServiceToken => 'ST');
  my $hr = $cfn->as_hashref;

  is_deeply($hr->{Resources}->{Custom}->{Properties}, { ServiceToken => 'ST' }, 'Object with only a service token is handled correctly');
  cmp_ok($hr->{Resources}->{Custom}->{Type}, 'eq', 'Custom::MyCustom', 'Objects hashref Type property is the original that we specified');  
}

{
  my $cfn = Cfn->new;
  $cfn->addResource('Custom', 'Custom::MyCustom', ServiceToken => 'ST', MyProp => 'Test');
  my $hr = $cfn->as_hashref;

  is_deeply($hr->{Resources}->{Custom}->{Properties}, { ServiceToken => 'ST', MyProp => 'Test' }, 'Custom properties are correctly hashrefed');

  cmp_ok($hr->{Resources}->{Custom}->{Type}, 'eq', 'Custom::MyCustom', 'Objects hashref Type property is the original that we specified');  
}

{
  my $cfn = Cfn->new(cfn_options => { custom_resource_rename => 1 });

  $cfn->addResource('Custom', 'Custom::MyCustom', ServiceToken => 'ST', MyProp => 'Test');
  my $hr = $cfn->as_hashref;

  is_deeply($hr->{Resources}->{Custom}->{Properties}, { ServiceToken => 'ST', MyProp => 'Test' }, 'Custom properties are correctly hashrefed');

  cmp_ok($hr->{Resources}->{Custom}->{Type}, 'eq', 'AWS::CloudFormation::CustomResource', 'Objects hashref Type property has been transformed to AWS::CloudFormation::CustomResource');  
}


done_testing;
