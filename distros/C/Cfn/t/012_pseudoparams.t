use Moose::Util::TypeConstraints;

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
}

my $cfn = Cfn->new;

$cfn->addResource('t1', 'Test1', 
  Prop1 => { 'Ref' => 'AWS::AccountId' },
  Prop2 => { 'Ref' => 'AWS::NotificationARNs' },
  Prop3 => { 'Ref' => 'AWS::NoValue' },
  Prop4 => { 'Ref' => 'AWS::Partition' },
  Prop5 => { 'Ref' => 'AWS::Region' },
  Prop6 => { 'Ref' => 'AWS::StackId' },
  Prop7 => { 'Ref' => 'AWS::StackName' },
  Prop8 => { 'Ref' => 'AWS::URLSuffix' },
);


isa_ok($cfn->Resource('t1')->Properties->Prop1, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop2, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop3, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop4, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop5, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop6, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop7, 'Cfn::Value::Function');
isa_ok($cfn->Resource('t1')->Properties->Prop8, 'Cfn::Value::Function');

isa_ok($cfn->Resource('t1')->Properties->Prop1, 'Cfn::Value::Function::PseudoParameter');
isa_ok($cfn->Resource('t1')->Properties->Prop2, 'Cfn::Value::Function::PseudoParameter');
isa_ok($cfn->Resource('t1')->Properties->Prop3, 'Cfn::Value::Function::PseudoParameter');
isa_ok($cfn->Resource('t1')->Properties->Prop4, 'Cfn::Value::Function::PseudoParameter');
isa_ok($cfn->Resource('t1')->Properties->Prop5, 'Cfn::Value::Function::PseudoParameter');
isa_ok($cfn->Resource('t1')->Properties->Prop6, 'Cfn::Value::Function::PseudoParameter');
isa_ok($cfn->Resource('t1')->Properties->Prop7, 'Cfn::Value::Function::PseudoParameter');
isa_ok($cfn->Resource('t1')->Properties->Prop8, 'Cfn::Value::Function::PseudoParameter');

done_testing;
