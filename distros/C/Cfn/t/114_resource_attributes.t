#!/usr/bin/env perl

use Test::More;
use Cfn;
use Cfn::Resource::AWS::ApiGateway::Account;
use Cfn::Resource::AWS::ApiGateway::RestApi;

{
  my $res = Cfn::Resource::AWS::ApiGateway::RestApi->new(
    Properties => {}
  );
  is_deeply($res->AttributeList, [ 'RootResourceId' ], 'AttributeList OK');
  ok($res->hasAttribute('RootResourceId'), 'hasAttribute returns correctly for existing');
  ok(not($res->hasAttribute('UnExistingAttribute')), 'hasAttribute returns correctly for non-existing');
}

{
  my $res = Cfn::Resource::AWS::ApiGateway::Account->new(
    Properties => {}
  );
  is_deeply($res->AttributeList, [ ], 'AttributeList OK');
  ok(not($res->hasAttribute('UnExistingAttribute')), 'hasAttribute returns correctly for non-existing');
}

done_testing;
