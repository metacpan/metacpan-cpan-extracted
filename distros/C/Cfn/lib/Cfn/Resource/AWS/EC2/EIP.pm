# AWS::EC2::EIP generated from spec 2.15.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::EIP',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::EIP->new( %$_ ) };

package Cfn::Resource::AWS::EC2::EIP {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::EIP', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'AllocationId' ]
  }
}



package Cfn::Resource::Properties::AWS::EC2::EIP {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has Domain => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has InstanceId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has PublicIpv4Pool => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
