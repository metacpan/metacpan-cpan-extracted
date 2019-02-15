# AWS::CloudFormation::WaitCondition generated from spec 2.15.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::CloudFormation::WaitCondition',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::CloudFormation::WaitCondition->new( %$_ ) };

package Cfn::Resource::AWS::CloudFormation::WaitCondition {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::CloudFormation::WaitCondition', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'Data' ]
  }
}



package Cfn::Resource::Properties::AWS::CloudFormation::WaitCondition {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Count => (isa => 'Cfn::Value::Integer', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Handle => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Timeout => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
