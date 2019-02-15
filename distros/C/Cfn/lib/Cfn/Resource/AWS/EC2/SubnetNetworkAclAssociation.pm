# AWS::EC2::SubnetNetworkAclAssociation generated from spec 1.11.0
use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::SubnetNetworkAclAssociation',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::SubnetNetworkAclAssociation->new( %$_ ) };

package Cfn::Resource::AWS::EC2::SubnetNetworkAclAssociation {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::SubnetNetworkAclAssociation', is => 'rw', coerce => 1);
  sub _build_attributes {
    [ 'AssociationId' ]
  }
}



package Cfn::Resource::Properties::AWS::EC2::SubnetNetworkAclAssociation {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  
  has NetworkAclId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
  has SubnetId => (isa => 'Cfn::Value::String', is => 'rw', coerce => 1, required => 1, traits => [ 'CfnMutability' ], mutability => 'Immutable');
}

1;
