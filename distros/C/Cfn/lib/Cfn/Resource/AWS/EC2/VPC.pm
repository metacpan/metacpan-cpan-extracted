# AWS::EC2::VPC generated from spec 1.13.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::VPC',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::VPC->new( %$_ ) };

package Cfn::Resource::AWS::EC2::VPC {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::VPC', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'CidrBlock','CidrBlockAssociations','DefaultNetworkAcl','DefaultSecurityGroup','Ipv6CidrBlocks' ]
  }
}



package Cfn::Resource::Properties::AWS::EC2::VPC {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has CidrBlock => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has EnableDnsHostnames => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has EnableDnsSupport => (isa => 'Cfn::Value::Boolean', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has InstanceTenancy => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
  has Tags => (isa => 'ArrayOfCfn::Resource::Properties::TagType', is => 'rw', coerce => 1, traits => [ 'CfnMutability' ], mutability => 'Mutable');
}

1;
