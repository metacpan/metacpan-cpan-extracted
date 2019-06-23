#!/usr/bin/env perl

use Moose::Util::TypeConstraints;

use strict;
use warnings;
use Cfn;

use Test::More;

coerce 'Cfn::Resource::Properties::Test1',
  from 'HashRef',
   via { Cfn::Resource::Properties::Test1->new( %$_ ) };

package Cfn::Resource::Test1 {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (is => 'rw', isa => 'Cfn::Resource::Properties::Test1', required => 1, coerce => 1);
}

package Cfn::Resource::Properties::Test1 {
  use Moose;
  extends 'Cfn::Resource::Properties';
  has Prop1 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop2 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop3 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop4 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop5 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop6 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop7 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop8 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop9 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop10 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop11 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop12 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop13 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop14 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop15 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop16 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop17 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop18 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop19 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
  has Prop20 => (is => 'rw', isa => 'Cfn::Value', coerce => 1);
}

my $cfn = Cfn->new;

$cfn->addResource('t1', 'Test1', 
  Prop1 => { 'Fn::Base64' => 'Value' },
  Prop2 => { 'Fn::FindInMap' => [ 'MapName', 'TopLevelKey', 'SecondLevelKey' ] },
  Prop3 => { 'Fn::GetAtt' => [ 'LogicalId', 'Attribute' ] },
  Prop4 => { 'Fn::GetAZs' => '' },
  Prop5 => { 'Fn::GetAZs' => { Ref => 'AWS::Region' } },
  Prop6 => { 'Fn::Join' => [ 'del', [ 'v1', 'v2', 'v3' ] ] },
  Prop7 => { 'Fn::Select' => [ 0, [ 'v1', 'v2', 'v3' ] ] },
  Prop8 => { 'Fn::Select' => [ 0, { 'Fn::GetAZs' => '' } ] },
  Prop9 => { 'Ref' => 'LogicalId' },

  Prop10 => { 'Fn::And' => [ { 'Fn::Equals' => [ 'sg-mysggroup', { 'Ref' => 'ASecurityGroup' } ] },
                             { 'Condition'  => 'SomeOtherCondition' }
  ] },
  Prop11 => { "Fn::Equals" => [ {"Ref" => "EnvironmentType"}, "prod" ] },
  Prop12 => { "Fn::If" => [ "CreateNewSecurityGroup", {"Ref" => "NewSecurityGroup"}, {"Ref" => "ExistingSecurityGroup"} ]},
  Prop13 => { "Fn::Not" => [{ "Fn::Equals" => [ {"Ref" => "EnvironmentType"}, "prod" ] } ] },
  Prop14 => { "Fn::Or"  => [{ "Fn::Equals" => ["sg-mysggroup", {"Ref" => "ASecurityGroup"}]}, {"Condition" => "SomeOtherCondition"} ] },
  Prop15 => { 'Fn::ImportValue' => 'Value' },
  Prop16 => { 'Fn::Split' => [ 'del', 'Value' ] },
  Prop17 => { 'Fn::Sub' => [ 'String' ] },
  Prop18 => { 'Fn::Sub' => [ 'String', [ 'v1', 'v2', 'v3' ] ] },
  Prop19 => { 'Fn::Cidr' => [ "192.168.0.0/24", 6, 5] },
  Prop20 => { 'Fn::Transform' => { Name => 'macro name', Parameters => {key1 => 'value1', key2 => 'value2' } } }
);


isa_ok($cfn->Resource('t1')->Properties->Prop1, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop2, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop3, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop4, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop5, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop6, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop7, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop8, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop9, 'Cfn::Value::Function');

isa_ok($cfn->Resource('t1')->Properties->Prop10, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop11, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop12, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop13, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop14, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop15, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop16, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop17, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop18, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop19, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop20, 'Cfn::Value::Function');

isa_ok($cfn->path_to('Resources.t1.Properties.Prop14.Fn::Or.1'), 'Cfn::Value::Function::Condition');

done_testing;
