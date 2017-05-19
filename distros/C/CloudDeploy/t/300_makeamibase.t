#!/usr/bin/env perl

use Test::More;
use CCfn;

package TestClass {
  use Moose;
  extends 'CCfnX::MakeAMIBase';
  use CCfnX::MakeAMIArgs;
  has params => (is => 'ro', isa => 'CCfnX::MakeAMIArgs', default => sub { CCfnX::MakeAMIArgs->new(
    instance_type => 'x1.xlarge',
    region => 'eu-west-1',
    account => 'devel-capside',
    name => 'NAME',
    ami  => 'xxxx',
    template => [ 'template-xx' ],
  ); } );

  use CCfnX::Shortcuts;

  resource X => 'AWS::IAM::User', {};
}

my $obj = TestClass->new;

ok($obj->Resource('Instance'), 'Instance object is defined just after create');
ok($obj->Resource('CfnPolicy'), 'CfnPolicy is defined just after create');

done_testing;
