#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cfn;

{
  my $res = Cfn->load_resource_module('AWS::ApiGateway::RestApi')->new(
    Properties => {}
  );
  is_deeply($res->AttributeList, [ 'RootResourceId' ], 'AttributeList OK');
  ok($res->hasAttribute('RootResourceId'), 'hasAttribute returns correctly for existing');
  ok(not($res->hasAttribute('UnExistingAttribute')), 'hasAttribute returns correctly for non-existing');
  ok(scalar(@{ $res->supported_regions }) > 0, 'supported_regions can be called as a method');
}

{
  my $res = Cfn->load_resource_module('AWS::ApiGateway::Account')->new(
    Properties => {}
  );
  is_deeply($res->AttributeList, [ ], 'AttributeList OK');
  ok(not($res->hasAttribute('UnExistingAttribute')), 'hasAttribute returns correctly for non-existing');
}

{
  my $res = Cfn->load_resource_module('AWS::CloudFormation::CustomResource')->new(
    Properties => { ServiceToken => '...' }
  );
  is_deeply($res->AttributeList, undef, 'AttributeList OK');
  ok($res->hasAttribute('AnAttribute'), 'hasAttribute returns correctly for any attribute');
}

done_testing;
