use Moose::Util::TypeConstraints;

coerce 'Cfn::Resource::Properties::AWS::EC2::SubnetNetworkAclAssociation',
  from 'HashRef',
   via { Cfn::Resource::Properties::AWS::EC2::SubnetNetworkAclAssociation->new( %$_ ) };

package Cfn::Resource::AWS::EC2::SubnetNetworkAclAssociation {
  use Moose;
  extends 'Cfn::Resource';
  has Properties => (isa => 'Cfn::Resource::Properties::AWS::EC2::SubnetNetworkAclAssociation', is => 'rw', coerce => 1, required => 1);
}

package Cfn::Resource::Properties::AWS::EC2::SubnetNetworkAclAssociation  {
  use Moose;
  use MooseX::StrictConstructor;
  extends 'Cfn::Resource::Properties';
  has SubnetId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
  has NetworkAclId => (isa => 'Cfn::Value', is => 'rw', coerce => 1, required => 1);
}

1;
